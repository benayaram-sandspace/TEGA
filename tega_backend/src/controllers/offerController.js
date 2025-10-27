import Offer from '../models/Offer.js';
import RealTimeCourse from '../models/RealTimeCourse.js'; // Updated to use RealTimeCourse
import Exam from '../models/Exam.js';
import Student from '../models/Student.js';
import mongoose from 'mongoose';

// Get all offers
export const getAllOffers = async (req, res) => {
  try {
    const { page = 1, limit = 10, institute, status } = req.query;
    const query = {};

    // Filter by institute if provided
    if (institute) {
      query.instituteName = { $regex: institute, $options: 'i' };
    }

    // Filter by status
    if (status === 'active') {
      const now = new Date();
      query.isActive = true;
      query.validFrom = { $lte: now };
      query.validUntil = { $gte: now };
    } else if (status === 'expired') {
      const now = new Date();
      query.validUntil = { $lt: now };
    } else if (status === 'inactive') {
      query.isActive = false;
    }

    const offers = await Offer.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Offer.countDocuments(query);

    res.json({
      success: true,
      data: offers,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalOffers: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1
      }
    });
  } catch (error) {
    // console.error('Error fetching offers:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch offers',
      error: error.message
    });
  }
};

// Get single offer by ID
export const getOfferById = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid offer ID'
      });
    }

    const offer = await Offer.findById(id);

    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    res.json({
      success: true,
      data: offer
    });
  } catch (error) {
    // console.error('Error fetching offer:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch offer',
      error: error.message
    });
  }
};

// Create new offer
export const createOffer = async (req, res) => {
  try {
    // console.log('🎯 Creating offer - Request body:', req.body);
    
    const {
      instituteName,
      courseOffers,
      tegaExamOffers,
      validUntil,
      description,
      maxStudents
    } = req.body;

    // Get admin ID from request (adminAuth middleware sets req.adminId and req.admin)
    let createdBy = null;
    if (req.adminId) {
      createdBy = req.adminId;
    } else if (req.admin && req.admin._id) {
      createdBy = req.admin._id;
    } else if (req.user && req.user.id) {
      createdBy = req.user.id;
    } else if (req.user && req.user._id) {
      createdBy = req.user._id;
    }
    
    // console.log('🎯 Created by admin ID:', createdBy);
    // console.log('🎯 Request object keys:', Object.keys(req));
    // console.log('🎯 req.adminId:', req.adminId);
    // console.log('🎯 req.admin:', req.admin);
    // console.log('🎯 req.user:', req.user);

    // Validate required fields
    if (!instituteName || !validUntil) {
      // console.log('❌ Missing required fields:', { instituteName, validUntil });
      return res.status(400).json({
        success: false,
        message: 'Institute name and valid until date are required'
      });
    }

    if (!createdBy) {
      // console.log('❌ No admin ID found in request');
      return res.status(400).json({
        success: false,
        message: 'Admin authentication required'
      });
    }

    // Validate and filter course offers if provided
    let validCourseOffers = [];
    let invalidCourses = [];
    if (courseOffers && courseOffers.length > 0) {
      for (const courseOffer of courseOffers) {
        if (!courseOffer.courseId || !courseOffer.originalPrice || !courseOffer.offerPrice) {
          // console.log('⚠️ Course offer missing required fields - filtering out');
          invalidCourses.push('Course offer with missing required fields');
          continue;
        }

        // Validate course exists (skip validation for default courses)
        // console.log('🔍 Validating course ID:', courseOffer.courseId);
        if (!courseOffer.courseId.startsWith('default-')) {
          const course = await RealTimeCourse.findById(courseOffer.courseId);
          if (!course) {
            // console.log('⚠️ Course not found:', courseOffer.courseId, '- filtering out');
            invalidCourses.push(`Course ID ${courseOffer.courseId} (not found)`);
            continue;
          }
          
          // Check if course is published (RealTimeCourse uses 'status' field)
          if (course.status !== 'published') {
            // console.log('⚠️ Course not published:', course.title, '- filtering out');
            invalidCourses.push(`Course "${course.title}" (not published)`);
            continue;
          }
          
          // console.log('✅ Course found:', course.title);
        } else {
          // console.log('✅ Using default course:', courseOffer.courseId);
        }

        // Validate prices
        if (courseOffer.offerPrice > courseOffer.originalPrice) {
          // console.log('⚠️ Offer price higher than original - filtering out');
          invalidCourses.push('Course offer with invalid pricing');
          continue;
        }
        
        // If we reach here, the course offer is valid
        validCourseOffers.push(courseOffer);
      }
      
      // Log warnings about filtered courses
      if (invalidCourses.length > 0) {
        // console.log(`⚠️ Filtered out ${invalidCourses.length} invalid course offers:`, invalidCourses);
      }
    }

    // Validate and filter TEGA exam offers if provided
    let validTegaExamOffers = [];
    let invalidTegaExams = [];
    if (tegaExamOffers && tegaExamOffers.length > 0) {
      for (const tegaExamOffer of tegaExamOffers) {
        if (!tegaExamOffer.examId || !tegaExamOffer.originalPrice || !tegaExamOffer.offerPrice) {
          // console.log('⚠️ TEGA exam offer missing required fields - filtering out');
          invalidTegaExams.push('TEGA exam offer with missing required fields');
          continue;
        }

        // Validate exam exists
        const exam = await Exam.findById(tegaExamOffer.examId);
        if (!exam) {
          // console.log('⚠️ TEGA exam not found:', tegaExamOffer.examId, '- filtering out');
          invalidTegaExams.push(`TEGA exam ID ${tegaExamOffer.examId} (not found)`);
          continue;
        }

        if (!exam.isTegaExam) {
          // console.log('⚠️ Exam is not a TEGA exam:', exam.title, '- filtering out');
          invalidTegaExams.push(`Exam "${exam.title}" (not a TEGA exam)`);
          continue;
        }
        
        // Check if exam is active
        if (!exam.isActive) {
          // console.log('⚠️ TEGA exam inactive:', exam.title, '- filtering out');
          invalidTegaExams.push(`TEGA exam "${exam.title}" (inactive)`);
          continue;
        }

        // Validate prices
        if (tegaExamOffer.offerPrice > tegaExamOffer.originalPrice) {
          // console.log('⚠️ TEGA exam offer price higher than original - filtering out');
          invalidTegaExams.push('TEGA exam offer with invalid pricing');
          continue;
        }

        // Set exam title if not provided
        if (!tegaExamOffer.examTitle) {
          tegaExamOffer.examTitle = exam.title;
        }

        // Calculate discount percentage
        tegaExamOffer.discountPercentage = Math.round(
          ((tegaExamOffer.originalPrice - tegaExamOffer.offerPrice) / tegaExamOffer.originalPrice) * 100
        );
        
        // If we reach here, the TEGA exam offer is valid
        validTegaExamOffers.push(tegaExamOffer);
      }
      
      // Log warnings about filtered TEGA exams
      if (invalidTegaExams.length > 0) {
        // console.log(`⚠️ Filtered out ${invalidTegaExams.length} invalid TEGA exam offers:`, invalidTegaExams);
      }
    }

    // Create offer
    // console.log('🎯 Creating offer object with data:', {
    //   instituteName,
    //   courseOffers: validCourseOffers,
    //   tegaExamOffers: validTegaExamOffers,
    //   validUntil: new Date(validUntil),
    //   description,
    //   maxStudents,
    //   createdBy
    // });

    const offer = new Offer({
      instituteName,
      courseOffers: validCourseOffers,
      tegaExamOffers: validTegaExamOffers,
      validUntil: new Date(validUntil),
      description,
      maxStudents,
      createdBy
    });

    // console.log('🎯 Offer object created, saving to database...');
    await offer.save();
    // console.log('✅ Offer saved successfully with ID:', offer._id);

    // Note: Since we changed courseId to String and createdBy to String, 
    // population is not needed for these fields
    // console.log('✅ Offer created without population (using String IDs)');

    // Prepare success message
    let successMessage = 'Offer created successfully';
    const filteredItems = [];
    
    if (invalidCourses && invalidCourses.length > 0) {
      filteredItems.push(`${invalidCourses.length} invalid course(s) removed`);
    }
    if (invalidTegaExams && invalidTegaExams.length > 0) {
      filteredItems.push(`${invalidTegaExams.length} invalid TEGA exam(s) removed`);
    }
    
    if (filteredItems.length > 0) {
      successMessage += `. Note: ${filteredItems.join(', ')}.`;
    }

    res.status(201).json({
      success: true,
      message: successMessage,
      data: offer
    });
  } catch (error) {
    // console.error('Error creating offer:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create offer',
      error: error.message
    });
  }
};

// Update offer
export const updateOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid offer ID'
      });
    }

    const offer = await Offer.findById(id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    // Validate and filter course offers if being updated
    let invalidCourses = [];
    if (updateData.courseOffers) {
      const validCourseOffers = [];
      
      for (const courseOffer of updateData.courseOffers) {
        if (courseOffer.courseId) {
          const course = await RealTimeCourse.findById(courseOffer.courseId);
          if (!course) {
            // console.log(`⚠️ Course validation warning: Course with ID ${courseOffer.courseId} not found - filtering out`);
            invalidCourses.push(`Course ID ${courseOffer.courseId} (not found)`);
            continue; // Skip this course offer
          }
          
          // Check if course is published (RealTimeCourse uses 'status' field)
          if (course.status !== 'published') {
            // console.log(`⚠️ Course validation warning: Course ${course.title} is not published - filtering out`);
            invalidCourses.push(`Course "${course.title}" (not published)`);
            continue; // Skip this course offer
          }
        }

        if (courseOffer.originalPrice && courseOffer.offerPrice && 
            courseOffer.offerPrice > courseOffer.originalPrice) {
          // console.log(`⚠️ Course validation warning: Offer price higher than original price - filtering out`);
          invalidCourses.push(`Course offer with invalid pricing`);
          continue; // Skip this course offer
        }
        
        // If we reach here, the course offer is valid
        validCourseOffers.push(courseOffer);
      }
      
      // Update the courseOffers with only valid ones
      updateData.courseOffers = validCourseOffers;
      
      // Log warnings about filtered courses
      if (invalidCourses.length > 0) {
        // console.log(`⚠️ Filtered out ${invalidCourses.length} invalid course offers:`, invalidCourses);
      }
    }

    // Validate and filter TEGA exam offers if being updated
    let invalidTegaExams = [];
    if (updateData.tegaExamOffers) {
      const validTegaExamOffers = [];
      
      for (const tegaExamOffer of updateData.tegaExamOffers) {
        if (tegaExamOffer.examId) {
          const exam = await Exam.findById(tegaExamOffer.examId);
          if (!exam) {
            // console.log(`⚠️ TEGA exam validation warning: Exam with ID ${tegaExamOffer.examId} not found - filtering out`);
            invalidTegaExams.push(`TEGA exam ID ${tegaExamOffer.examId} (not found)`);
            continue; // Skip this exam offer
          }

          if (!exam.isTegaExam) {
            // console.log(`⚠️ TEGA exam validation warning: Exam ${exam.title} is not a TEGA exam - filtering out`);
            invalidTegaExams.push(`Exam "${exam.title}" (not a TEGA exam)`);
            continue; // Skip this exam offer
          }
          
          // Check if exam is active
          if (!exam.isActive) {
            // console.log(`⚠️ TEGA exam validation warning: Exam ${exam.title} is not active - filtering out`);
            invalidTegaExams.push(`TEGA exam "${exam.title}" (inactive)`);
            continue; // Skip this exam offer
          }

          // Set exam title if not provided
          if (!tegaExamOffer.examTitle) {
            tegaExamOffer.examTitle = exam.title;
          }
        }
        
        // If we reach here, the TEGA exam offer is valid
        validTegaExamOffers.push(tegaExamOffer);
      }
      
      // Update the tegaExamOffers with only valid ones
      updateData.tegaExamOffers = validTegaExamOffers;
      
      // Log warnings about filtered TEGA exams
      if (invalidTegaExams.length > 0) {
        // console.log(`⚠️ Filtered out ${invalidTegaExams.length} invalid TEGA exam offers:`, invalidTegaExams);
      }
    }

    // Update offer
    Object.assign(offer, updateData);
    await offer.save();

    // Populate the updated offer
    await offer.populate([
      { path: 'courseOffers.courseId', select: 'courseName price' },
      { path: 'tegaExamOffers.examId', select: 'title price effectivePrice' },
      { path: 'createdBy', select: 'username email' }
    ]);

    // Prepare success message
    let successMessage = 'Offer updated successfully';
    const filteredItems = [];
    
    if (invalidCourses && invalidCourses.length > 0) {
      filteredItems.push(`${invalidCourses.length} invalid course(s) removed`);
    }
    if (invalidTegaExams && invalidTegaExams.length > 0) {
      filteredItems.push(`${invalidTegaExams.length} invalid TEGA exam(s) removed`);
    }
    
    if (filteredItems.length > 0) {
      successMessage += `. Note: ${filteredItems.join(', ')}.`;
    }

    res.json({
      success: true,
      message: successMessage,
      data: offer
    });
  } catch (error) {
    // console.error('Error updating offer:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update offer',
      error: error.message
    });
  }
};

// Delete offer
export const deleteOffer = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid offer ID'
      });
    }

    const offer = await Offer.findById(id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    await Offer.findByIdAndDelete(id);

    res.json({
      success: true,
      message: 'Offer deleted successfully'
    });
  } catch (error) {
    // console.error('Error deleting offer:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete offer',
      error: error.message
    });
  }
};

// Toggle offer status
export const toggleOfferStatus = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid offer ID'
      });
    }

    const offer = await Offer.findById(id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    offer.isActive = !offer.isActive;
    await offer.save();

    res.json({
      success: true,
      message: `Offer ${offer.isActive ? 'activated' : 'deactivated'} successfully`,
      data: offer
    });
  } catch (error) {
    // console.error('Error toggling offer status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle offer status',
      error: error.message
    });
  }
};

// Get offers for specific institute (for students)
export const getOffersForInstitute = async (req, res) => {
  try {
    const { instituteName } = req.params;
    // console.log('🔍 Fetching offers for institute:', instituteName);

    if (!instituteName) {
      return res.status(400).json({
        success: false,
        message: 'Institute name is required'
      });
    }

    // Find active offers for the institute (try exact match first, then fuzzy match)
    const now = new Date();
    
    // Try exact match first
    let offers = await Offer.find({
      instituteName: instituteName,
      isActive: true,
      validFrom: { $lte: now },
      validUntil: { $gte: now }
    });
    
    // If no exact match, try case-insensitive match
    if (!offers || offers.length === 0) {
      // console.log('🔍 No exact match, trying case-insensitive search...');
      offers = await Offer.find({
        instituteName: { $regex: new RegExp(`^${instituteName}$`, 'i') },
        isActive: true,
        validFrom: { $lte: now },
        validUntil: { $gte: now }
      });
    }
    
    // If still no match, try partial match
    if (!offers || offers.length === 0) {
      // console.log('🔍 No case-insensitive match, trying partial search...');
      offers = await Offer.find({
        instituteName: { $regex: instituteName, $options: 'i' },
        isActive: true,
        validFrom: { $lte: now },
        validUntil: { $gte: now }
      });
    }

    // console.log('📊 Found offers for institute:', offers.length);
    // console.log('📊 Offers data:', offers);

    // If no offers found, show all available institute names for debugging
    if (!offers || offers.length === 0) {
      // console.log('🔍 No offers found, checking all available institutes...');
      const allOffers = await Offer.find({ isActive: true });
      const availableInstitutes = [...new Set(allOffers.map(offer => offer.instituteName))];
      // console.log('📊 Available institutes in database:', availableInstitutes);
      
      return res.status(404).json({
        success: false,
        message: 'No active offers found for this institute',
        debug: {
          searchedFor: instituteName,
          availableInstitutes: availableInstitutes
        }
      });
    }

    res.json({
      success: true,
      data: offers
    });
  } catch (error) {
    // console.error('Error fetching offers for institute:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch offers for institute',
      error: error.message
    });
  }
};

// Get course offer for specific institute and course
export const getCourseOfferForInstitute = async (req, res) => {
  try {
    const { instituteName, courseId } = req.params;

    if (!instituteName || !courseId) {
      return res.status(400).json({
        success: false,
        message: 'Institute name and course ID are required'
      });
    }

    if (!mongoose.Types.ObjectId.isValid(courseId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid course ID'
      });
    }

    const offer = await Offer.getCourseOfferForInstitute(instituteName, courseId);

    res.json({
      success: true,
      data: offer
    });
  } catch (error) {
    // console.error('Error fetching course offer:', error);
    res.status(500).json({
          success: false,
      message: 'Failed to fetch course offer',
      error: error.message
    });
  }
};

// Get Tega Exam offer for specific institute
export const getTegaExamOfferForInstitute = async (req, res) => {
  try {
    const { instituteName } = req.params;

    if (!instituteName) {
      return res.status(400).json({
        success: false,
        message: 'Institute name is required'
      });
    }

    const offer = await Offer.getTegaExamOfferForInstitute(instituteName);

    res.json({
      success: true,
      data: offer
    });
  } catch (error) {
    // console.error('Error fetching Tega Exam offer:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch Tega Exam offer',
      error: error.message
    });
  }
};

// Get available courses for offer creation
export const getAvailableCourses = async (req, res) => {
  try {
    // console.log('🔍 Fetching available courses...');
    
    const courses = await RealTimeCourse.find({ status: 'published' })
      .select('_id title price category description')
      .sort({ title: 1 });

    // console.log('📚 Courses found:', courses.length);
    // console.log('📚 Sample course:', courses[0]);

    // Map RealTimeCourse fields to expected format for offer management
    const mappedCourses = courses.map(course => ({
      _id: course._id,
      courseName: course.title, // Map title to courseName for compatibility
      name: course.title, // Also provide as 'name'
      title: course.title,
      price: course.price,
      category: course.category,
      description: course.description
    }));

    // console.log('📚 Mapped courses:', mappedCourses.length);

    // If no courses found, add some default courses
    if (!mappedCourses || mappedCourses.length === 0) {
      // console.log('📚 No courses found, adding default courses');
      const defaultCourses = [
        {
          _id: 'default-java',
          courseName: 'Java Programming',
          name: 'Java Programming',
          title: 'Java Programming',
          price: 799,
          category: 'Programming',
          description: 'Learn Java programming from basics to advanced'
        },
        {
          _id: 'default-python',
          courseName: 'Python for Data Science',
          name: 'Python for Data Science',
          title: 'Python for Data Science',
          price: 799,
          category: 'Data Science',
          description: 'Master Python for data analysis and machine learning'
        },
        {
          _id: 'default-react',
          courseName: 'React.js Development',
          price: 799,
          category: 'Web Development',
          description: 'Build modern web applications with React'
        },
        {
          _id: 'default-aws',
          courseName: 'AWS Cloud Practitioner',
          price: 799,
          category: 'Cloud Computing',
          description: 'Learn AWS cloud services and deployment'
        },
        {
          _id: 'default-tega-exam',
          courseName: 'Tega Main Exam',
          price: 799,
          category: 'Exam',
          description: 'Comprehensive assessment for technical skills'
        }
      ];
      
      res.json({
        success: true,
        data: defaultCourses
      });
      return;
    }

    res.json({
      success: true,
      data: mappedCourses
    });
  } catch (error) {
    // console.error('Error fetching available courses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available courses',
      error: error.message
    });
  }
};

// Get available TEGA exams for offer management
export const getAvailableTegaExams = async (req, res) => {
  try {
    // console.log('🔍 Fetching available TEGA exams for offer management...');
    
    // Get all TEGA exams (isTegaExam: true)
    const tegaExams = await Exam.find({ 
      isTegaExam: true,
      isActive: true 
    }).select('_id title price effectivePrice description duration').sort({ createdAt: -1 });
    
    // console.log('📊 TEGA exams found:', tegaExams.length);
    // console.log('📊 TEGA exams data:', tegaExams.map(exam => ({
    //   id: exam._id,
    //   title: exam.title,
    //   price: exam.price,
    //   effectivePrice: exam.effectivePrice
    // }));

    res.json({
      success: true,
      data: tegaExams
    });
  } catch (error) {
    // console.error('Error fetching available TEGA exams:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available TEGA exams',
      error: error.message
    });
  }
};

// Get institutes list
export const getInstitutes = async (req, res) => {
  try {
    // console.log('🔍 Fetching institutes list...');
    
    // Get unique institute names from students
    const studentInstitutes = await Student.distinct('institute', { 
      institute: { $exists: true, $ne: null, $ne: '' } 
    });
    
    // console.log('📊 Student institutes found:', studentInstitutes);
    
    // If no institutes found in students, use static colleges list as fallback
    let institutes = studentInstitutes;
    
    if (!institutes || institutes.length === 0) {
      // console.log('📚 No institutes found in students, using static colleges list');
      const { colleges } = await import('../data/colleges.js');
      institutes = colleges.slice(0, 50); // Use first 50 colleges for demo
    }
    
    // Sort alphabetically
    institutes.sort();
    
    // console.log('✅ Final institutes list:', institutes.length, 'institutes');

    res.json({
      success: true,
      data: institutes
    });
  } catch (error) {
    // console.error('Error fetching institutes:', error);
    
    // Fallback to static colleges if database fails
    try {
      const { colleges } = await import('../data/colleges.js');
      res.json({
        success: true,
        data: colleges.slice(0, 50).sort()
      });
    } catch (fallbackError) {
    res.status(500).json({
      success: false,
        message: 'Failed to fetch institutes',
        error: error.message
    });
    }
  }
};

// Get offer statistics
export const getOfferStats = async (req, res) => {
  try {
    const now = new Date();
    
    const [
      totalOffers,
      activeOffers,
      expiredOffers,
      totalEnrollments
    ] = await Promise.all([
      Offer.countDocuments(),
      Offer.countDocuments({
        isActive: true,
        validFrom: { $lte: now },
        validUntil: { $gte: now }
      }),
      Offer.countDocuments({
        validUntil: { $lt: now }
      }),
      Offer.aggregate([
      {
        $group: {
          _id: null,
            totalEnrollments: { $sum: '$enrolledStudents' }
          }
        }
      ])
    ]);

    res.json({
      success: true,
      data: {
        totalOffers,
        activeOffers,
        expiredOffers,
        totalEnrollments: totalEnrollments[0]?.totalEnrollments || 0
      }
    });
  } catch (error) {
    // console.error('Error fetching offer statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch offer statistics',
      error: error.message
    });
  }
};
