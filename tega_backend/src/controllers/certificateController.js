import Certificate from '../models/Certificate.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import RealTimeProgress from '../models/RealTimeProgress.js';
import Student from '../models/Student.js';
import Enrollment from '../models/Enrollment.js';
import { uploadToR2, generateR2Key, generatePresignedDownloadUrl } from '../config/r2.js';
import PDFDocument from 'pdfkit';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Extract student name from student object - NEVER use email as name
 */
function extractStudentName(student) {
  if (!student) return 'Student';
  
  // Priority order: studentName > firstName + lastName > firstName > lastName > username
  let studentName = null;
  
  if (student.studentName && student.studentName.trim() && student.studentName !== student.email && !student.studentName.includes('@')) {
    studentName = student.studentName.trim();
  } else if (student.firstName && student.lastName) {
    const fullName = `${student.firstName} ${student.lastName}`.trim();
    if (fullName && fullName !== student.email && !fullName.includes('@')) {
      studentName = fullName;
    }
  } else if (student.firstName && student.firstName.trim() && student.firstName !== student.email && !student.firstName.includes('@')) {
    studentName = student.firstName.trim();
  } else if (student.lastName && student.lastName.trim() && student.lastName !== student.email && !student.lastName.includes('@')) {
    studentName = student.lastName.trim();
  } else if (student.username && student.username.trim() && student.username !== student.email && !student.username.includes('@')) {
    studentName = student.username.trim();
  }
  
  // If still no valid name found, extract name from email as last resort
  if (!studentName || studentName === student.email || studentName.includes('@')) {
    if (student.email) {
      const emailName = student.email.split('@')[0];
      // Capitalize first letter of each word
      studentName = emailName.split(/[._-]/).map(word => 
        word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
      ).join(' ');
    } else {
      studentName = 'Student';
    }
  }
  
  return studentName;
}

/**
 * Generate certificate for a student upon course completion
 */
export const generateCertificate = async (req, res) => {
  try {
    const { courseId } = req.body;
    const studentId = req.studentId;

    if (!courseId) {
      return res.status(400).json({
        success: false,
        message: 'Course ID is required'
      });
    }

    // Check if certificate already exists
    let certificate = await Certificate.findOne({ studentId, courseId });
    
    if (certificate && certificate.isActive) {
      return res.json({
        success: true,
        message: 'Certificate already exists',
        certificate
      });
    }

    // Get student, course, and enrollment information - USE ONLY REALTIMECOURSE
    const student = await Student.findById(studentId);
    const course = await RealTimeCourse.findById(courseId);
    const enrollment = await Enrollment.findOne({ studentId, courseId });

    if (!student || !course || !enrollment) {
      return res.status(404).json({
        success: false,
        message: 'Student, course, or enrollment not found'
      });
    }

    // Check if course is completed using RealTimeProgress
    const progress = await RealTimeProgress.findOne({ studentId, courseId });
    
    if (!progress) {
      return res.status(404).json({
        success: false,
        message: 'Progress record not found'
      });
    }

    // Check completion using both percentage field and isCompleted flag
    const completionPercentage = progress.overallProgress?.percentage || 
                                (progress.isCompleted ? 100 : 0) ||
                                (progress.completionPercentage || 0);

    // Also check if course is marked as completed
    const isCompleted = progress.isCompleted || completionPercentage >= 100;

    if (!isCompleted && completionPercentage < 100) {
      return res.status(400).json({
        success: false,
        message: 'Course not completed yet',
        progress: {
          completedLectures: progress.overallProgress?.completedLectures || 0,
          totalLectures: progress.overallProgress?.totalLectures || 0,
          completionPercentage: Math.round(completionPercentage),
          isCompleted: progress.isCompleted || false
        }
      });
    }

    // Calculate final score from quiz attempts (lecture quizzes and module quizzes)
    const lectureProgress = progress.lectureProgress || [];
    let totalScore = 0;
    let quizCount = 0;
    
    // Count quizzes from lecture progress (quizProgress.attempts)
    lectureProgress.forEach(lp => {
      if (lp.type === 'quiz' && lp.quizProgress && lp.quizProgress.attempts && lp.quizProgress.attempts.length > 0) {
        const bestAttempt = lp.quizProgress.attempts.reduce((max, attempt) => 
          attempt.score > max.score ? attempt : max, lp.quizProgress.attempts[0]
        );
        totalScore += bestAttempt.score;
        quizCount++;
      }
      // Also check for legacy quizAttempts format
      else if (lp.quizAttempts && lp.quizAttempts.length > 0) {
        const bestAttempt = lp.quizAttempts.reduce((max, attempt) => 
          attempt.score > max.score ? attempt : max, lp.quizAttempts[0]
        );
        totalScore += bestAttempt.score;
        quizCount++;
      }
    });
    
    // Count module quizzes from QuizAttempt model
    try {
      const QuizAttempt = (await import('../models/QuizAttempt.js')).default;
      const moduleQuizAttempts = await QuizAttempt.find({
        studentId,
        courseId
      }).populate('quizId', 'totalQuestions passMarks');
      
      if (moduleQuizAttempts && moduleQuizAttempts.length > 0) {
        // Group by quizId to get best attempt per quiz
        const quizMap = new Map();
        moduleQuizAttempts.forEach(attempt => {
          const quizId = attempt.quizId?._id?.toString() || attempt.quizId?.toString();
          if (quizId) {
            const currentScore = attempt.score || 0;
            const existingScore = quizMap.get(quizId)?.score || 0;
            if (!quizMap.has(quizId) || currentScore > existingScore) {
              quizMap.set(quizId, attempt);
            }
          }
        });
        
        // Add module quiz scores (convert marks to percentage if needed)
        quizMap.forEach(attempt => {
          let score = attempt.score || 0;
          // If totalMarks exists, convert to percentage (0-100)
          if (attempt.totalMarks && attempt.totalMarks > 0) {
            score = Math.round((score / attempt.totalMarks) * 100);
          }
          if (score > 0) {
            totalScore += score;
            quizCount++;
          }
        });
      }
    } catch (error) {
      // QuizAttempt model might not exist, that's okay
    }

    const finalScore = quizCount > 0 ? Math.round(totalScore / quizCount) : 100;

    // Generate certificate number and verification code
    const certificateNumber = await Certificate.generateCertificateNumber();
    const verificationCode = Certificate.generateVerificationCode();

    // Get student name - try multiple fields, but NEVER use email as name
    const studentName = extractStudentName(student);
    
    // Create certificate record
    certificate = new Certificate({
      studentId,
      courseId,
      certificateNumber,
      verificationCode,
      studentName: studentName,
      studentEmail: student.email,
      courseName: course.title || course.courseName,
      courseDescription: course.description,
      completionDate: new Date(),
      totalDuration: course.duration,
      finalScore,
      instructorName: course.instructor || 'TEGA Instructor',
      organizationName: 'TEGA Learning Platform',
    });

    // Calculate grade
    certificate.grade = certificate.calculateGrade();

    // Generate certificate PDF
    const pdfBuffer = await generateCertificatePDF(certificate, course, student);

    // Upload PDF to R2
    const pdfR2Key = generateR2Key('certificates', `${certificateNumber}.pdf`);
    const uploadResult = await uploadToR2(
      pdfBuffer,
      pdfR2Key,
      'application/pdf',
      {
        certificateNumber,
        studentId: studentId.toString(),
        courseId: courseId.toString()
      }
    );

    certificate.certificatePdfUrl = uploadResult.url;
    certificate.r2Key = pdfR2Key;

    await certificate.save();

    res.status(201).json({
      success: true,
      message: 'Certificate generated successfully',
      certificate: {
        ...certificate.toObject(),
        downloadUrl: uploadResult.url
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to generate certificate',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Generate certificate PDF
 */
async function generateCertificatePDF(certificate, course, student) {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({
        layout: 'landscape',
        size: 'A4',
        margin: 0, // No margins to maximize space
        autoFirstPage: true
      });

      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Prevent automatic page breaks - stay on first page only
      doc.switchToPage(0);
      
      // Disable automatic page creation
      const originalAddPage = doc.addPage;
      doc.addPage = function() {
        // Prevent adding new pages
        return this;
      };

      // White background
      doc.rect(0, 0, doc.page.width, doc.page.height)
         .fillColor('#ffffff')
         .fill();

      // Try to load logos
      const possibleTegaPaths = [
        path.join(__dirname, '../../client/src/assets/tegalog.png'),
        path.join(__dirname, '../../../client/src/assets/tegalog.png'),
        path.join(process.cwd(), 'client/src/assets/tegalog.png'),
        path.join(process.cwd(), 'TEAM_TEGA/client/src/assets/tegalog.png'),
        path.join(__dirname, '../../assets/tegalog.png')
      ];

      const possibleSandspacePaths = [
        path.join(__dirname, '../../client/src/assets/sandspace-logo.png'),
        path.join(__dirname, '../../../client/src/assets/sandspace-logo.png'),
        path.join(process.cwd(), 'client/src/assets/sandspace-logo.png'),
        path.join(process.cwd(), 'TEAM_TEGA/client/src/assets/sandspace-logo.png'),
        path.join(__dirname, '../../assets/sandspace-logo.png')
      ];

      let tegaLogoPath = null;
      let sandspaceLogoPath = null;

      for (const testPath of possibleTegaPaths) {
        if (fs.existsSync(testPath)) {
          tegaLogoPath = testPath;
          break;
        }
      }

      for (const testPath of possibleSandspacePaths) {
        if (fs.existsSync(testPath)) {
          sandspaceLogoPath = testPath;
          break;
        }
      }

      // Calculate page dimensions (A4 landscape: 842 x 595 points)
      const pageWidth = 842;
      const pageHeight = 595;
      
      // Top Header Section - Minimal spacing
      const topY = 10;
      const leftX = 20;
      const rightX = pageWidth - 130;

      // TEGA Logo and Text (Left side)
      if (tegaLogoPath) {
        try {
          doc.image(tegaLogoPath, leftX, topY, { width: 40, height: 40 });
        } catch (e) {}
      }
      
      doc.fontSize(11)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text('TEGA', leftX + 45, topY + 3);
      doc.fontSize(5.5)
         .fillColor('#4b5563')
         .font('Helvetica')
         .text('Training and Employment', leftX + 45, topY + 13)
         .text('Generation Activity', leftX + 45, topY + 20);

      // Sandspace Logo (Right side)
      if (sandspaceLogoPath) {
        try {
          doc.fontSize(5)
             .fillColor('#6b7280')
             .text('Powered by', rightX, topY, { width: 115, align: 'right' });
          doc.image(sandspaceLogoPath, rightX, topY + 5, { width: 115, height: 28 });
        } catch (e) {}
      }

      // Certificate Number (Centered at top)
      doc.fontSize(4.5)
         .fillColor('#6b7280')
         .text('Certificate No.', 0, topY + 10, { width: pageWidth, align: 'center' });
      doc.fontSize(6.5)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text(certificate.certificateNumber, 0, topY + 15, { width: pageWidth, align: 'center' });

      // Main Title Section - Tighter spacing
      const titleY = topY + 32;
      doc.fontSize(24)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text('CERTIFICATE', 0, titleY, {
           width: pageWidth,
           align: 'center'
         });

      doc.fontSize(14)
         .fillColor('#2563eb')
         .font('Helvetica-Bold')
         .text('OF ACHIEVEMENT', 0, titleY + 18, {
           width: pageWidth,
           align: 'center'
         });

      // Decorative line
      doc.moveTo(pageWidth / 2 - 50, titleY + 34)
         .lineTo(pageWidth / 2 + 50, titleY + 34)
         .lineWidth(2)
         .strokeColor('#2563eb')
         .stroke();

      // Body Text
      const bodyY = titleY + 38;
      doc.fontSize(7.5)
         .fillColor('#4b5563')
         .font('Helvetica')
         .text('This certifies that', 0, bodyY, {
           width: pageWidth,
           align: 'center'
         });

      // Student Name - Compact but prominent (with ellipsis if too long)
      const studentName = certificate.studentName || 'Student';
      doc.fontSize(20)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text(studentName, 0, bodyY + 10, {
           width: pageWidth,
           align: 'center',
           ellipsis: true,
           lineBreak: false
         });

      // Course completion text
      doc.fontSize(8.5)
         .fillColor('#4b5563')
         .font('Helvetica')
         .text('has successfully completed', 0, bodyY + 28, {
           width: pageWidth,
           align: 'center'
         });

      // Course Name Box - More compact
      const courseBoxY = bodyY + 40;
      const courseBoxWidth = pageWidth - 110;
      const courseBoxX = 55;
      const courseBoxHeight = 42;
      
      // Background box
      doc.rect(courseBoxX, courseBoxY, courseBoxWidth, courseBoxHeight)
         .fillColor('#eff6ff')
         .fill();
      
      // Border
      doc.rect(courseBoxX, courseBoxY, courseBoxWidth, courseBoxHeight)
         .lineWidth(2)
         .strokeColor('#bfdbfe')
         .stroke();

      // Course name (with ellipsis if too long)
      const courseName = certificate.courseName || 'Course';
      doc.fontSize(13)
         .fillColor('#1d4ed8')
         .font('Helvetica-Bold')
         .text(courseName, courseBoxX + 7, courseBoxY + 6, {
           width: courseBoxWidth - 14,
           align: 'center',
           ellipsis: true,
           lineBreak: false
         });

      // Completion date and grade side by side
      const dateText = new Date(certificate.completionDate).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
      
      const leftHalf = (courseBoxWidth - 14) / 2;
      const dividerX = courseBoxX + 7 + leftHalf;
      
      // Completed On (left side)
      doc.fontSize(4.5)
         .fillColor('#4b5563')
         .font('Helvetica-Bold')
         .text('Completed On', courseBoxX + 7, courseBoxY + 22, {
           width: leftHalf,
           align: 'center'
         });
      doc.fontSize(5.5)
         .fillColor('#1f2937')
         .font('Helvetica')
         .text(dateText, courseBoxX + 7, courseBoxY + 29, {
           width: leftHalf,
           align: 'center'
         });

      // Divider line (vertical)
      doc.moveTo(dividerX, courseBoxY + 22)
         .lineTo(dividerX, courseBoxY + 38)
         .lineWidth(0.5)
         .strokeColor('#d1d5db')
         .stroke();

      // Final Grade (right side)
      doc.fontSize(4.5)
         .fillColor('#4b5563')
         .font('Helvetica-Bold')
         .text('Final Grade', dividerX + 2, courseBoxY + 22, {
           width: leftHalf,
           align: 'center'
         });
      doc.fontSize(10)
         .fillColor('#16a34a')
         .font('Helvetica-Bold')
         .text(certificate.grade, dividerX + 2, courseBoxY + 29, {
           width: leftHalf,
           align: 'center'
         });

      // Achievement Statement - Very compact, shorter text
      doc.fontSize(5.5)
         .fillColor('#374151')
         .font('Helvetica')
         .text('Demonstrating mastery and achieving outstanding performance throughout the program.', 0, courseBoxY + 48, {
           width: pageWidth - 15,
           align: 'center',
           lineGap: 0.5
         });

      // Signatures Section - Tighter positioning
      const signatureY = pageHeight - 60;
      const signatureWidth = 140;
      const leftSignatureX = 65;
      const rightSignatureX = pageWidth - 65 - signatureWidth;

      // Left signature - Course Instructor
      doc.moveTo(leftSignatureX, signatureY)
         .lineTo(leftSignatureX + signatureWidth, signatureY)
         .lineWidth(1.5)
         .strokeColor('#4b5563')
         .stroke();
      doc.fontSize(6)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text('Course Instructor', leftSignatureX, signatureY + 3, {
           width: signatureWidth,
           align: 'center'
         });
      doc.fontSize(4.5)
         .fillColor('#6b7280')
         .font('Helvetica')
         .text(certificate.instructorName || 'Course Instructor Name', leftSignatureX, signatureY + 10, {
           width: signatureWidth,
           align: 'center'
         });

      // Right signature - Head
      doc.moveTo(rightSignatureX, signatureY)
         .lineTo(rightSignatureX + signatureWidth, signatureY)
         .lineWidth(1.5)
         .strokeColor('#4b5563')
         .stroke();
      doc.fontSize(6)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text('Head', rightSignatureX, signatureY + 3, {
           width: signatureWidth,
           align: 'center'
         });
      doc.fontSize(4.5)
         .fillColor('#6b7280')
         .font('Helvetica-Bold')
         .text('Sudheer Anne', rightSignatureX, signatureY + 10, {
           width: signatureWidth,
           align: 'center'
         });

      // Footer Section with Logos - Minimal space
      const footerY = pageHeight - 22;
      const footerCenterX = pageWidth / 2;

      // TEGA Logo (left side of footer)
      if (tegaLogoPath) {
        try {
          doc.image(tegaLogoPath, footerCenterX - 100, footerY, { width: 25, height: 25 });
        } catch (e) {}
      }
      
      // TEGA Text
      doc.fontSize(4.5)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text('TEGA Learning Platform', footerCenterX - 50, footerY + 2, { width: 100, align: 'center' });
      doc.fontSize(3.5)
         .fillColor('#6b7280')
         .text('Training and Employment Generation Activity', footerCenterX - 50, footerY + 7, { width: 100, align: 'center' });

      // Sandspace Logo (right side of footer)
      if (sandspaceLogoPath) {
        try {
          doc.image(sandspaceLogoPath, footerCenterX + 55, footerY, { width: 55, height: 16 });
        } catch (e) {}
      }
      
      // Sandspace Text
      doc.fontSize(3.5)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text('Sandspace Technologies', footerCenterX + 50, footerY + 14, { width: 50, align: 'center' });
      doc.fontSize(2.5)
         .fillColor('#6b7280')
         .text('Powered by Sandspace', footerCenterX + 50, footerY + 18, { width: 50, align: 'center' });

      // Verification code at bottom left
      doc.fontSize(3)
         .fillColor('#9ca3af')
         .text(`Verification Code: ${certificate.verificationCode}`, 20, pageHeight - 5);

      doc.end();

    } catch (error) {
      reject(error);
    }
  });
}

/**
 * Get student certificates
 */
export const getStudentCertificates = async (req, res) => {
  try {
    const studentId = req.studentId;

    const certificates = await Certificate.find({ 
      studentId, 
      isActive: true 
    })
    .populate('courseId', 'courseName description image')
    .sort({ completionDate: -1 });

    res.json({
      success: true,
      certificates,
      count: certificates.length
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch certificates',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get certificate by ID
 */
export const getCertificateById = async (req, res) => {
  try {
    const { certificateId } = req.params;

    const certificate = await Certificate.findById(certificateId)
      .populate('studentId', 'name email')
      .populate('courseId', 'courseName description');

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate not found'
      });
    }

    // Increment view count
    await certificate.incrementViewCount();

    res.json({
      success: true,
      certificate
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch certificate',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Download certificate
 */
export const downloadCertificate = async (req, res) => {
  try {
    const { certificateId } = req.params;
    const { regenerate } = req.query; // Optional query param to force regeneration

    const certificate = await Certificate.findById(certificateId);

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate not found'
      });
    }

    // Regenerate PDF if requested or if certificate doesn't have PDF URL
    if (regenerate === 'true' || !certificate.certificatePdfUrl || !certificate.r2Key) {
      try {
        const course = await RealTimeCourse.findById(certificate.courseId);
        const student = await Student.findById(certificate.studentId);
        
        if (!course || !student) {
          throw new Error('Course or student not found');
        }

        // Re-extract student name to fix email issue
        const correctStudentName = extractStudentName(student);
        
        // Update certificate with correct name if it's currently an email
        if (certificate.studentName.includes('@') || certificate.studentName === student.email) {
          certificate.studentName = correctStudentName;
          await certificate.save();
        }
        
        // Create a temporary certificate object with correct name for PDF generation
        const certificateForPDF = {
          ...certificate.toObject(),
          studentName: correctStudentName
        };

        // Regenerate PDF with new template and correct name
        const pdfBuffer = await generateCertificatePDF(certificateForPDF, course, student);

        // Upload new PDF to R2
        const pdfR2Key = generateR2Key('certificates', `${certificate.certificateNumber}.pdf`);
        const uploadResult = await uploadToR2(
          pdfBuffer,
          pdfR2Key,
          'application/pdf',
          {
            certificateNumber: certificate.certificateNumber,
            studentId: certificate.studentId.toString(),
            courseId: certificate.courseId.toString()
          }
        );

        // Update certificate with new PDF URL
        certificate.certificatePdfUrl = uploadResult.url;
        certificate.r2Key = pdfR2Key;
        await certificate.save();
      } catch (regenerateError) {
        // Continue with existing PDF if regeneration fails
      }
    }

    // Generate download URL
    const result = await generatePresignedDownloadUrl(certificate.r2Key, 3600);

    // Increment download count
    await certificate.incrementDownloadCount();

    res.json({
      success: true,
      downloadUrl: result.downloadUrl,
      certificateNumber: certificate.certificateNumber,
      expiresIn: result.expiresIn
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to download certificate',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Verify certificate by verification code
 */
export const verifyCertificate = async (req, res) => {
  try {
    const { verificationCode } = req.params;

    const certificate = await Certificate.verifyCertificate(verificationCode);

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate not found or invalid verification code',
        isValid: false
      });
    }

    res.json({
      success: true,
      isValid: true,
      certificate: {
        certificateNumber: certificate.certificateNumber,
        studentName: certificate.studentName,
        courseName: certificate.courseName,
        completionDate: certificate.completionDate,
        grade: certificate.grade,
        organizationName: certificate.organizationName
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to verify certificate',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get certificate sample/template for preview
 */
export const getCertificateSample = async (req, res) => {
  try {
    // Generate a sample certificate
    const sampleCertificate = {
      certificateNumber: 'TEGA-2025-SAMPLE',
      verificationCode: 'XXXX-XXXX-XXXX',
      studentName: 'John Doe',
      courseName: 'Sample Course Name',
      completionDate: new Date(),
      finalScore: 95,
      grade: 'A+',
      instructorName: 'TEGA Instructor',
      organizationName: 'TEGA Learning Platform',
    };

    const course = { courseName: 'Sample Course' };
    const student = { name: 'John Doe' };

    const pdfBuffer = await generateCertificatePDF(sampleCertificate, course, student);

    // Send PDF directly
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'inline; filename=certificate-sample.pdf');
    res.send(pdfBuffer);

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to generate certificate sample',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Check course completion status
 */
export const checkCourseCompletion = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    // Get progress for this course using RealTimeProgress
    const progress = await RealTimeProgress.findOne({ studentId, courseId });
    
    if (!progress) {
      return res.json({
        success: true,
        isCompleted: false,
        completionPercentage: 0,
        completedLectures: 0,
        totalLectures: 0,
        averageScore: 0,
        quizzesTaken: 0,
        certificateGenerated: false,
        certificate: null
      });
    }

    // Get completion status from progress
    const completionPercentage = progress.overallProgress?.percentage || 
                                 (progress.isCompleted ? 100 : 0) ||
                                 (progress.completionPercentage || 0);
    const isCompleted = progress.isCompleted || completionPercentage >= 100;
    const completedLectures = progress.overallProgress?.completedLectures || 0;
    const totalLectures = progress.overallProgress?.totalLectures || 0;

    // Check if certificate exists
    const certificate = await Certificate.findOne({ studentId, courseId, isActive: true });

    // Calculate quiz scores from lecture progress and module quizzes
    const lectureProgress = progress.lectureProgress || [];
    let totalScore = 0;
    let quizCount = 0;
    
    // Count quizzes from lecture progress (quizProgress.attempts)
    lectureProgress.forEach(lp => {
      if (lp.type === 'quiz' && lp.quizProgress && lp.quizProgress.attempts && lp.quizProgress.attempts.length > 0) {
        const bestAttempt = lp.quizProgress.attempts.reduce((max, attempt) => 
          attempt.score > max.score ? attempt : max, lp.quizProgress.attempts[0]
        );
        totalScore += bestAttempt.score;
        quizCount++;
      }
      // Also check for legacy quizAttempts format
      else if (lp.quizAttempts && lp.quizAttempts.length > 0) {
        const bestAttempt = lp.quizAttempts.reduce((max, attempt) => 
          attempt.score > max.score ? attempt : max, lp.quizAttempts[0]
        );
        totalScore += bestAttempt.score;
        quizCount++;
      }
    });
    
    // Count module quizzes from QuizAttempt model
    try {
      const QuizAttempt = (await import('../models/QuizAttempt.js')).default;
      const moduleQuizAttempts = await QuizAttempt.find({
        studentId,
        courseId
      }).populate('quizId', 'totalQuestions passMarks');
      
      if (moduleQuizAttempts && moduleQuizAttempts.length > 0) {
        // Group by quizId to get best attempt per quiz
        const quizMap = new Map();
        moduleQuizAttempts.forEach(attempt => {
          const quizId = attempt.quizId?._id?.toString() || attempt.quizId?.toString();
          if (quizId) {
            const currentScore = attempt.score || 0;
            const existingScore = quizMap.get(quizId)?.score || 0;
            if (!quizMap.has(quizId) || currentScore > existingScore) {
              quizMap.set(quizId, attempt);
            }
          }
        });
        
        // Add module quiz scores (convert marks to percentage if needed)
        quizMap.forEach(attempt => {
          let score = attempt.score || 0;
          // If totalMarks exists, convert to percentage (0-100)
          if (attempt.totalMarks && attempt.totalMarks > 0) {
            score = Math.round((score / attempt.totalMarks) * 100);
          }
          if (score > 0) {
            totalScore += score;
            quizCount++;
          }
        });
      }
    } catch (error) {
      // QuizAttempt model might not exist, that's okay
    }

    const averageScore = quizCount > 0 ? Math.round(totalScore / quizCount) : 0;

    res.json({
      success: true,
      isCompleted,
      completionPercentage: Math.round(completionPercentage),
      completedLectures,
      totalLectures,
      averageScore,
      quizzesTaken: quizCount,
      certificateGenerated: !!certificate,
      certificate: certificate || null
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check course completion',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
