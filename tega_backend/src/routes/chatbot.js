import express from 'express';
import axios from 'axios';

const router = express.Router();

// Chatbot responses database
const chatbotResponses = {
  greeting: [
    "Hello! Welcome to TEGA! How can I assist you today?",
    "Hi there! I'm here to help with any questions about our courses and services.",
    "Welcome! What would you like to know about TEGA?",
    "Hello! I'm TEGA's virtual assistant. How can I help you today?"
  ],
  courses: [
    "We offer a wide range of courses including programming, data science, web development, mobile app development, and more!",
    "Our courses cover programming languages, data science, web development, mobile app development, and digital marketing.",
    "TEGA provides comprehensive training in programming, data science, web development, and emerging technologies.",
    "We have courses in Python, JavaScript, React, Node.js, Data Science, Machine Learning, and many more!"
  ],
  enrollment: [
    "You can enroll in courses directly through our website. Simply browse our course catalog and follow the enrollment process.",
    "To enroll, visit our courses page, select your desired course, and complete the registration process.",
    "Enrollment is easy! Just browse our courses, select one that interests you, and follow the simple registration steps.",
    "Simply go to our courses section, choose your preferred course, and click on 'Enroll Now' to get started."
  ],
  contact: [
    "You can reach us at +91-8143001777 or email us at tega@sandspacetechnologies.com",
    "Contact us at our main office in Vijayawada: NCK Plaza SBI Bank building, or call +91-8143001777",
    "We're available at +91-8143001777 or tega@sandspacetechnologies.com. Our office is in Vijayawada.",
    "Reach out to us via phone: +91-8143001777 or email: tega@sandspacetechnologies.com"
  ],
  hours: [
    "Our office hours are Monday to Friday: 9:00 AM - 6:00 PM, Saturday: 9:00 AM - 2:00 PM. We're closed on Sundays.",
    "We're open Monday-Friday 9 AM-6 PM and Saturday 9 AM-2 PM. Closed on Sundays.",
    "Visit us Monday-Friday 9:00 AM-6:00 PM or Saturday 9:00 AM-2:00 PM. We're closed on Sundays.",
    "Our working hours: Mon-Fri 9:00 AM-6:00 PM, Sat 9:00 AM-2:00 PM. We're closed on Sundays."
  ],
  location: [
    "Our main office is located at NCK Plaza SBI Bank building, Vijayawada, Andhra Pradesh.",
    "Find us at NCK Plaza SBI Bank building in Vijayawada, Andhra Pradesh.",
    "We're located at NCK Plaza SBI Bank building, Vijayawada, Andhra Pradesh, India.",
    "Visit us at NCK Plaza SBI Bank building, Vijayawada, Andhra Pradesh, India."
  ],
  pricing: [
    "Our course pricing varies depending on the program. Please contact us for detailed pricing information.",
    "Course fees depend on the program duration and content. Contact us for specific pricing details.",
    "We offer competitive pricing for all our courses. Reach out to us for detailed fee structure.",
    "Pricing varies by course. Please contact our team for accurate pricing information."
  ],
  duration: [
    "Course duration varies from 2 weeks to 6 months depending on the program you choose.",
    "Our courses range from short-term (2-4 weeks) to comprehensive programs (3-6 months).",
    "Duration depends on the course: short courses (2-4 weeks) to full programs (3-6 months).",
    "We offer flexible duration options from 2 weeks to 6 months based on your chosen program."
  ],
  default: [
    "I'm here to help! You can ask me about our courses, enrollment process, contact information, or office hours.",
    "That's a great question! I can help you with information about our courses, enrollment, contact details, or office hours.",
    "I'd be happy to assist you! Feel free to ask about our courses, enrollment, contact information, or any other queries.",
    "I'm TEGA's assistant! Ask me about courses, enrollment, contact info, office hours, or anything else you need to know."
  ]
};

// AI-powered response generation (using intelligent local system for now)
const generateAIResponse = async (userMessage, context = {}) => {
  // For now, use the intelligent local response system
  // This can be enhanced with actual AI integration later
  const response = generateIntelligentResponse(userMessage);
  
  // Ensure we return the response object directly
  return response;
};

// Enhanced local response generation
const generateIntelligentResponse = (userMessage) => {
  const lowerMessage = userMessage.toLowerCase();
  
  // More comprehensive pattern matching
  const patterns = {
    greeting: /\b(hello|hi|hey|good morning|good afternoon|good evening|greetings|welcome|namaste|namaskar)\b/,
    courses: /\b(course|courses|program|programs|training|learn|study|education|curriculum|python|javascript|react|node|data science|machine learning|web development|mobile app|digital marketing|java|c\+\+|html|css|sql|mongodb|mysql|php|angular|vue|flutter|android|ios)\b/,
    enrollment: /\b(enroll|enrollment|register|registration|join|sign up|admission|apply|how to join|become student|admission process|how to apply)\b/,
    contact: /\b(contact|phone|email|call|reach|get in touch|connect|support|help|number|address)\b/,
    hours: /\b(hour|hours|time|open|close|available|when|working hours|business hours|timing|schedule)\b/,
    location: /\b(location|address|where|place|office|visit|come|find|directions|vijayawada|hyderabad|visakhapatnam|andhra|telangana)\b/,
    pricing: /\b(price|pricing|cost|fee|fees|money|pay|payment|expensive|cheap|affordable|budget|rupees|rs|costly|free)\b/,
    duration: /\b(duration|long|time|weeks|months|days|finish|complete|how long|length|period|timeline)\b/,
    online: /\b(online|virtual|remote|distance|zoom|google meet|live classes|internet|webinar)\b/,
    offline: /\b(offline|physical|classroom|in-person|face to face|onsite|classroom|center|institute)\b/,
    certification: /\b(certificate|certification|certified|completion|diploma|degree|cert|valid|recognized)\b/,
    job: /\b(job|jobs|placement|career|employment|work|hire|recruitment|salary|package|company|interview)\b/,
    exam: /\b(exam|examination|test|assessment|quiz|evaluation|result|marks|score|pass|fail)\b/,
    faculty: /\b(teacher|instructor|faculty|mentor|trainer|staff|professor|guide)\b/,
    batch: /\b(batch|group|class|session|timing|morning|evening|weekend|weekday)\b/,
    doubt: /\b(doubt|question|query|problem|issue|confusion|clarify|explain|understand)\b/,
    material: /\b(material|notes|books|resources|study|content|syllabus|curriculum)\b/,
    project: /\b(project|assignment|practical|hands-on|real-time|industry|live)\b/
  };

  // Find matching patterns
  const matchedPatterns = Object.entries(patterns)
    .filter(([key, pattern]) => pattern.test(lowerMessage))
    .map(([key]) => key);
  

  // Generate contextual response based on matched patterns
  if (matchedPatterns.includes('greeting')) {
    return {
      message: "Hello! Welcome to TEGA! I'm here to help you with information about our courses, enrollment process, and services. What would you like to know?",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What are your office hours?",
        "Where are you located?",
        "What is the course duration?",
        "How much do courses cost?",
        "Do you offer online classes?",
        "What programming languages do you teach?",
        "Do you provide job placement?",
        "What are the prerequisites?"
      ]
    };
  }
  
  if (matchedPatterns.includes('courses')) {
    return {
      message: "TEGA offers comprehensive courses in programming (Python, JavaScript, React, Node.js, Java, C++), Data Science, Machine Learning, Web Development, Mobile App Development (Android, iOS, Flutter), and Digital Marketing. Each course includes hands-on projects and industry-relevant curriculum.",
      followUpOptions: [
        "How do I enroll in a course?",
        "What is the course duration?",
        "How much do courses cost?",
        "Do you offer online classes?",
        "What programming languages do you teach?",
        "Do you provide job placement?",
        "What are the prerequisites?",
        "Do you have beginner courses?",
        "What projects will I work on?",
        "Are there any discounts available?"
      ]
    };
  }
  
  if (matchedPatterns.includes('enrollment')) {
    return {
      message: "Enrolling at TEGA is simple! You can browse our courses online, select your preferred program, and complete the registration process. Our team is also available to guide you through the enrollment process. Contact us at +91-8143001777 for assistance.",
      followUpOptions: [
        "What courses do you offer?",
        "What is the course duration?",
        "How much do courses cost?",
        "What are your office hours?",
        "Do you offer online classes?",
        "What documents do I need for enrollment?",
        "Can I pay in installments?",
        "Do you offer scholarships?",
        "What is the admission process?",
        "Can I change my course later?"
      ]
    };
  }
  
  if (matchedPatterns.includes('contact')) {
    return {
      message: "You can reach TEGA at +91-8143001777 or email us at tega@sandspacetechnologies.com. Our main office is located at NCK Plaza SBI Bank building, Vijayawada, Andhra Pradesh. We're here to help with any questions!",
      followUpOptions: [
        "What are your office hours?",
        "Where are you located?",
        "How do I enroll?",
        "What courses do you offer?",
        "Can I visit your office?",
        "Do you have other locations?",
        "What is your email address?",
        "Can I schedule a consultation?",
        "Do you have a WhatsApp number?",
        "How can I reach your support team?"
      ]
    };
  }
  
  if (matchedPatterns.includes('hours')) {
    return {
      message: "TEGA's office hours are Monday to Friday: 9:00 AM - 6:00 PM, and Saturday: 9:00 AM - 2:00 PM. We're closed on Sundays. You can also reach us via phone or email outside these hours.",
      followUpOptions: [
        "Where are you located?",
        "How do I contact you?",
        "What courses do you offer?",
        "How do I enroll?",
        "Do you offer weekend classes?",
        "Can I visit outside office hours?",
        "What are your weekend timings?",
        "Do you have evening batches?",
        "Can I attend online during office hours?",
        "What if I miss a class?"
      ]
    };
  }
  
  if (matchedPatterns.includes('location')) {
    return {
      message: "TEGA has multiple locations: Main Office in Vijayawada (NCK Plaza SBI Bank building), Training Center in Hyderabad (HITEC City), and Branch Office in Visakhapatnam (Rushikonda IT Park). All locations offer the same quality education and support.",
      followUpOptions: [
        "What are your office hours?",
        "How do I contact you?",
        "What courses do you offer?",
        "How do I enroll?",
        "Can I visit any location?",
        "Do all locations have the same courses?",
        "Which location is closest to me?",
        "Do you provide transportation?",
        "Is parking available?",
        "Can I transfer between locations?"
      ]
    };
  }
  
  if (matchedPatterns.includes('pricing')) {
    return {
      message: "TEGA offers competitive pricing for all our courses with flexible payment options including EMI plans. Course fees vary based on the program duration and content. Contact us at +91-8143001777 for detailed pricing information and available discounts.",
      followUpOptions: [
        "What courses do you offer?",
        "What is the course duration?",
        "How do I enroll?",
        "Do you offer EMI options?",
        "Are there any discounts available?",
        "What payment methods do you accept?",
        "Can I pay in installments?",
        "Do you offer scholarships?",
        "What is the refund policy?",
        "Are there any hidden fees?"
      ]
    };
  }
  
  if (matchedPatterns.includes('duration')) {
    return {
      message: "Course duration at TEGA varies from 2 weeks to 6 months depending on the program. We offer both short-term intensive courses and comprehensive long-term programs. Each course is designed to provide maximum learning in the optimal timeframe.",
      followUpOptions: [
        "What courses do you offer?",
        "How much do courses cost?",
        "How do I enroll?",
        "Do you offer online classes?",
        "What is the shortest course?",
        "What is the longest course?",
        "Can I complete courses faster?",
        "What if I need more time?",
        "Do you offer intensive programs?",
        "Can I study part-time?"
      ]
    };
  }
  
  if (matchedPatterns.includes('online')) {
    return {
      message: "Yes! TEGA offers both online and offline classes to accommodate different learning preferences. Our online classes use modern platforms and interactive tools to ensure effective learning from anywhere.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "How much do online courses cost?",
        "What platforms do you use?",
        "Do you provide study materials?",
        "Can I access recordings later?",
        "Do you have live sessions?",
        "What if I miss an online class?",
        "Do you provide technical support?"
      ]
    };
  }
  
  if (matchedPatterns.includes('offline')) {
    return {
      message: "TEGA provides excellent offline classroom training at our modern facilities in Vijayawada, Hyderabad, and Visakhapatnam. Our classrooms are equipped with the latest technology and provide hands-on learning experiences.",
      followUpOptions: [
        "Where are you located?",
        "What are your office hours?",
        "What courses do you offer?",
        "How do I enroll?",
        "What facilities do you have?",
        "Do you provide lab access?"
      ]
    };
  }
  
  if (matchedPatterns.includes('certification')) {
    return {
      message: "Upon successful completion of any TEGA course, you'll receive a recognized certificate that validates your skills. Our certifications are industry-relevant and help boost your career prospects.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "Do you provide job placement?",
        "Are certificates recognized by companies?",
        "What exams do I need to pass?"
      ]
    };
  }
  
  if (matchedPatterns.includes('job')) {
    return {
      message: "TEGA provides comprehensive job placement assistance and career guidance. We help students with resume building, interview preparation, and connecting with top companies. Our placement team works closely with industry partners to create job opportunities.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "How much do courses cost?",
        "What companies do you partner with?",
        "What is the placement success rate?"
      ]
    };
  }
  
  if (matchedPatterns.includes('exam')) {
    return {
      message: "TEGA conducts regular assessments and exams to evaluate student progress. We offer skill tests, certification exams, and practical assessments. Results are provided promptly with detailed feedback to help students improve.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "Do you provide certificates?",
        "What types of exams do you conduct?",
        "How are results provided?"
      ]
    };
  }

  if (matchedPatterns.includes('faculty')) {
    return {
      message: "TEGA has experienced and qualified faculty members who are industry experts in their respective fields. Our instructors have practical experience and provide personalized guidance to help students succeed.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "Do you provide one-on-one support?",
        "What qualifications do instructors have?",
        "How do instructors help students?"
      ]
    };
  }

  if (matchedPatterns.includes('batch')) {
    return {
      message: "TEGA offers flexible batch timings including morning, evening, and weekend batches to accommodate different schedules. You can choose the timing that works best for you.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What are your office hours?",
        "Do you offer online classes?",
        "What are the batch sizes?",
        "Can I change my batch timing?"
      ]
    };
  }

  if (matchedPatterns.includes('doubt')) {
    return {
      message: "TEGA provides dedicated doubt-clearing sessions and one-on-one support. Our instructors are always available to help students understand concepts and resolve any queries.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "Do you provide study materials?",
        "How do I get help with doubts?",
        "Are instructors available after class?"
      ]
    };
  }

  if (matchedPatterns.includes('material')) {
    return {
      message: "TEGA provides comprehensive study materials, notes, and resources for all courses. Students get access to updated content, practical examples, and industry-relevant case studies.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "Do you provide online materials?",
        "What types of resources do you offer?",
        "Are materials updated regularly?"
      ]
    };
  }

  if (matchedPatterns.includes('project')) {
    return {
      message: "TEGA emphasizes hands-on learning with real-time projects and industry-based assignments. Students work on live projects that help them gain practical experience and build a strong portfolio.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "Do you provide job placement?",
        "What types of projects do students work on?",
        "How do projects help in career development?"
      ]
    };
  }

  // Handle specific questions with more context
  if (lowerMessage.includes('what') && lowerMessage.includes('tega')) {
    return {
      message: "TEGA (Training and Employment Generation Activity) is a leading educational institution that provides comprehensive training in programming, data science, web development, and emerging technologies. We offer both online and offline classes with industry-relevant curriculum and job placement assistance.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "Where are you located?",
        "What are your office hours?",
        "How much do courses cost?",
        "Do you provide job placement?"
      ]
    };
  }

  if (lowerMessage.includes('who') && lowerMessage.includes('tega')) {
    return {
      message: "TEGA is run by experienced professionals in the IT industry. Our team consists of qualified instructors, industry experts, and dedicated support staff who are committed to providing quality education and career guidance.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What qualifications do instructors have?",
        "How do instructors help students?",
        "What support do you provide?",
        "How can I contact your team?"
      ]
    };
  }

  if (lowerMessage.includes('why') && lowerMessage.includes('tega')) {
    return {
      message: "Choose TEGA for quality education, experienced faculty, industry-relevant curriculum, hands-on projects, job placement assistance, flexible timings, and affordable pricing. We focus on practical learning and career development.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "How much do courses cost?",
        "Do you provide job placement?",
        "What makes TEGA different?"
      ]
    };
  }

  if (lowerMessage.includes('how') && lowerMessage.includes('good')) {
    return {
      message: "TEGA is excellent for learning! We have experienced faculty, industry-relevant curriculum, hands-on projects, job placement assistance, and a track record of successful student placements. Our courses are designed to make you industry-ready.",
      followUpOptions: [
        "What courses do you offer?",
        "How do I enroll?",
        "What is the course duration?",
        "How much do courses cost?",
        "What is the success rate?",
        "Do you provide job placement?"
      ]
    };
  }

  // Default intelligent response
  return {
    message: "That's a great question! TEGA offers comprehensive training in programming, data science, web development, and emerging technologies. We provide both online and offline classes with industry-relevant curriculum. How can I help you learn more about our specific courses or services?",
    followUpOptions: [
      "What courses do you offer?",
      "How do I enroll?",
      "What are your office hours?",
      "Where are you located?",
      "What is the course duration?",
      "How much do courses cost?",
      "Do you offer online classes?",
      "Do you provide job placement?"
    ]
  };
};

// POST /api/chatbot/message - Handle chatbot messages
router.post('/message', async (req, res) => {
  try {
    const { message, sessionId } = req.body;
    
    if (!message || typeof message !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Message is required and must be a string'
      });
    }
    
    // Generate AI-powered response
    const aiResponse = await generateAIResponse(message, { sessionId });
    
    // Handle both string and object responses
    const responseData = typeof aiResponse === 'string' 
      ? { message: aiResponse, followUpOptions: [] }
      : aiResponse;
    
    // Return response immediately
    res.json({
      success: true,
      data: {
        message: responseData.message,
        followUpOptions: responseData.followUpOptions || [],
        timestamp: new Date().toISOString(),
        sessionId: sessionId || 'anonymous',
        type: 'ai-generated'
      }
    });
    
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// GET /api/chatbot/status - Check chatbot status
router.get('/status', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'online',
      version: '1.0.0',
      features: ['real-time messaging', 'intelligent responses', 'quick replies'],
      timestamp: new Date().toISOString()
    }
  });
});

// GET /api/chatbot/quick-replies - Get quick reply suggestions
router.get('/quick-replies', (req, res) => {
  const quickReplies = [
    "What courses do you offer?",
    "How do I enroll?",
    "What are your office hours?",
    "Where are you located?",
    "What is the course duration?",
    "How much do courses cost?",
    "Do you offer online classes?",
    "What programming languages do you teach?"
  ];
  
  res.json({
    success: true,
    data: {
      quickReplies: quickReplies,
      timestamp: new Date().toISOString()
    }
  });
});

export default router;
