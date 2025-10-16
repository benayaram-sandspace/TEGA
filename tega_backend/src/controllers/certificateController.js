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

    const completionPercentage = progress.overallProgress?.progressPercentage || 0;

    if (completionPercentage < 100) {
      return res.status(400).json({
        success: false,
        message: 'Course not completed yet',
        progress: {
          completedLectures: progress.overallProgress?.completedLectures || 0,
          totalLectures: progress.overallProgress?.totalLectures || 0,
          completionPercentage: Math.round(completionPercentage)
        }
      });
    }

    // Calculate final score from quiz attempts
    const quizProgress = progress.lectureProgress?.filter(lp => lp.quizAttempts && lp.quizAttempts.length > 0) || [];
    let totalScore = 0;
    let quizCount = 0;
    
    quizProgress.forEach(lp => {
      const bestAttempt = lp.quizAttempts.reduce((max, attempt) => 
        attempt.score > max.score ? attempt : max, lp.quizAttempts[0]
      );
      totalScore += bestAttempt.score;
      quizCount++;
    });

    const finalScore = quizCount > 0 ? Math.round(totalScore / quizCount) : 100;

    // Generate certificate number and verification code
    const certificateNumber = await Certificate.generateCertificateNumber();
    const verificationCode = Certificate.generateVerificationCode();

    // Create certificate record
    certificate = new Certificate({
      studentId,
      courseId,
      certificateNumber,
      verificationCode,
      studentName: student.name || student.email,
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
    console.error('Generate Certificate Error:', error);
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
        margin: 50
      });

      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Background
      doc.rect(0, 0, doc.page.width, doc.page.height)
         .fillColor('#f8f9fa')
         .fill();

      // Border
      doc.rect(30, 30, doc.page.width - 60, doc.page.height - 60)
         .lineWidth(3)
         .strokeColor('#2563eb')
         .stroke();

      // Inner border
      doc.rect(35, 35, doc.page.width - 70, doc.page.height - 70)
         .lineWidth(1)
         .strokeColor('#60a5fa')
         .stroke();

      // Title
      doc.fontSize(40)
         .fillColor('#1e40af')
         .font('Helvetica-Bold')
         .text('CERTIFICATE OF COMPLETION', 80, 80, {
           width: doc.page.width - 160,
           align: 'center'
         });

      // Decorative line
      doc.moveTo(200, 140)
         .lineTo(doc.page.width - 200, 140)
         .lineWidth(2)
         .strokeColor('#3b82f6')
         .stroke();

      // Body text
      doc.fontSize(14)
         .fillColor('#4b5563')
         .font('Helvetica')
         .text('This is to certify that', 0, 170, {
           width: doc.page.width,
           align: 'center'
         });

      // Student name
      doc.fontSize(32)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text(certificate.studentName, 0, 200, {
           width: doc.page.width,
           align: 'center'
         });

      // Course completion text
      doc.fontSize(14)
         .fillColor('#4b5563')
         .font('Helvetica')
         .text('has successfully completed the course', 0, 250, {
           width: doc.page.width,
           align: 'center'
         });

      // Course name
      doc.fontSize(24)
         .fillColor('#2563eb')
         .font('Helvetica-Bold')
         .text(certificate.courseName, 0, 280, {
           width: doc.page.width,
           align: 'center'
         });

      // Score and grade
      doc.fontSize(14)
         .fillColor('#4b5563')
         .font('Helvetica')
         .text(`Final Score: ${certificate.finalScore}% | Grade: ${certificate.grade}`, 0, 330, {
           width: doc.page.width,
           align: 'center'
         });

      // Date
      doc.fontSize(12)
         .fillColor('#6b7280')
         .text(`Date of Completion: ${certificate.completionDate.toLocaleDateString('en-US', {
           year: 'numeric',
           month: 'long',
           day: 'numeric'
         })}`, 0, 360, {
           width: doc.page.width,
           align: 'center'
         });

      // Certificate number and verification
      const bottomY = doc.page.height - 120;
      
      doc.fontSize(10)
         .fillColor('#9ca3af')
         .text(`Certificate No: ${certificate.certificateNumber}`, 80, bottomY)
         .text(`Verification Code: ${certificate.verificationCode}`, 80, bottomY + 15);

      // Organization info
      doc.fontSize(12)
         .fillColor('#1f2937')
         .font('Helvetica-Bold')
         .text(certificate.organizationName, doc.page.width - 300, bottomY, {
           width: 200,
           align: 'right'
         });

      // Instructor signature line
      doc.fontSize(10)
         .fillColor('#4b5563')
         .font('Helvetica')
         .text('_____________________', doc.page.width - 300, bottomY + 25, {
           width: 200,
           align: 'right'
         })
         .text(certificate.instructorName || 'Authorized Signatory', doc.page.width - 300, bottomY + 40, {
           width: 200,
           align: 'right'
         });

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
    console.error('Get Student Certificates Error:', error);
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
    console.error('Get Certificate Error:', error);
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

    const certificate = await Certificate.findById(certificateId);

    if (!certificate) {
      return res.status(404).json({
        success: false,
        message: 'Certificate not found'
      });
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
    console.error('Download Certificate Error:', error);
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
    console.error('Verify Certificate Error:', error);
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
    console.error('Get Certificate Sample Error:', error);
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

    // Get all progress for this course
    const progress = await StudentProgress.find({ studentId, courseId });
    
    const totalLectures = progress.length;
    const completedLectures = progress.filter(p => p.isCompleted).length;
    const completionPercentage = totalLectures > 0 ? (completedLectures / totalLectures) * 100 : 0;

    // Check if certificate exists
    const certificate = await Certificate.findOne({ studentId, courseId, isActive: true });

    // Calculate quiz scores
    const quizProgress = progress.filter(p => p.quizAttempts && p.quizAttempts.length > 0);
    let totalScore = 0;
    let quizCount = 0;
    
    quizProgress.forEach(p => {
      const bestAttempt = p.quizAttempts.reduce((max, attempt) => 
        attempt.score > max.score ? attempt : max, p.quizAttempts[0]
      );
      totalScore += bestAttempt.score;
      quizCount++;
    });

    const averageScore = quizCount > 0 ? Math.round(totalScore / quizCount) : 0;

    res.json({
      success: true,
      isCompleted: completionPercentage === 100,
      completionPercentage: Math.round(completionPercentage),
      completedLectures,
      totalLectures,
      averageScore,
      quizzesTaken: quizCount,
      certificateGenerated: !!certificate,
      certificate: certificate || null
    });

  } catch (error) {
    console.error('Check Course Completion Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check course completion',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

