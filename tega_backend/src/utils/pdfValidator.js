/**
 * PDF Content Validator
 * Checks for elements that cannot be extracted properly
 */

/**
 * Validate PDF content and warn about extraction issues
 * @param {string} text - Extracted text from PDF
 * @param {object} pdfData - PDF metadata
 * @returns {object} Validation result with warnings
 */
export function validatePDFContent(text, pdfData) {
  const warnings = [];
  const errors = [];
  const issues = {
    hasImages: false,
    hasTables: false,
    hasMathSymbols: false,
    hasSuperscripts: false,
    hasSubscripts: false,
    hasSpecialChars: false,
    hasCodeBlocks: false,
    hasMultiColumn: false,
    isScanned: false
  };

  // Check 1: Detect if PDF might be scanned (very little text for pages)
  const textPerPage = text.length / pdfData.numpages;
  if (textPerPage < 100) {
    issues.isScanned = true;
    errors.push({
      type: 'SCANNED_PDF',
      severity: 'critical',
      message: 'This PDF appears to be scanned. Scanned PDFs cannot be extracted.',
      solution: 'Use OCR software or manually enter questions.'
    });
  }

  // Check 2: Detect mathematical symbols that may not extract properly
  const mathSymbols = ['∫', '∑', '√', '∞', '≠', '≈', '≤', '≥', '±', '×', '÷', '∂', 'π', '∆'];
  mathSymbols.forEach(symbol => {
    if (text.includes(symbol)) {
      issues.hasMathSymbols = true;
    }
  });
  if (issues.hasMathSymbols) {
    warnings.push({
      type: 'MATH_SYMBOLS',
      severity: 'high',
      message: 'PDF contains mathematical symbols (∫, √, ∑, etc.) that may not extract correctly.',
      solution: 'Write formulas as text (e.g., "integral of x^2" instead of "∫x²")',
      affectedCount: mathSymbols.filter(s => text.includes(s)).length
    });
  }

  // Check 3: Detect superscripts (x², x³, etc.)
  const superscriptPattern = /[²³⁴⁵⁶⁷⁸⁹⁰¹]/;
  if (superscriptPattern.test(text)) {
    issues.hasSuperscripts = true;
    warnings.push({
      type: 'SUPERSCRIPTS',
      severity: 'medium',
      message: 'PDF contains superscripts (x², x³) that will become plain text (x2, x3).',
      solution: 'Use caret notation (x^2, x^3) instead of superscripts.',
      example: 'x² → x^2, x³ → x^3'
    });
  }

  // Check 4: Detect subscripts (H₂O, etc.)
  const subscriptPattern = /[₀₁₂₃₄₅₆₇₈₉]/;
  if (subscriptPattern.test(text)) {
    issues.hasSubscripts = true;
    warnings.push({
      type: 'SUBSCRIPTS',
      severity: 'medium',
      message: 'PDF contains subscripts (H₂O) that will become plain text (H2O).',
      solution: 'Use underscore notation (H_2O) or write as text.',
      example: 'H₂O → H2O or H_2O'
    });
  }

  // Check 5: Detect table patterns
  const tablePatterns = [
    /\|.*\|.*\|/,  // Pipe-delimited tables
    /─{3,}/,       // Horizontal lines
    /┌|┐|└|┘|├|┤|┬|┴|┼/, // Box drawing characters
  ];
  const hasTableIndicators = tablePatterns.some(pattern => pattern.test(text));
  if (hasTableIndicators) {
    issues.hasTables = true;
    warnings.push({
      type: 'TABLES',
      severity: 'high',
      message: 'PDF contains tables that will be extracted as jumbled text.',
      solution: 'Convert table data to plain text format in questions.',
      example: 'Instead of table, write: "Given data - Name:John Age:25, Name:Mary Age:30"'
    });
  }

  // Check 6: Detect special characters that may break
  const specialChars = ['→', '←', '↑', '↓', '⇒', '⇐', '≫', '≪', '°', '§', '¶', '†', '‡'];
  const foundSpecialChars = specialChars.filter(char => text.includes(char));
  if (foundSpecialChars.length > 0) {
    issues.hasSpecialChars = true;
    warnings.push({
      type: 'SPECIAL_CHARS',
      severity: 'low',
      message: `PDF contains special characters (${foundSpecialChars.join(', ')}) that may not display correctly.`,
      solution: 'Replace with text equivalents (→ becomes "->", ° becomes "degrees").',
      foundChars: foundSpecialChars
    });
  }

  // Check 7: Detect code blocks (indentation patterns)
  const lines = text.split('\n');
  const indentedLines = lines.filter(line => line.match(/^\s{4,}/));
  if (indentedLines.length > 5) {
    issues.hasCodeBlocks = true;
    warnings.push({
      type: 'CODE_BLOCKS',
      severity: 'medium',
      message: 'PDF contains code blocks that will lose indentation.',
      solution: 'Write code in single lines or describe the logic instead.',
      example: 'Instead of formatted code, write: "function test() { return 5; }"'
    });
  }

  // Check 8: Detect multi-column layout (text length variations suggest columns)
  const avgLineLength = text.length / lines.length;
  const shortLines = lines.filter(line => line.length < avgLineLength / 2);
  if (shortLines.length > lines.length * 0.3) {
    issues.hasMultiColumn = true;
    warnings.push({
      type: 'MULTI_COLUMN',
      severity: 'high',
      message: 'PDF may have multi-column layout which causes text mixing.',
      solution: 'Convert to single-column layout before creating PDF.'
    });
  }

  // Check 9: Detect Greek letters
  const greekLetters = ['α', 'β', 'γ', 'δ', 'ε', 'θ', 'λ', 'μ', 'π', 'σ', 'φ', 'ω'];
  const foundGreek = greekLetters.filter(letter => text.includes(letter));
  if (foundGreek.length > 0) {
    warnings.push({
      type: 'GREEK_LETTERS',
      severity: 'medium',
      message: `PDF contains Greek letters (${foundGreek.join(', ')}) that may not extract properly.`,
      solution: 'Write out Greek letters as words (α → alpha, β → beta).',
      foundLetters: foundGreek
    });
  }

  // Check 10: Detect fractions
  const fractionPattern = /[¼½¾⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]/;
  if (fractionPattern.test(text)) {
    warnings.push({
      type: 'FRACTIONS',
      severity: 'low',
      message: 'PDF contains fraction symbols (½, ¼) that may not extract correctly.',
      solution: 'Write fractions as text (1/2, 1/4, 3/4).',
      example: '½ → 1/2, ¾ → 3/4'
    });
  }

  // Check 11: Estimate if images are present (indirect detection)
  // If text is sparse but file has many pages, might have images
  if (textPerPage < 500 && pdfData.numpages > 2 && !issues.isScanned) {
    issues.hasImages = true;
    warnings.push({
      type: 'POSSIBLE_IMAGES',
      severity: 'high',
      message: 'PDF may contain images or diagrams (low text density detected).',
      solution: 'Images cannot be extracted. Describe visual content in text.',
      note: 'This is an estimate. Verify manually.'
    });
  }

  // Generate summary
  const summary = {
    canExtract: errors.length === 0,
    totalWarnings: warnings.length,
    totalErrors: errors.length,
    criticalIssues: errors.filter(e => e.severity === 'critical').length,
    highWarnings: warnings.filter(w => w.severity === 'high').length,
    textQuality: calculateTextQuality(text, issues),
    recommendation: generateRecommendation(errors, warnings, issues)
  };

  return {
    success: errors.length === 0,
    summary,
    warnings,
    errors,
    issues,
    stats: {
      totalPages: pdfData.numpages,
      totalText: text.length,
      textPerPage: Math.round(textPerPage),
      totalLines: lines.length
    }
  };
}

/**
 * Calculate text quality score (0-100)
 */
function calculateTextQuality(text, issues) {
  let score = 100;
  
  if (issues.isScanned) score -= 100; // Fatal
  if (issues.hasTables) score -= 20;
  if (issues.hasMultiColumn) score -= 20;
  if (issues.hasImages) score -= 15;
  if (issues.hasMathSymbols) score -= 15;
  if (issues.hasCodeBlocks) score -= 10;
  if (issues.hasSuperscripts) score -= 10;
  if (issues.hasSubscripts) score -= 5;
  if (issues.hasSpecialChars) score -= 5;
  
  return Math.max(0, score);
}

/**
 * Generate recommendation based on issues
 */
function generateRecommendation(errors, warnings, issues) {
  if (errors.length > 0) {
    return {
      action: 'DO_NOT_PROCEED',
      message: 'PDF has critical issues and cannot be extracted properly.',
      alternatives: [
        'Use OCR software if scanned',
        'Convert to text-based PDF',
        'Manually enter questions'
      ]
    };
  }
  
  if (warnings.filter(w => w.severity === 'high').length > 2) {
    return {
      action: 'SIMPLIFY_FIRST',
      message: 'PDF has multiple complex elements. Simplify before uploading.',
      steps: [
        'Remove images and describe visually',
        'Convert tables to text format',
        'Replace math symbols with text equivalents',
        'Use single-column layout'
      ]
    };
  }
  
  if (warnings.length > 0) {
    return {
      action: 'PROCEED_WITH_CAUTION',
      message: 'PDF can be extracted but some elements may need manual correction.',
      advice: 'Review extracted questions carefully and edit as needed.'
    };
  }
  
  return {
    action: 'PROCEED',
    message: 'PDF appears to be in good format for extraction.',
    note: 'Always review extracted questions before saving.'
  };
}

/**
 * Check if question text is valid
 */
export function validateQuestionText(questionText) {
  const issues = [];
  
  if (questionText.length < 10) {
    issues.push('Question too short (minimum 10 characters)');
  }
  
  if (questionText.length > 1000) {
    issues.push('Question too long (maximum 1000 characters)');
  }
  
  // Check for incomplete text (ends mid-sentence)
  if (!questionText.match(/[.?!]$/)) {
    issues.push('Question appears incomplete (no ending punctuation)');
  }
  
  // Check for placeholder text
  const placeholders = ['...', '___', '[IMAGE]', '[TABLE]', '[CHART]'];
  placeholders.forEach(placeholder => {
    if (questionText.includes(placeholder)) {
      issues.push(`Contains placeholder: ${placeholder}`);
    }
  });
  
  return {
    valid: issues.length === 0,
    issues
  };
}

export default {
  validatePDFContent,
  validateQuestionText
};
