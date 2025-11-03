import PlacementModule from '../models/PlacementModule.js';
import PlacementQuestion from '../models/PlacementQuestion.js';
import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const sampleModules = [
  {
    title: 'Technical Skills Assessment',
    description: 'Evaluate your core programming and technical skills',
    moduleType: 'assessment',
    icon: 'Brain',
    color: 'blue',
    order: 1,
    features: [
      'Programming Fundamentals',
      'Data Structures',
      'Algorithms',
      'Problem Solving'
    ],
    isActive: true
  },
  {
    title: 'Coding Practice',
    description: 'Practice with real coding problems',
    moduleType: 'technical',
    icon: 'Code',
    color: 'purple',
    order: 2,
    features: [
      'LeetCode-style Problems',
      'Multiple Difficulty Levels',
      'Detailed Solutions',
      'Test Cases'
    ],
    isActive: true
  },
  {
    title: 'Interview Preparation',
    description: 'Master behavioral and HR interview questions',
    moduleType: 'interview',
    icon: 'Mic',
    color: 'red',
    order: 3,
    features: [
      'Common Interview Questions',
      'STAR Method Practice',
      'Behavioral Questions',
      'Mock Interviews'
    ],
    isActive: true
  }
];

const sampleQuestions = [
  // Assessment Questions
  {
    title: 'What is the time complexity of binary search?',
    description: 'Choose the correct time complexity for binary search algorithm',
    type: 'mcq',
    category: 'assessment',
    difficulty: 'easy',
    topic: 'Algorithms',
    options: [
      { text: 'O(n)', isCorrect: false },
      { text: 'O(log n)', isCorrect: true },
      { text: 'O(n log n)', isCorrect: false },
      { text: 'O(n²)', isCorrect: false }
    ],
    explanation: 'Binary search divides the search space in half with each iteration, resulting in O(log n) time complexity.',
    points: 10,
    timeLimit: 5,
    tags: ['algorithms', 'complexity', 'binary search'],
    companies: ['Google', 'Microsoft', 'Amazon'],
    isActive: true
  },
  {
    title: 'Which data structure uses LIFO principle?',
    description: 'Select the data structure that follows Last-In-First-Out principle',
    type: 'mcq',
    category: 'assessment',
    difficulty: 'easy',
    topic: 'Data Structures',
    options: [
      { text: 'Queue', isCorrect: false },
      { text: 'Stack', isCorrect: true },
      { text: 'Array', isCorrect: false },
      { text: 'Linked List', isCorrect: false }
    ],
    explanation: 'Stack is a LIFO (Last-In-First-Out) data structure where the last element added is the first one to be removed.',
    points: 10,
    timeLimit: 5,
    tags: ['data structures', 'stack'],
    companies: ['Facebook', 'Apple'],
    isActive: true
  },
  // Coding Questions
  {
    title: 'Two Sum Problem',
    description: 'Given an array of integers nums and an integer target, return indices of the two numbers that add up to target.',
    type: 'coding',
    category: 'technical',
    difficulty: 'easy',
    topic: 'Arrays',
    problemStatement: 'You may assume that each input would have exactly one solution, and you may not use the same element twice. You can return the answer in any order.',
    constraints: '• 2 <= nums.length <= 10⁴\n• -10⁹ <= nums[i] <= 10⁹\n• -10⁹ <= target <= 10⁹',
    inputFormat: 'nums = [2,7,11,15], target = 9',
    outputFormat: '[0,1]',
    sampleInput: '[2,7,11,15]\n9',
    sampleOutput: '[0,1]',
    testCases: [
      { input: '[2,7,11,15], 9', output: '[0,1]', isHidden: false },
      { input: '[3,2,4], 6', output: '[1,2]', isHidden: false },
      { input: '[3,3], 6', output: '[0,1]', isHidden: true }
    ],
    starterCode: {
      javascript: 'function twoSum(nums, target) {\n  // Write your code here\n  \n}',
      python: 'def two_sum(nums, target):\n    # Write your code here\n    pass',
      java: 'public int[] twoSum(int[] nums, int target) {\n    // Write your code here\n    \n}',
      cpp: 'vector<int> twoSum(vector<int>& nums, int target) {\n    // Write your code here\n    \n}'
    },
    hints: [
      'Try using a hash map to store numbers you\'ve seen',
      'For each number, check if target - number exists in the hash map'
    ],
    explanation: 'Use a hash map to store each number and its index. For each number, check if (target - number) exists in the hash map.',
    points: 25,
    timeLimit: 30,
    tags: ['arrays', 'hash map', 'leetcode'],
    companies: ['Amazon', 'Google', 'Microsoft'],
    isActive: true
  },
  {
    title: 'Reverse a String',
    description: 'Write a function that reverses a string. The input string is given as an array of characters.',
    type: 'coding',
    category: 'technical',
    difficulty: 'easy',
    topic: 'Strings',
    problemStatement: 'You must do this by modifying the input array in-place with O(1) extra memory.',
    sampleInput: '["h","e","l","l","o"]',
    sampleOutput: '["o","l","l","e","h"]',
    testCases: [
      { input: '["h","e","l","l","o"]', output: '["o","l","l","e","h"]', isHidden: false },
      { input: '["H","a","n","n","a","h"]', output: '["h","a","n","n","a","H"]', isHidden: true }
    ],
    starterCode: {
      javascript: 'function reverseString(s) {\n  // Write your code here\n  \n}',
      python: 'def reverse_string(s):\n    # Write your code here\n    pass'
    },
    hints: [
      'Use two pointers, one at the start and one at the end',
      'Swap characters and move pointers towards each other'
    ],
    explanation: 'Use two pointers technique: swap characters at start and end, then move pointers towards center.',
    points: 20,
    timeLimit: 20,
    tags: ['strings', 'two pointers'],
    companies: ['Facebook', 'LinkedIn'],
    isActive: true
  },
  // Interview Questions
  {
    title: 'Tell me about yourself',
    description: 'Provide a professional introduction highlighting your background, skills, and career goals.',
    type: 'behavioral',
    category: 'interview',
    difficulty: 'medium',
    topic: 'Self Introduction',
    explanation: 'Structure your answer: Present (current role/education) → Past (relevant experience) → Future (career goals). Keep it concise (1-2 minutes).',
    points: 15,
    timeLimit: 10,
    tags: ['behavioral', 'introduction'],
    companies: ['All Companies'],
    isActive: true
  },
  {
    title: 'Describe a challenging project you worked on',
    description: 'Use the STAR method to describe a challenging project: Situation, Task, Action, Result.',
    type: 'behavioral',
    category: 'interview',
    difficulty: 'medium',
    topic: 'Project Experience',
    explanation: 'Use STAR method: Situation (context), Task (what needed to be done), Action (steps you took), Result (outcome and learnings).',
    points: 20,
    timeLimit: 15,
    tags: ['behavioral', 'STAR method', 'projects'],
    companies: ['Google', 'Microsoft', 'Amazon'],
    isActive: true
  }
];

async function seedPlacementData() {
  try {
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tega-auth-starter');

    // Clear existing data
    await PlacementModule.deleteMany({});
    await PlacementQuestion.deleteMany({});

    // Insert Modules
    const createdModules = await PlacementModule.insertMany(sampleModules);

    // Insert Questions
    const createdQuestions = await PlacementQuestion.insertMany(sampleQuestions);

    // Assign questions to modules
    
    // Assessment module - first 2 questions
    await PlacementModule.findOneAndUpdate(
      { moduleType: 'assessment' },
      { $set: { questions: createdQuestions.slice(0, 2).map(q => q._id) } }
    );
    
    // Technical module - next 2 questions
    await PlacementModule.findOneAndUpdate(
      { moduleType: 'technical' },
      { $set: { questions: createdQuestions.slice(2, 4).map(q => q._id) } }
    );
    
    // Interview module - last 2 questions
    await PlacementModule.findOneAndUpdate(
      { moduleType: 'interview' },
      { $set: { questions: createdQuestions.slice(4, 6).map(q => q._id) } }
    );

    process.exit(0);
  } catch (error) {
    process.exit(1);
  }
}

// Run seeder
seedPlacementData();
