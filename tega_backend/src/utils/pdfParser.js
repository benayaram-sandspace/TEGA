import fs from 'fs/promises';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const pdfParse = require('pdf-parse');

/**
 * Parse PDF and extract questions
 * This is a basic parser - can be enhanced based on PDF structure
 */
export async function parsePDFQuestions(filePath, companyName) {
  try {
    const dataBuffer = await fs.readFile(filePath);
    const pdfData = await pdfParse(dataBuffer);

    // Extract questions from text
    const questions = extractQuestionsFromText(pdfData.text, companyName, pdfData.numpages);
    
    return {
      success: true,
      totalPages: pdfData.numpages,
      questionsFound: questions.length,
      questions,
      rawText: pdfData.text, // For validation
      method: 'basic' // Parser method identifier
    };
  } catch (error) {
    throw new Error(`PDF parsing failed: ${error.message}`);
  }
}

/**
 * Extract structured questions from PDF text
 * Supports multiple question formats
 */
function extractQuestionsFromText(text, companyName, totalPages) {
  const questions = [];
  
  // Clean up text
  text = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
  
  // Pattern 1: Questions with numbered format
  // Example: "1. What is...? A) Option1 B) Option2 C) Option3 D) Option4 Answer: B"
  const pattern1 = /(\d+)\.\s*(.+?)\n\s*(?:A\)|a\))(.+?)\n\s*(?:B\)|b\))(.+?)\n\s*(?:C\)|c\))(.+?)\n\s*(?:D\)|d\))(.+?)(?:\n\s*(?:Answer|Ans|Correct):\s*([A-Da-d]))?/gi;
  
  let match;
  while ((match = pattern1.exec(text)) !== null) {
    const questionNum = match[1];
    const questionText = match[2].trim();
    const optionA = match[3].trim();
    const optionB = match[4].trim();
    const optionC = match[5].trim();
    const optionD = match[6].trim();
    const correctAnswer = match[7] ? match[7].toUpperCase() : null;
    
    const options = [
      { text: optionA, isCorrect: correctAnswer === 'A' },
      { text: optionB, isCorrect: correctAnswer === 'B' },
      { text: optionC, isCorrect: correctAnswer === 'C' },
      { text: optionD, isCorrect: correctAnswer === 'D' }
    ];
    
    // If no correct answer specified, mark first as correct (admin can edit later)
    if (!correctAnswer) {
      options[0].isCorrect = true;
    }
    
    questions.push({
      companyName,
      questionText,
      questionType: 'mcq',
      options,
      difficulty: 'medium',
      category: 'technical',
      uploadedFrom: 'pdf',
      pageNumber: estimatePageNumber(questionNum, totalPages, text),
      isActive: true
    });
  }
  
  // Pattern 2: True/False questions
  // Example: "5. JavaScript is a compiled language. (True/False) Answer: False"
  const pattern2 = /(\d+)\.\s*(.+?)\s*\(True\/False\)(?:\s*(?:Answer|Ans):\s*(True|False))?/gi;
  
  while ((match = pattern2.exec(text)) !== null) {
    const questionNum = match[1];
    const questionText = match[2].trim();
    const correctAnswer = match[3] ? match[3] : 'True'; // Default to True if not specified
    
    const options = [
      { text: 'True', isCorrect: correctAnswer === 'True' },
      { text: 'False', isCorrect: correctAnswer === 'False' }
    ];
    
    questions.push({
      companyName,
      questionText,
      questionType: 'true-false',
      options,
      difficulty: 'easy',
      category: 'technical',
      uploadedFrom: 'pdf',
      pageNumber: estimatePageNumber(questionNum, totalPages, text),
      isActive: true
    });
  }
  
  // Pattern 3: Fill in the blank / Short answer
  // Example: "10. _____ is used for styling web pages. Answer: CSS"
  const pattern3 = /(\d+)\.\s*(.+?_____+.+?)(?:\s*(?:Answer|Ans):\s*(.+?))?(?=\n\d+\.|$)/gi;
  
  while ((match = pattern3.exec(text)) !== null) {
    const questionNum = match[1];
    const questionText = match[2].trim();
    const correctAnswer = match[3] ? match[3].trim() : '';
    
    questions.push({
      companyName,
      questionText,
      questionType: 'subjective',
      correctAnswer,
      difficulty: 'medium',
      category: 'technical',
      uploadedFrom: 'pdf',
      pageNumber: estimatePageNumber(questionNum, totalPages, text),
      isActive: true
    });
  }
  
  // If no patterns matched, try simple question extraction
  if (questions.length === 0) {
    questions.push(...extractSimpleQuestions(text, companyName));
  }
  
  return questions;
}

/**
 * Fallback: Extract simple questions without strict patterns
 */
function extractSimpleQuestions(text, companyName) {
  const questions = [];
  const lines = text.split('\n');
  
  let currentQuestion = null;
  let optionIndex = 0;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    
    // Detect question (starts with number and dot or question mark)
    if (/^\d+[\.)]\s+.+\?/.test(line) || /^Q\d+[\.:\)]\s+/.test(line)) {
      // Save previous question if exists
      if (currentQuestion && currentQuestion.options.length > 0) {
        questions.push(currentQuestion);
      }
      
      // Start new question
      currentQuestion = {
        companyName,
        questionText: line.replace(/^\d+[\.)]\s+|^Q\d+[\.:\)]\s+/, '').trim(),
        questionType: 'mcq',
        options: [],
        difficulty: 'medium',
        category: 'technical',
        uploadedFrom: 'pdf',
        isActive: true
      };
      optionIndex = 0;
    }
    // Detect options
    else if (currentQuestion && /^[A-Da-d][\.)]\s+/.test(line)) {
      currentQuestion.options.push({
        text: line.replace(/^[A-Da-d][\.)]\s+/, '').trim(),
        isCorrect: optionIndex === 0 // Default first option as correct
      });
      optionIndex++;
    }
  }
  
  // Add last question
  if (currentQuestion && currentQuestion.options.length > 0) {
    questions.push(currentQuestion);
  }
  
  return questions;
}

/**
 * Estimate page number based on question number
 */
function estimatePageNumber(questionNum, totalPages, fullText) {
  try {
    const num = parseInt(questionNum);
    // Simple estimation: divide total text into pages
    const questionPosition = fullText.indexOf(`${questionNum}.`);
    const pageEstimate = Math.ceil((questionPosition / fullText.length) * totalPages);
    return Math.max(1, Math.min(pageEstimate, totalPages));
  } catch {
    return 1;
  }
}

/**
 * AI-Enhanced parsing (placeholder for future enhancement)
 * Can integrate with OpenAI API to better understand question structure
 */
export async function parseWithAI(pdfText, companyName) {
  // TODO: Implement AI-based parsing using OpenAI API
  // This would provide better accuracy for complex PDFs
  return extractQuestionsFromText(pdfText, companyName, 1);
}

/**
 * Validate extracted questions
 */
export function validateQuestions(questions) {
  const validQuestions = [];
  const errors = [];
  
  questions.forEach((q, index) => {
    const errs = [];
    
    if (!q.questionText || q.questionText.length < 10) {
      errs.push('Question text too short');
    }
    
    if (q.questionType === 'mcq') {
      if (!q.options || q.options.length < 2) {
        errs.push('MCQ must have at least 2 options');
      }
      
      const hasCorrect = q.options.some(opt => opt.isCorrect);
      if (!hasCorrect) {
        errs.push('No correct answer marked');
      }
    }
    
    if (errs.length > 0) {
      errors.push({ questionIndex: index + 1, errors: errs });
    } else {
      validQuestions.push(q);
    }
  });
  
  return {
    valid: validQuestions,
    invalid: errors,
    totalValid: validQuestions.length,
    totalInvalid: errors.length
  };
}

export default {
  parsePDFQuestions,
  parseWithAI,
  validateQuestions
};
