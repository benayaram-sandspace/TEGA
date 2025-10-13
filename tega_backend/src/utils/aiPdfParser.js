import { GoogleGenerativeAI } from '@google/generative-ai';
import fs from 'fs/promises';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const pdfParse = require('pdf-parse');

// Initialize Gemini AI (FREE tier available)
// Get free API key from: https://makersuite.google.com/app/apikey
const genAI = process.env.GEMINI_API_KEY 
  ? new GoogleGenerativeAI(process.env.GEMINI_API_KEY)
  : null;

/**
 * Parse PDF using AI (Google Gemini - FREE)
 * Extracts questions more accurately including context
 */
export async function parseWithAI(filePath, companyName) {
  try {
    if (!genAI) {
      return await parseWithBasicMethod(filePath, companyName);
    }


    // Read PDF text
    const dataBuffer = await fs.readFile(filePath);
    const pdfData = await pdfParse(dataBuffer);
    

    // Use Gemini AI to extract questions intelligently
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

    const prompt = `
Extract all multiple choice questions from the following text. For each question, extract:
- Question number
- Complete question text (including any formulas, tables, or additional context)
- All options (A, B, C, D, etc.)
- Correct answer

Format as JSON array:
[
  {
    "questionNumber": 1,
    "questionText": "complete question text",
    "options": [
      {"label": "A", "text": "option A text"},
      {"label": "B", "text": "option B text"},
      {"label": "C", "text": "option C text"},
      {"label": "D", "text": "option D text"}
    ],
    "correctAnswer": "B",
    "category": "numerical/verbal/reasoning/coding"
  }
]

Text to extract from:
${pdfData.text}

Important:
- Preserve complete question text (don't truncate)
- If question has a table, convert it to readable text
- If question has math formula, keep the formula text
- Extract ALL questions, not just some
- Ensure each question has exactly 4 options (A, B, C, D) unless it's a different format
- Return ONLY the JSON array, no extra text
`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const aiText = response.text();
    

    // Parse AI response (should be JSON)
    let aiQuestions = [];
    try {
      // Extract JSON from response (AI might wrap it in markdown)
      const jsonMatch = aiText.match(/\[[\s\S]*\]/);
      if (jsonMatch) {
        aiQuestions = JSON.parse(jsonMatch[0]);
      } else {
        return await parseWithBasicMethod(filePath, companyName);
      }
    } catch (parseError) {
      return await parseWithBasicMethod(filePath, companyName);
    }

    // Convert AI format to our database format
    const questions = aiQuestions.map(q => ({
      companyName,
      questionText: q.questionText,
      questionType: determineQuestionType(q),
      options: q.options.map(opt => ({
        text: opt.text,
        isCorrect: opt.label === q.correctAnswer
      })),
      difficulty: 'medium',
      category: mapCategory(q.category || 'technical'),
      uploadedFrom: 'pdf-ai',
      isActive: true
    }));


    return {
      success: true,
      totalPages: pdfData.numpages,
      questionsFound: questions.length,
      questions,
      rawText: pdfData.text,
      method: 'ai-gemini'
    };

  } catch (error) {
    // Fallback to basic parsing
    return await parseWithBasicMethod(filePath, companyName);
  }
}

/**
 * Fallback to basic parsing if AI fails
 */
async function parseWithBasicMethod(filePath, companyName) {
  const { parsePDFQuestions } = await import('./pdfParser.js');
  return await parsePDFQuestions(filePath, companyName);
}

/**
 * Determine question type from AI extracted data
 */
function determineQuestionType(aiQuestion) {
  if (aiQuestion.options.length === 2 && 
      aiQuestion.options.every(opt => ['True', 'False'].includes(opt.text))) {
    return 'true-false';
  }
  if (aiQuestion.options.length > 0) {
    return 'mcq';
  }
  return 'subjective';
}

/**
 * Map AI category to our system categories
 */
function mapCategory(aiCategory) {
  const mapping = {
    'numerical': 'aptitude',
    'verbal': 'verbal',
    'reasoning': 'reasoning',
    'coding': 'coding',
    'programming': 'coding',
    'technical': 'technical',
    'hr': 'hr'
  };
  return mapping[aiCategory.toLowerCase()] || 'technical';
}

export default {
  parseWithAI
};

