import PDFDocument from 'pdfkit';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import ExamAttempt from '../models/ExamAttempt.js';
import Exam from '../models/Exam.js';
import Question from '../models/Question.js';
import Student from '../models/Student.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Generate dynamic PDF feedback for exam results
 */
export const generateExamFeedbackPDF = async (req, res) => {
  try {
    const { attemptId } = req.params;
    const studentId = req.studentId;

    // Debug logging (remove in production)
    if (!attemptId) {
      return res.status(400).json({
        success: false,
        message: 'Attempt ID is required'
      });
    }

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Fetch exam attempt with populated data
    const examAttempt = await ExamAttempt.findById(attemptId)
      .populate('examId', 'title subject duration totalMarks passingMarks questionPaperId questions')
      .populate('studentId', 'firstName lastName email studentId institute');

    if (!examAttempt) {
      return res.status(404).json({
        success: false,
        message: 'Exam attempt not found'
      });
    }
    if (!examAttempt) {
      return res.status(404).json({
        success: false,
        message: 'Exam attempt not found'
      });
    }

    // Verify ownership
    // Handle both ObjectId and string comparisons
    const examAttemptStudentId = examAttempt.studentId._id.toString();
    const requestStudentId = studentId.toString();
    
    if (examAttemptStudentId !== requestStudentId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied - You can only download your own exam feedback',
        debug: {
          examAttemptStudentId,
          requestStudentId,
          areEqual: examAttemptStudentId === requestStudentId
        }
      });
    }

    // Fetch questions using the same logic as getExamQuestions (which works for results)
    let questions = [];
    
    try {
      // Get the full exam object
      const exam = await Exam.findById(examAttempt.examId._id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }
      // Use the same logic as getExamQuestions function
      if (exam.questionPaperId) {
        // Import QuestionPaper model
        const QuestionPaper = (await import('../models/QuestionPaper.js')).default;
        const questionPaper = await QuestionPaper.findById(exam.questionPaperId).populate('questions');
        if (questionPaper && questionPaper.questions) {
          questions = questionPaper.questions.map(q => ({
            _id: q._id,
            question: q.question,
            options: q.options,
            correctAnswer: q.correctAnswer,
            marks: q.marks || 1,
            explanation: q.explanation,
            subject: q.subject,
            topic: q.topic,
            difficulty: q.difficulty
          }));
        }
      } else if (exam.questions && exam.questions.length > 0) {
        questions = await Question.find({ _id: { $in: exam.questions } })
          .select('question options correctAnswer marks explanation subject topic difficulty')
          .sort({ sno: 1 });
      }

      // If still no questions, try to find questions that were answered
      if (!questions || questions.length === 0) {
        const answeredQuestionIds = Array.from(examAttempt.answers.keys());
        if (answeredQuestionIds.length > 0) {
          questions = await Question.find({ _id: { $in: answeredQuestionIds } })
            .select('question options correctAnswer marks explanation subject topic difficulty')
            .sort({ sno: 1 });
        }
      }

    } catch (questionError) {
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch questions for PDF generation',
        error: questionError.message
      });
    }

    if (!questions || questions.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Questions not found for this exam',
        debug: {
          examId: examAttempt.examId._id,
          hasAnswers: examAttempt.answers.size > 0,
          answerCount: examAttempt.answers.size,
          answeredQuestionIds: Array.from(examAttempt.answers.keys())
        }
      });
    }
    // Create PDF document with optimized margins (0.75 inch = 54 points for more space)
    const doc = new PDFDocument({
      size: 'A4',
      margins: {
        top: 54,
        bottom: 54,
        left: 54,
        right: 54
      }
    });

    // Set response headers for PDF download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="Tega_Feedback_${examAttempt.studentId.firstName}_${examAttempt.studentId.lastName}.pdf"`);

    // Pipe PDF to response
    doc.pipe(res);

    // Add Tega logo (top-right corner)
    await addTegaLogo(doc);

    // Add watermark to every page
    addWatermark(doc);

    // Generate PDF content
    try {
      await generatePDFContent(doc, examAttempt, questions);
    } catch (contentError) {
      return res.status(500).json({
        success: false,
        message: 'Failed to generate PDF content',
        error: process.env.NODE_ENV === 'development' ? contentError.message : undefined
      });
    }

    // Finalize PDF
    doc.end();

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to generate PDF feedback',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Add Tega logo to PDF (top-right corner)
 */
async function addTegaLogo(doc) {
  try {
    // Try multiple possible paths for the logo
    const possiblePaths = [
      path.join(__dirname, '../../client/src/assets/tegalog.png'),
      path.join(__dirname, '../../../client/src/assets/tegalog.png'),
      path.join(process.cwd(), 'client/src/assets/tegalog.png'),
      path.join(process.cwd(), 'src/assets/tegalog.png'),
      path.join(__dirname, '../../assets/tegalog.png')
    ];
    
    let logoPath = null;
    for (const testPath of possiblePaths) {
      if (fs.existsSync(testPath)) {
        logoPath = testPath;
        break;
      }
    }
    
    if (logoPath) {
      // Add logo to top-right corner with professional styling
      doc.image(logoPath, doc.page.width - 80, 10, {
        width: 60,
        height: 30,
        align: 'right'
      });
    } else {
      // Fallback: Add professional text logo
      doc.fontSize(14)
         .font('Helvetica-Bold')
         .fillColor('#003366')
         .text('TEGA', doc.page.width - 50, 15, {
           align: 'right'
         });
    }
  } catch (error) {
    // Fallback: Add professional text logo
    doc.fontSize(14)
       .font('Helvetica-Bold')
       .fillColor('#003366')
       .text('TEGA', doc.page.width - 50, 15, {
         align: 'right'
       });
  }
}

/**
 * Add watermark to every page
 */
function addWatermark(doc) {
  // Store original event handlers
  const originalEndPage = doc._events['endPage'];
  
  // Override endPage to add watermark
  doc.on('endPage', function() {
    // Add subtle watermark with TEGA logo in maroon
    doc.save();
    doc.rotate(-45, { origin: [doc.page.width / 2, doc.page.height / 2] });
    doc.fontSize(60)
       .fillColor('#8B0000', 0.05) // Very subtle maroon watermark
       .text('TEGA', doc.page.width / 2 - 90, doc.page.height / 2 - 30);
    doc.restore();
    
    // Call original endPage handler if it exists
    if (originalEndPage) {
      originalEndPage.forEach(handler => handler.call(this));
    }
  });
}

/**
 * Generate main PDF content with clean, well-formatted layout
 */
async function generatePDFContent(doc, examAttempt, questions) {
  const { studentId, examId, score, totalMarks, correctAnswers, wrongAnswers, unattempted, percentage, endTime } = examAttempt;
  
  // Set consistent margins (0.75 inch = 54 points for more efficient space usage)
  const margin = 54;
  let currentY = margin;
  
  // TEGA EXAM FEEDBACK REPORT - Main Title with maroon theme (compact)
  doc.fontSize(20) // Reduced from 22
     .font('Helvetica-Bold')
     .fillColor('#8B0000') // Maroon color
     .text('TEGA EXAM FEEDBACK REPORT', margin, currentY, {
       align: 'center',
       width: doc.page.width - (2 * margin)
     });
  
  currentY += 22; // Reduced spacing
  
  // Add decorative line under title
  doc.strokeColor('#8B0000')
     .lineWidth(1) // Thinner line
     .moveTo(margin + 50, currentY - 6)
     .lineTo(doc.page.width - margin - 50, currentY - 6)
     .stroke();
  
  currentY += 12; // Reduced spacing
  
  // Generated on timestamp (smaller)
  doc.fontSize(9) // Reduced from 10
     .font('Helvetica')
     .fillColor('#666666')
     .text(`Generated on: ${new Date().toLocaleString('en-IN')}`, margin, currentY, {
       align: 'center',
       width: doc.page.width - (2 * margin)
     });
  
  currentY += 15; // Reduced spacing
  
  // Compact layout: Combine all summary sections in a two-column layout
  // Left column: Student Details + Exam Details
  // Right column: Performance Summary
  
  const leftColumnWidth = (doc.page.width - (2 * margin)) / 2 - 10;
  const rightColumnWidth = (doc.page.width - (2 * margin)) / 2 - 10;
  const leftColumnX = margin;
  const rightColumnX = margin + leftColumnWidth + 20;
  
  // Left Column: Student Details
  addSectionHeader(doc, 'Student Details', leftColumnX, currentY, leftColumnWidth);
  currentY += 22; // Reduced spacing
  
  const studentDetails = [
    { label: 'Name', value: `${studentId.firstName} ${studentId.lastName}` },
    { label: 'Student ID', value: studentId.studentId || 'N/A' },
    { label: 'Institute', value: studentId.institute || 'N/A' },
    { label: 'Email', value: studentId.email || 'N/A' }
  ];
  
  let leftColumnY = currentY;
  studentDetails.forEach(detail => {
    leftColumnY = addFieldWithLabel(doc, detail.label, detail.value, leftColumnX, leftColumnY, leftColumnWidth);
  });
  
  // Right Column: Performance Summary
  addSectionHeader(doc, 'Performance Summary', rightColumnX, currentY, rightColumnWidth);
  currentY += 22; // Reduced spacing
  
  const performanceDetails = [
    { label: 'Total Questions', value: questions.length.toString() },
    { label: 'Correct Answers', value: correctAnswers.toString() },
    { label: 'Incorrect Answers', value: wrongAnswers.toString() },
    { label: 'Unattempted', value: unattempted.toString() },
    { label: 'Score', value: `${score}/${totalMarks}` },
    { label: 'Percentage', value: `${percentage.toFixed(2)}%` }
  ];
  
  let rightColumnY = currentY;
  performanceDetails.forEach(detail => {
    rightColumnY = addFieldWithLabel(doc, detail.label, detail.value, rightColumnX, rightColumnY, rightColumnWidth);
  });
  
  // Use the maximum Y from both columns
  currentY = Math.max(leftColumnY, rightColumnY) + 12;
  
  // Exam Details section (full width, below the columns)
  addSectionHeader(doc, 'Exam Details', margin, currentY);
  currentY += 22; // Reduced spacing
  
  const examDetails = [
    { label: 'Exam', value: examId.title },
    { label: 'Subject', value: examId.subject || 'N/A' },
    { label: 'Date', value: new Date(endTime).toLocaleDateString('en-IN') },
    { label: 'Duration', value: `${examId.duration} minutes` }
  ];
  
  examDetails.forEach(detail => {
    currentY = addFieldWithLabel(doc, detail.label, detail.value, margin, currentY);
  });
  
  // Overall Feedback
  currentY += 12;
  const overallFeedback = generateOverallFeedback(percentage, correctAnswers, questions.length);
  currentY = addFieldWithLabel(doc, 'Overall Feedback', overallFeedback, margin, currentY);
  
  currentY += 15; // Reduced spacing
  
  // Check if we need a new page for questions (only if really necessary)
  if (currentY > doc.page.height - 150) {
    doc.addPage();
    addWatermark(doc);
    currentY = margin;
  }
  
  // Section 4: Question-wise Feedback
  addSectionHeader(doc, 'Question-wise Feedback', margin, currentY);
  currentY += 20; // Reduced spacing
  
  for (let i = 0; i < questions.length; i++) {
    const question = questions[i];
    const userAnswer = examAttempt.answers.get(question._id.toString());
    const isCorrect = userAnswer === question.correctAnswer;
    
    // Check if we need a new page (more aggressive check - only break when really needed)
    // Calculate estimated height needed for this question (more compact)
    const baseHeight = 180;
    const optionsHeight = question.options ? question.options.length * 11 : 0;
    const estimatedQuestionHeight = baseHeight + optionsHeight;
    
    // Only add page if question truly won't fit
    if (currentY + estimatedQuestionHeight > doc.page.height - margin - 30) {
      doc.addPage();
      addWatermark(doc);
      currentY = margin;
    }
    
    // Store starting Y position for question container
    const questionStartY = currentY;
    
    // Calculate question block height dynamically (more compact)
    // Reuse optionsHeight from above, but recalculate for background (slightly different spacing)
    const backgroundOptionsHeight = question.options && question.options.length > 0 ? question.options.length * 12 : 0;
    const estimatedHeight = 180 + backgroundOptionsHeight; // More compact estimate
    const bgColor = isCorrect ? '#F8FCF8' : '#FFFBFB'; // Very light green/red
    
    // Draw background rectangle first (before text, so text appears on top)
    doc.rect(margin - 5, questionStartY - 5, doc.page.width - (2 * margin) + 10, estimatedHeight)
       .fillColor(bgColor)
       .fill();
    
    // Draw border
    doc.rect(margin - 5, questionStartY - 5, doc.page.width - (2 * margin) + 10, estimatedHeight)
       .strokeColor(isCorrect ? '#28A745' : '#DC3545')
       .lineWidth(1.2)
       .stroke();
    
    // Question header with status and better styling
    const status = isCorrect ? 'Correct' : 'Incorrect';
    const statusColor = isCorrect ? '#28A745' : '#DC3545';
    const statusIcon = isCorrect ? '✓' : '✗';
    
    doc.fontSize(12) // Reduced from 13
       .font('Helvetica-Bold')
       .fillColor('#8B0000')
       .text(`Question ${i + 1}`, margin, currentY + 3);
    
    doc.fontSize(10) // Reduced from 11
       .font('Helvetica-Bold')
       .fillColor(statusColor)
       .text(`${statusIcon} ${status}`, doc.page.width - margin - 100, currentY + 3);
    
    currentY += 18; // Reduced from 22
    
    // Question text with better formatting (compact)
    doc.fontSize(9.5) // Reduced from 10
       .font('Helvetica-Bold')
       .fillColor('#8B0000')
       .text('Q:', margin, currentY);
    
    const questionHeight = doc.heightOfString(question.question, {
      width: doc.page.width - margin - 18 - margin,
      align: 'justify',
      lineGap: 2
    });
    
    doc.fontSize(9.5) // Reduced from 10
       .font('Helvetica')
       .fillColor('#333333')
       .text(question.question, margin + 18, currentY, {
         width: doc.page.width - margin - 18 - margin,
         align: 'justify',
         lineGap: 2
       });
    
    currentY += questionHeight + 8; // Reduced spacing
    
    // Display options if available (and remove HTML entities like &amp;)
    if (question.options && question.options.length > 0) {
      doc.fontSize(8.5) // Reduced from 9
         .font('Helvetica-Bold')
         .fillColor('#666666')
         .text('Options:', margin, currentY);
      
      currentY += 10; // Reduced from 12
      
      question.options.forEach((option, optIndex) => {
        const optionLetter = String.fromCharCode(65 + optIndex); // A, B, C, D
        const cleanOption = (option || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
        const isUserChoice = userAnswer === option;
        const isCorrectOption = option === question.correctAnswer;
        
        let optionColor = '#666666';
        if (isCorrectOption) {
          optionColor = '#28A745';
        } else if (isUserChoice && !isCorrect) {
          optionColor = '#DC3545';
        }
        
        doc.fontSize(8.5) // Reduced from 9
           .font(isUserChoice || isCorrectOption ? 'Helvetica-Bold' : 'Helvetica')
           .fillColor(optionColor)
           .text(`${optionLetter}. ${cleanOption}`, margin + 12, currentY, {
             width: doc.page.width - margin - 12 - margin,
             lineGap: 1.5
           });
        
        currentY += 11; // Reduced from 14
      });
      
      currentY += 6; // Reduced from 8
    }
    
    // User's answer with proper spacing - label on separate line (compact)
    doc.fontSize(9.5) // Reduced from 10
       .font('Helvetica-Bold')
       .fillColor('#8B0000')
       .text('Your Answer:', margin, currentY);
    
    currentY += 12; // Reduced from 15
    
    const userAnswerText = userAnswer || 'Not Attempted';
    const userAnswerClean = userAnswerText.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
    
    doc.fontSize(9) // Reduced from 10
       .font('Helvetica')
       .fillColor(userAnswer ? '#333333' : '#DC3545')
       .text(userAnswerClean, margin + 8, currentY, {
         width: doc.page.width - margin - 8 - margin,
         lineGap: 1.5
       });
    
    const userAnswerHeight = doc.heightOfString(userAnswerClean, {
      width: doc.page.width - margin - 8 - margin,
      lineGap: 1.5
    });
    
    currentY += userAnswerHeight + 10; // Reduced from 12
    
    // Correct answer with proper spacing - label on separate line (compact)
    doc.fontSize(9.5) // Reduced from 10
       .font('Helvetica-Bold')
       .fillColor('#8B0000')
       .text('Correct Answer:', margin, currentY);
    
    currentY += 12; // Reduced from 15
    
    const correctAnswerClean = (question.correctAnswer || '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
    
    doc.fontSize(9) // Reduced from 10
       .font('Helvetica')
       .fillColor('#28A745')
       .text(correctAnswerClean, margin + 8, currentY, {
         width: doc.page.width - margin - 8 - margin,
         lineGap: 1.5
       });
    
    const correctAnswerHeight = doc.heightOfString(correctAnswerClean, {
      width: doc.page.width - margin - 8 - margin,
      lineGap: 1.5
    });
    
    currentY += correctAnswerHeight + 12; // Reduced from 15
    
    // Individual feedback with better styling (compact)
    const individualFeedback = generateIndividualFeedback(question, isCorrect, userAnswer);
    if (individualFeedback) {
      doc.fontSize(9.5) // Reduced from 10
         .font('Helvetica-Bold')
         .fillColor('#8B0000')
         .text('Feedback:', margin, currentY);
      
      currentY += 12; // Reduced from 15
      
      doc.fontSize(8.5) // Reduced from 9
         .font('Helvetica-Oblique')
         .fillColor('#666666')
         .text(individualFeedback, margin + 8, currentY, {
           width: doc.page.width - margin - 8 - margin,
           align: 'justify',
           lineGap: 1.5
         });
      
      const feedbackHeight = doc.heightOfString(individualFeedback, {
        width: doc.page.width - margin - 8 - margin,
        align: 'justify',
        lineGap: 1.5
      });
      
      currentY += feedbackHeight + 10; // Reduced from 12
    }
    
    // Add separator line with maroon color (lighter and thinner)
    currentY += 8; // Reduced spacing
    doc.strokeColor('#8B0000')
       .lineWidth(0.3) // Thinner line
       .moveTo(margin, currentY)
       .lineTo(doc.page.width - margin, currentY)
       .stroke();
    
    currentY += 10; // Reduced spacing
  }
  
  // Recommendations & Next Steps (continue on same page if space available)
  // Check if we have enough space, otherwise add new page
  if (currentY > doc.page.height - 200) {
    doc.addPage();
    addWatermark(doc);
    currentY = margin;
  } else {
    currentY += 20; // Small gap before recommendations
  }
  
  // Section 5: Recommendations & Next Steps
  addSectionHeader(doc, 'Recommendations & Next Steps', margin, currentY);
  currentY += 20; // Reduced spacing
  
  const recommendations = generateRecommendations(percentage, examAttempt, questions);
  
  // Calculate recommendations height dynamically
  const recommendationsHeight = doc.heightOfString(recommendations, {
    width: doc.page.width - (2 * margin) - 30,
    lineGap: 2
  }) + 40;
  
  // Add background box for recommendations (dynamic height)
  doc.rect(margin - 5, currentY - 5, doc.page.width - (2 * margin) + 10, recommendationsHeight)
     .fillColor('#F8F8F8')
     .fill()
     .strokeColor('#8B0000')
     .lineWidth(0.8)
     .stroke();
  
  currentY += 8;
  
  // Split recommendations into lines and add as bullet points
  const recommendationLines = recommendations.split('\n');
  recommendationLines.forEach(line => {
    if (line.trim()) {
      if (line.startsWith('•')) {
        // Bullet point with maroon bullet
        doc.fontSize(10) // Reduced from 11
           .font('Helvetica')
           .fillColor('#8B0000')
           .text('•', margin, currentY);
        
        doc.fontSize(10) // Reduced from 11
           .font('Helvetica')
           .fillColor('#333333')
           .text(line.substring(1).trim(), margin + 12, currentY, {
             width: doc.page.width - (2 * margin) - 12,
             lineGap: 1.5
           });
        currentY += 15; // Reduced spacing
      } else {
        // Regular text
        doc.fontSize(10) // Reduced from 11
           .font('Helvetica')
           .fillColor('#333333')
           .text(line, margin, currentY, {
             width: doc.page.width - (2 * margin),
             lineGap: 1.5
           });
        currentY += 15; // Reduced spacing
      }
    }
  });
  
  // Enhanced footer with maroon styling
  currentY = doc.page.height - 80;
  
  // Add decorative line above footer
  doc.strokeColor('#8B0000')
     .lineWidth(1)
     .moveTo(margin, currentY - 10)
     .lineTo(doc.page.width - margin, currentY - 10)
     .stroke();
  
  doc.fontSize(11)
     .font('Helvetica-Bold')
     .fillColor('#8B0000')
     .text('Generated by TEGA - Training and Employment Generation Activity', margin, currentY, {
       align: 'center',
       width: doc.page.width - (2 * margin)
     });
  
  doc.fontSize(9)
     .font('Helvetica')
     .fillColor('#666666')
     .text(`Generated on: ${new Date().toLocaleString('en-IN')}`, margin, currentY + 15, {
       align: 'center',
       width: doc.page.width - (2 * margin)
     });
}

/**
 * Add a section header with maroon styling
 */
function addSectionHeader(doc, title, x, y, width = null) {
  const sectionWidth = width || (doc.page.width - (2 * x));
  const headerHeight = 28; // Reduced from 35
  
  // Add background box for section header
  doc.rect(x - 5, y - 5, sectionWidth + 10, headerHeight)
     .fillColor('#F8F8F8')
     .fill()
     .strokeColor('#8B0000')
     .lineWidth(0.8)
     .stroke();
  
  // Section title with maroon color
  doc.fontSize(13) // Reduced from 15
     .font('Helvetica-Bold')
     .fillColor('#8B0000')
     .text(title, x, y, {
       width: sectionWidth
     });
  
  // Add a subtle line under the title
  const textWidth = Math.min(doc.widthOfString(title), sectionWidth);
  doc.strokeColor('#8B0000')
     .lineWidth(1)
     .moveTo(x, y + 16)
     .lineTo(x + textWidth, y + 16)
     .stroke();
}

/**
 * Add a field with label and value, returning new Y position
 */
function addFieldWithLabel(doc, label, value, x, y, width = null) {
  const margin = 54; // 0.75 inch margin for more space
  const fieldWidth = width || (doc.page.width - x - margin);
  
  // Label with maroon color (compact)
  doc.fontSize(10) // Reduced from 11
     .font('Helvetica-Bold')
     .fillColor('#8B0000')
     .text(`${label}:`, x, y);
  
  // Value with proper text wrapping and better styling
  const valueY = y + 14; // Reduced from 16
  const textHeight = doc.heightOfString(value, {
    width: fieldWidth - 20,
    align: 'left',
    lineGap: 1.5
  });
  
  doc.fontSize(9.5) // Slightly smaller
     .font('Helvetica')
     .fillColor('#333333')
     .text(value, x + 18, valueY, {
       width: fieldWidth - 18,
       align: 'left',
       lineGap: 1.5
     });
  
  return valueY + textHeight + 8; // Return new Y position with compact padding
}

/**
 * Generate performance suggestion based on percentage
 */
function generatePerformanceSuggestion(percentage) {
  if (percentage >= 90) {
    return "Excellent performance! You have demonstrated outstanding mastery of the subject.";
  } else if (percentage >= 80) {
    return "Very good performance! You have a solid understanding with room for minor improvements.";
  } else if (percentage >= 70) {
    return "Good performance! Focus on strengthening your knowledge in specific areas.";
  } else if (percentage >= 60) {
    return "Satisfactory performance. Consider reviewing fundamental concepts and practicing more.";
  } else if (percentage >= 50) {
    return "Below average performance. We recommend revisiting the course material and seeking additional help.";
  } else {
    return "Poor performance. We strongly recommend retaking the course and focusing on basic concepts.";
  }
}

/**
 * Generate overall performance feedback
 */
function generateOverallFeedback(percentage, correctAnswers, totalQuestions) {
  if (percentage >= 90) {
    return `Excellent performance! You scored ${percentage.toFixed(2)}% with ${correctAnswers} out of ${totalQuestions} correct answers. This demonstrates a strong understanding of the subject matter. Keep up the great work!`;
  } else if (percentage >= 80) {
    return `Very good performance! You scored ${percentage.toFixed(2)}% with ${correctAnswers} out of ${totalQuestions} correct answers. You have a solid grasp of most concepts with room for improvement in a few areas.`;
  } else if (percentage >= 70) {
    return `Good performance! You scored ${percentage.toFixed(2)}% with ${correctAnswers} out of ${totalQuestions} correct answers. You understand the basics well but should focus on strengthening your knowledge in specific topics.`;
  } else if (percentage >= 60) {
    return `Satisfactory performance. You scored ${percentage.toFixed(2)}% with ${correctAnswers} out of ${totalQuestions} correct answers. Consider reviewing the fundamental concepts and practicing more to improve your understanding.`;
  } else if (percentage >= 50) {
    return `Below average performance. You scored ${percentage.toFixed(2)}% with ${correctAnswers} out of ${totalQuestions} correct answers. We recommend revisiting the course material and seeking additional help to strengthen your foundation.`;
  } else {
    return `Poor performance. You scored ${percentage.toFixed(2)}% with ${correctAnswers} out of ${totalQuestions} correct answers. We strongly recommend retaking the course and focusing on understanding the basic concepts before attempting the exam again.`;
  }
}

/**
 * Generate individual question feedback with more specific and helpful content
 */
function generateIndividualFeedback(question, isCorrect, userAnswer) {
  if (isCorrect) {
    const feedbacks = [
      "Excellent! You have a strong understanding of this concept.",
      "Well done! Your answer demonstrates clear comprehension of the topic.",
      "Perfect! This shows you've mastered the fundamentals here.",
      "Great work! Your knowledge in this area is solid.",
      "Outstanding! You've applied the concept correctly.",
      "Brilliant! This answer shows deep understanding.",
      "Superb! You've grasped this topic completely."
    ];
    return feedbacks[Math.floor(Math.random() * feedbacks.length)];
  } else {
    if (!userAnswer) {
      return "This question was not attempted. Consider reviewing the topic and practicing similar questions to improve your understanding.";
    }
    
    const feedbacks = [
      `This concept needs more attention. Focus on understanding ${question.subject || 'the fundamentals'} and practice similar problems.`,
      "Review the core principles of this topic. Consider seeking additional help or resources to strengthen your understanding.",
      "This area requires more study. Break down the concept into smaller parts and practice step by step.",
      "Take time to understand the underlying principles here. Practice with similar examples to build confidence.",
      "This topic needs reinforcement. Consider reviewing course materials and asking for clarification if needed.",
      "Focus on the basics of this concept first. Once you understand the fundamentals, you'll find it easier to solve similar problems."
    ];
    return feedbacks[Math.floor(Math.random() * feedbacks.length)];
  }
}

/**
 * Generate recommendations based on performance
 */
function generateRecommendations(percentage, examAttempt, questions) {
  let recommendations = "Based on your performance, here are our recommendations:\n\n";
  
  if (percentage >= 80) {
    recommendations += "• Continue practicing advanced topics in this subject\n";
    recommendations += "• Consider taking advanced level courses\n";
    recommendations += "• Share your knowledge by helping other students\n";
    recommendations += "• Apply for internships or projects in this field\n";
  } else if (percentage >= 60) {
    recommendations += "• Review the topics where you made mistakes\n";
    recommendations += "• Practice more questions from weak areas\n";
    recommendations += "• Join study groups or seek peer help\n";
    recommendations += "• Consider retaking the exam after preparation\n";
  } else {
    recommendations += "• Start with basic concepts and fundamentals\n";
    recommendations += "• Take additional courses or tutorials\n";
    recommendations += "• Seek help from instructors or mentors\n";
    recommendations += "• Practice regularly with sample questions\n";
    recommendations += "• Consider one-on-one tutoring sessions\n";
  }

  recommendations += "\nRemember: Every exam is a learning opportunity. Use this feedback to identify your strengths and areas for improvement. TEGA is here to support your learning journey!";

  return recommendations;
}
