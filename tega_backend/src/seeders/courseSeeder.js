import Course from '../models/Course.js';

const courses = [
  {
    courseId: 'java-programming',
    name: 'Java Programming',
    description: 'Learn Java programming fundamentals and advanced concepts including OOP, data structures, and algorithms',
    price: 799,
    duration: '3 months',
    category: 'programming',
    difficulty: 'beginner',
    features: [
      'Comprehensive Java fundamentals',
      'Object-Oriented Programming concepts',
      'Data structures and algorithms',
      'Real-world projects',
      'Certificate upon completion'
    ],
    syllabus: [
      {
        title: 'Java Basics',
        description: 'Introduction to Java, variables, data types, operators',
        duration: '2 weeks'
      },
      {
        title: 'Control Structures',
        description: 'Conditional statements, loops, switch cases',
        duration: '2 weeks'
      },
      {
        title: 'Object-Oriented Programming',
        description: 'Classes, objects, inheritance, polymorphism',
        duration: '3 weeks'
      },
      {
        title: 'Data Structures',
        description: 'Arrays, lists, maps, sets',
        duration: '2 weeks'
      },
      {
        title: 'Exception Handling',
        description: 'Try-catch blocks, custom exceptions',
        duration: '1 week'
      }
    ],
    requirements: [
      'Basic computer knowledge',
      'No prior programming experience required',
      'Computer with Java Development Kit (JDK)'
    ],
    outcomes: [
      'Master Java programming fundamentals',
      'Understand OOP concepts',
      'Build real-world applications',
      'Prepare for Java certification exams'
    ],
    instructor: {
      name: 'Dr. Sarah Johnson',
      email: 'sarah.johnson@tega.com',
      bio: 'Senior Java Developer with 10+ years of experience in enterprise applications'
    }
  },
  {
    courseId: 'python-data-science',
    name: 'Python for Data Science',
    description: 'Master Python programming for data analysis and machine learning with practical projects',
    price: 799,
    duration: '4 months',
    category: 'ai',
    difficulty: 'intermediate',
    features: [
      'Python programming fundamentals',
      'Data analysis with Pandas and NumPy',
      'Machine learning algorithms',
      'Data visualization',
      'Real-world data science projects'
    ],
    syllabus: [
      {
        title: 'Python Fundamentals',
        description: 'Python basics, data types, functions, modules',
        duration: '3 weeks'
      },
      {
        title: 'Data Analysis',
        description: 'Pandas, NumPy, data manipulation',
        duration: '3 weeks'
      },
      {
        title: 'Data Visualization',
        description: 'Matplotlib, Seaborn, Plotly',
        duration: '2 weeks'
      },
      {
        title: 'Machine Learning',
        description: 'Scikit-learn, model training, evaluation',
        duration: '4 weeks'
      },
      {
        title: 'Advanced Topics',
        description: 'Deep learning, neural networks',
        duration: '2 weeks'
      }
    ],
    requirements: [
      'Basic programming knowledge',
      'Mathematics fundamentals',
      'Computer with Python installed'
    ],
    outcomes: [
      'Proficient in Python programming',
      'Data analysis and visualization skills',
      'Machine learning model development',
      'Real-world data science projects'
    ],
    instructor: {
      name: 'Prof. Michael Chen',
      email: 'michael.chen@tega.com',
      bio: 'Data Scientist with expertise in machine learning and AI'
    }
  },
  {
    courseId: 'react-development',
    name: 'React.js Development',
    description: 'Build modern web applications with React.js, hooks, state management, and routing',
    price: 799,
    duration: '2 months',
    category: 'web',
    difficulty: 'intermediate',
    features: [
      'React fundamentals and components',
      'Hooks and state management',
      'Routing and navigation',
      'API integration',
      'Modern web development practices'
    ],
    syllabus: [
      {
        title: 'React Basics',
        description: 'Components, JSX, props, state',
        duration: '2 weeks'
      },
      {
        title: 'Hooks',
        description: 'useState, useEffect, custom hooks',
        duration: '2 weeks'
      },
      {
        title: 'State Management',
        description: 'Context API, Redux basics',
        duration: '2 weeks'
      },
      {
        title: 'Routing',
        description: 'React Router, navigation',
        duration: '1 week'
      },
      {
        title: 'Advanced Topics',
        description: 'Performance optimization, testing',
        duration: '1 week'
      }
    ],
    requirements: [
      'Basic HTML, CSS, JavaScript knowledge',
      'Understanding of ES6+ features',
      'Computer with Node.js installed'
    ],
    outcomes: [
      'Build modern React applications',
      'Understand component architecture',
      'Implement state management',
      'Deploy React applications'
    ],
    instructor: {
      name: 'Alex Rodriguez',
      email: 'alex.rodriguez@tega.com',
      bio: 'Full-stack developer specializing in React and modern web technologies'
    }
  },
  {
    courseId: 'aws-cloud',
    name: 'AWS Cloud Practitioner',
    description: 'Get AWS Cloud Practitioner certification with hands-on experience in cloud services',
    price: 799,
    duration: '3 months',
    category: 'cloud',
    difficulty: 'beginner',
    features: [
      'AWS fundamentals and services',
      'Cloud architecture principles',
      'Security and compliance',
      'Cost optimization',
      'AWS certification preparation'
    ],
    syllabus: [
      {
        title: 'Cloud Fundamentals',
        description: 'Cloud computing basics, AWS overview',
        duration: '2 weeks'
      },
      {
        title: 'AWS Core Services',
        description: 'EC2, S3, VPC, IAM',
        duration: '3 weeks'
      },
      {
        title: 'Security & Compliance',
        description: 'Security best practices, compliance',
        duration: '2 weeks'
      },
      {
        title: 'Cost Management',
        description: 'Pricing models, cost optimization',
        duration: '2 weeks'
      },
      {
        title: 'Certification Prep',
        description: 'Practice exams, exam strategies',
        duration: '1 week'
      }
    ],
    requirements: [
      'Basic IT knowledge',
      'Understanding of networking concepts',
      'AWS free tier account'
    ],
    outcomes: [
      'AWS Cloud Practitioner certification',
      'Cloud architecture understanding',
      'AWS service proficiency',
      'Cost optimization skills'
    ],
    instructor: {
      name: 'Lisa Thompson',
      email: 'lisa.thompson@tega.com',
      bio: 'AWS Certified Solutions Architect with 8+ years of cloud experience'
    }
  },
  {
    courseId: 'tega-main-exam',
    name: 'Tega Main Exam',
    description: 'Comprehensive assessment across all technical domains for Tega Master Certification',
    price: 799,
    duration: 'One-time',
    category: 'comprehensive',
    difficulty: 'advanced',
    features: [
      '200+ comprehensive questions',
      'All technical domains covered',
      'Adaptive difficulty',
      'Prestigious certification',
      'Lifetime access'
    ],
    syllabus: [
      {
        title: 'Programming Fundamentals',
        description: 'Java, Python, JavaScript basics',
        duration: '1 hour'
      },
      {
        title: 'Web Development',
        description: 'HTML, CSS, React, Node.js',
        duration: '1 hour'
      },
      {
        title: 'Data Science & AI',
        description: 'Machine learning, data analysis',
        duration: '1 hour'
      },
      {
        title: 'Cloud & DevOps',
        description: 'AWS, Docker, CI/CD',
        duration: '30 minutes'
      },
      {
        title: 'Cybersecurity',
        description: 'Security fundamentals, best practices',
        duration: '30 minutes'
      }
    ],
    requirements: [
      'Intermediate programming knowledge',
      'Understanding of multiple domains',
      '3 hours of dedicated time'
    ],
    outcomes: [
      'Tega Master Certification',
      'Comprehensive skill assessment',
      'Professional recognition',
      'Career advancement opportunities'
    ],
    instructor: {
      name: 'Tega Certification Board',
      email: 'certification@tega.com',
      bio: 'Expert panel of industry professionals and educators'
    }
  }
];

export const seedCourses = async () => {
  try {
    // Clear existing courses
    await Course.deleteMany({});
    
    // Insert new courses
    await Course.insertMany(courses);
    
    
    // Log course details
    courses.forEach(course => {
    });
    
  } catch (error) {
  }
};

export { courses };
