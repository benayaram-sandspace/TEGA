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
    // Create PDF document
    const doc = new PDFDocument({
      size: 'A4',
      margins: {
        top: 50,
        bottom: 50,
        left: 50,
        right: 50
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
    // Add subtle watermark with TEGA logo
    doc.save();
    doc.rotate(-45, { origin: [doc.page.width / 2, doc.page.height / 2] });
    doc.fontSize(60)
       .fillColor('#E0E0E0', 0.1) // Very subtle watermark
       .text('TEGA', doc.page.width / 2 - 90, doc.page.height / 2 - 30);
    doc.restore();
    
    // Call original endPage handler if it exists
    if (originalEndPage) {
      originalEndPage.forEach(handler => handler.call(this));
    }
  });
}

/**
 * Generate main PDF content
 */
async function generatePDFContent(doc, examAttempt, questions) {
  const { studentId, examId, score, totalMarks, correctAnswers, wrongAnswers, unattempted, percentage, endTime } = examAttempt;
  
  // Professional Header Section with TEGA branding
  doc.fontSize(24)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text('TEGA EXAM FEEDBACK REPORT', 0, 60, {
       align: 'center',
       width: doc.page.width
     });

  // Add professional line separator
  doc.strokeColor('#003366')
     .lineWidth(2)
     .moveTo(doc.page.width / 2 - 80, 90)
     .lineTo(doc.page.width / 2 + 80, 90)
     .stroke();

  // Add generation timestamp
  doc.fontSize(10)
     .font('Helvetica')
     .fillColor('#555555')
     .text(`Generated on: ${new Date().toLocaleString('en-IN')}`, 0, 100, {
       align: 'center',
       width: doc.page.width
     });

  // Student Details Section with professional styling
  doc.rect(40, 120, doc.page.width - 80, 100)
     .fillColor('#F5F5F5')
     .fill()
     .strokeColor('#003366')
     .lineWidth(1)
     .stroke();

  doc.fontSize(14)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text('Student Details', 50, 135);

  // Student details with proper formatting
  const studentDetails = [
    { label: 'Name', value: `${studentId.firstName} ${studentId.lastName}` },
    { label: 'Student ID', value: studentId.studentId || 'N/A' },
    { label: 'Institute', value: studentId.institute || 'N/A' },
    { label: 'Email', value: studentId.email || 'N/A' }
  ];

  let yPos = 155;
  studentDetails.forEach(detail => {
    doc.fontSize(12)
       .font('Helvetica-Bold')
       .fillColor('#003366')
       .text(`${detail.label}:`, 50, yPos);
    
    doc.fontSize(12)
       .font('Helvetica')
       .fillColor('#555555')
       .text(detail.value, 50, yPos + 15, {
         width: doc.page.width - 100
       });
    
    yPos += 30;
  });

  // Horizontal rule separator
  doc.strokeColor('#003366')
     .lineWidth(1)
     .moveTo(40, 240)
     .lineTo(doc.page.width - 40, 240)
     .stroke();

  // Exam Details Section with professional styling
  doc.fontSize(14)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text('Exam Details', 50, 255);

  // Exam name and subject in dark blue bold
  doc.fontSize(13)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text(`Exam: ${examId.title}`, 50, 275);

  doc.fontSize(13)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text(`Subject: ${examId.subject || 'N/A'}`, 50, 295);

  // Date and duration in smaller gray text
  doc.fontSize(11)
     .font('Helvetica')
     .fillColor('#555555')
     .text(`Date: ${new Date(endTime).toLocaleDateString('en-IN')}`, 50, 315);

  doc.fontSize(11)
     .font('Helvetica')
     .fillColor('#555555')
     .text(`Duration: ${examId.duration} minutes`, 50, 330);

  // Performance Summary Section with light blue box
  doc.rect(40, 350, doc.page.width - 80, 120)
     .fillColor('#E3F2FD')
     .fill()
     .strokeColor('#003366')
     .lineWidth(1)
     .stroke();

  doc.fontSize(14)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text('Performance Summary', 50, 365);

  // Performance metrics with consistent alignment
  const metrics = [
    { label: 'Total Questions', value: questions.length },
    { label: 'Correct Answers', value: correctAnswers },
    { label: 'Incorrect Answers', value: wrongAnswers },
    { label: 'Unattempted', value: unattempted },
    { label: 'Score', value: `${score}/${totalMarks}` },
    { label: 'Percentage', value: `${percentage.toFixed(2)}%` }
  ];

  let metricsYPos = 385;
  metrics.forEach((metric, index) => {
    const xPos = 50 + (index % 2) * 250;
    if (index % 2 === 0 && index > 0) metricsYPos += 25;
    
    doc.fontSize(12)
       .font('Helvetica-Bold')
       .fillColor('#003366')
       .text(`${metric.label}:`, xPos, metricsYPos);
    
    doc.fontSize(12)
       .font('Helvetica-Bold')
       .fillColor('#003366')
       .text(metric.value, xPos + 120, metricsYPos);
  });

  // Overall performance suggestion
  const performanceSuggestion = generatePerformanceSuggestion(percentage);
  doc.fontSize(12)
     .font('Helvetica-BoldOblique')
     .fillColor(percentage >= 70 ? '#00A859' : '#D32F2F')
     .text(performanceSuggestion, 50, metricsYPos + 30, {
       width: doc.page.width - 100
     });

  // Check if we need a new page for questions
  if (metricsYPos + 100 > doc.page.height - 100) {
    doc.addPage();
    addWatermark(doc);
  }

  // Question-wise Feedback Section with professional styling
  doc.fontSize(16)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text('Question-wise Feedback', 50, 50);

  let currentY = 70;
  const questionsPerPage = 3; // Optimized for better spacing
  let questionCount = 0;

  for (let i = 0; i < questions.length; i++) {
    const question = questions[i];
    const userAnswer = examAttempt.answers.get(question._id.toString());
    const isCorrect = userAnswer === question.correctAnswer;
    
    // Check if we need a new page
    if (currentY > doc.page.height - 250) {
      doc.addPage();
      addWatermark(doc);
      currentY = 50;
    }

    // Add a subtle background for each question with proper padding
    doc.rect(40, currentY - 5, doc.page.width - 80, 180)
       .fillColor('#F5F5F5')
       .fill()
       .strokeColor('#E0E0E0')
       .lineWidth(1)
       .stroke();

    // Question number with bold font
    doc.fontSize(12)
       .font('Helvetica-Bold')
       .fillColor('#003366')
       .text(`Question ${i + 1}`, 50, currentY + 10);

    // Correct/Incorrect indicator with proper colors
    doc.fontSize(12)
       .font('Helvetica-Bold')
       .fillColor(isCorrect ? '#00A859' : '#D32F2F')
       .text(isCorrect ? 'Correct' : 'Incorrect', doc.page.width - 120, currentY + 10);

    currentY += 30;

    // Question text with proper formatting
    doc.fontSize(11)
       .font('Helvetica')
       .fillColor('#555555')
       .text(question.question, 50, currentY, {
         width: doc.page.width - 100,
         align: 'justify'
       });

    currentY += 35;

    // User's answer and correct answer side-by-side
    doc.fontSize(11)
       .font('Helvetica-Bold')
       .fillColor('#555555')
       .text(`Your Answer: ${userAnswer || 'Not Attempted'}`, 50, currentY);

    doc.fontSize(11)
       .font('Helvetica-Bold')
       .fillColor(isCorrect ? '#00A859' : '#D32F2F')
       .text(`Correct Answer: ${question.correctAnswer}`, 50, currentY + 15);

    currentY += 35;

    // Dynamic feedback message in italic gray font
    const individualFeedback = generateIndividualFeedback(question, isCorrect, userAnswer);
    if (individualFeedback) {
      doc.fontSize(10)
         .font('Helvetica-Oblique')
         .fillColor('#555555')
         .text(`Feedback: ${individualFeedback}`, 50, currentY, {
           width: doc.page.width - 100,
           align: 'justify'
         });
      currentY += 25;
    }

    currentY += 20; // Space between questions
    questionCount++;
  }

  // Final page with recommendations - Professional Design
  doc.addPage();
  addWatermark(doc);

  // Professional header for recommendations page
  doc.fontSize(18)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text('Recommendations & Next Steps', 0, 50, {
       align: 'center',
       width: doc.page.width
     });

  // Add professional line separator
  doc.strokeColor('#003366')
     .lineWidth(2)
     .moveTo(doc.page.width / 2 - 100, 80)
     .lineTo(doc.page.width / 2 + 100, 80)
     .stroke();

  const recommendations = generateRecommendations(percentage, examAttempt, questions);
  
  // Professional card design for recommendations
  doc.rect(40, 100, doc.page.width - 80, 200)
     .fillColor('#F5F5F5')
     .fill()
     .strokeColor('#003366')
     .lineWidth(1)
     .stroke();

  doc.fontSize(14)
     .font('Helvetica-Bold')
     .fillColor('#003366')
     .text('Personalized Recommendations', 50, 120);
  
  doc.fontSize(11)
     .font('Helvetica')
     .fillColor('#555555')
     .text(recommendations, 50, 145, {
       width: doc.page.width - 100,
       align: 'justify'
     });

  // Professional footer
  doc.fontSize(10)
     .font('Helvetica-Bold')
     .fillColor('#555555')
     .text('Generated by TEGA - Training and Employment Generation Activity', 0, doc.page.height - 50, {
       align: 'center',
       width: doc.page.width
     });

  doc.fontSize(9)
     .font('Helvetica')
     .fillColor('#555555')
     .text(`Generated on: ${new Date().toLocaleString('en-IN')}`, 0, doc.page.height - 30, {
       align: 'center',
       width: doc.page.width
     });
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
 * Generate individual question feedback
 */
function generateIndividualFeedback(question, isCorrect, userAnswer) {
  if (isCorrect) {
    const feedbacks = [
      "Good understanding of this concept!",
      "Excellent! You've mastered this topic.",
      "Well done! Your answer shows clear comprehension.",
      "Perfect! You have a solid grasp of this area.",
      "Great work! This demonstrates good knowledge."
    ];
    return feedbacks[Math.floor(Math.random() * feedbacks.length)];
  } else {
    const feedbacks = [
      `Review topic: ${question.subject || 'This concept'}`,
      "Consider revisiting the fundamentals of this topic.",
      "This area needs more attention and practice.",
      "Focus on understanding the core concepts here.",
      "Additional study recommended for this topic."
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
