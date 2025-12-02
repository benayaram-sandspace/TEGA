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
    // Validate required fields
    if (!instituteName || !validUntil) {
      return res.status(400).json({
        success: false,
        message: 'Institute name and valid until date are required'
      });
    }

    if (!createdBy) {
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
          invalidCourses.push('Course offer with missing required fields');
          continue;
        }

        // Validate course exists (skip validation for default courses)
        if (!courseOffer.courseId.startsWith('default-')) {
          const course = await RealTimeCourse.findById(courseOffer.courseId);
          if (!course) {
            invalidCourses.push(`Course ID ${courseOffer.courseId} (not found)`);
            continue;
          }
          
          // Check if course is published (RealTimeCourse uses 'status' field)
          if (course.status !== 'published') {
            invalidCourses.push(`Course "${course.title}" (not published)`);
            continue;
          }
        } else {
        }

        // Validate prices
        if (courseOffer.offerPrice > courseOffer.originalPrice) {
          invalidCourses.push('Course offer with invalid pricing');
          continue;
        }
        
        // If we reach here, the course offer is valid
        validCourseOffers.push(courseOffer);
      }
      
      // Log warnings about filtered courses
      if (invalidCourses.length > 0) {
      }
    }

    // Validate and filter TEGA exam offers if provided
    let validTegaExamOffers = [];
    let invalidTegaExams = [];
    if (tegaExamOffers && tegaExamOffers.length > 0) {
      for (const tegaExamOffer of tegaExamOffers) {
        if (!tegaExamOffer.examId || !tegaExamOffer.originalPrice || !tegaExamOffer.offerPrice) {
          invalidTegaExams.push('TEGA exam offer with missing required fields');
          continue;
        }

        // Validate exam exists
        const exam = await Exam.findById(tegaExamOffer.examId);
        if (!exam) {
          invalidTegaExams.push(`TEGA exam ID ${tegaExamOffer.examId} (not found)`);
          continue;
        }

        if (!exam.isTegaExam) {
          invalidTegaExams.push(`Exam "${exam.title}" (not a TEGA exam)`);
          continue;
        }
        
        // Check if exam is active
        if (!exam.isActive) {
          invalidTegaExams.push(`TEGA exam "${exam.title}" (inactive)`);
          continue;
        }

        // Validate prices
        if (tegaExamOffer.offerPrice > tegaExamOffer.originalPrice) {
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
      }
    }

    // Create offer
    const offer = new Offer({
      instituteName,
      courseOffers: validCourseOffers,
      tegaExamOffers: validTegaExamOffers,
      validUntil: new Date(validUntil),
      description,
      maxStudents,
      createdBy
    });
    await offer.save();
    // Note: Since we changed courseId to String and createdBy to String, 
    // population is not needed for these fields
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
            invalidCourses.push(`Course ID ${courseOffer.courseId} (not found)`);
            continue; // Skip this course offer
          }
          
          // Check if course is published (RealTimeCourse uses 'status' field)
          if (course.status !== 'published') {
            invalidCourses.push(`Course "${course.title}" (not published)`);
            continue; // Skip this course offer
          }
        }

        if (courseOffer.originalPrice && courseOffer.offerPrice && 
            courseOffer.offerPrice > courseOffer.originalPrice) {
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
            invalidTegaExams.push(`TEGA exam ID ${tegaExamOffer.examId} (not found)`);
            continue; // Skip this exam offer
          }

          if (!exam.isTegaExam) {
            invalidTegaExams.push(`Exam "${exam.title}" (not a TEGA exam)`);
            continue; // Skip this exam offer
          }
          
          // Check if exam is active
          if (!exam.isActive) {
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
      offers = await Offer.find({
        instituteName: { $regex: new RegExp(`^${instituteName}$`, 'i') },
        isActive: true,
        validFrom: { $lte: now },
        validUntil: { $gte: now }
      });
    }
    
    // If still no match, try partial match
    if (!offers || offers.length === 0) {
      offers = await Offer.find({
        instituteName: { $regex: instituteName, $options: 'i' },
        isActive: true,
        validFrom: { $lte: now },
        validUntil: { $gte: now }
      });
    }
    // If no offers found, show all available institute names for debugging
    if (!offers || offers.length === 0) {
      const allOffers = await Offer.find({ isActive: true });
      const availableInstitutes = [...new Set(allOffers.map(offer => offer.instituteName))];
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
    const courses = await RealTimeCourse.find({ status: 'published' })
      .select('_id title price category description')
      .sort({ title: 1 });
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
    // If no courses found, add some default courses
    if (!mappedCourses || mappedCourses.length === 0) {
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
    // Get all TEGA exams (isTegaExam: true)
    const tegaExams = await Exam.find({ 
      isTegaExam: true,
      isActive: true 
    }).select('_id title price effectivePrice description duration').sort({ createdAt: -1 });

    res.json({
      success: true,
      data: tegaExams
    });
  } catch (error) {
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
    // Get unique institute names from students
    const studentInstitutes = await Student.distinct('institute', { 
      institute: { $exists: true, $ne: null, $ne: '' } 
    });
    // If no institutes found in students, use static colleges list as fallback
    let institutes = studentInstitutes;
    
    if (!institutes || institutes.length === 0) {
      const { colleges } = await import('../data/colleges.js');
      institutes = colleges.slice(0, 50); // Use first 50 colleges for demo
    }
    
    // Sort alphabetically
    institutes.sort();
    res.json({
      success: true,
      data: institutes
    });
  } catch (error) {
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
    res.status(500).json({
      success: false,
      message: 'Failed to fetch offer statistics',
      error: error.message
    });
  }
};

// ============ PACKAGE OFFERS ============

// Create package offer
export const createPackageOffer = async (req, res) => {
  try {
    const {
      packageName,
      description,
      includedCourses,
      includedExam,
      price,
      validUntil,
      instituteName
    } = req.body;

    // Get admin ID
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

    if (!createdBy) {
      return res.status(400).json({
        success: false,
        message: 'Admin authentication required'
      });
    }

    // Validate required fields
    if (!packageName || !instituteName || !price || !validUntil) {
      return res.status(400).json({
        success: false,
        message: 'Package name, institute name, price, and valid until date are required'
      });
    }

    if (!includedCourses || !Array.isArray(includedCourses) || includedCourses.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one course must be included in the package'
      });
    }

    // Validate courses exist
    const validCourses = [];
    for (const courseData of includedCourses) {
      const courseId = courseData.courseId || courseData;
      const courseName = courseData.courseName || courseData;
      
      if (!courseId.startsWith('default-')) {
        const course = await RealTimeCourse.findById(courseId);
        if (!course) {
          continue; // Skip invalid courses
        }
        if (course.status !== 'published') {
          continue; // Skip unpublished courses
        }
        validCourses.push({
          courseId: courseId.toString(),
          courseName: course.title || courseName
        });
      } else {
        validCourses.push({
          courseId: courseId,
          courseName: courseName || 'Default Course'
        });
      }
    }

    if (validCourses.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid courses found for this package'
      });
    }

    // Validate exam if provided
    let examData = null;
    if (includedExam && includedExam.examId) {
      const exam = await Exam.findById(includedExam.examId);
      if (!exam) {
        return res.status(400).json({
          success: false,
          message: 'TEGA exam not found'
        });
      }
      if (!exam.isTegaExam) {
        return res.status(400).json({
          success: false,
          message: 'Selected exam is not a TEGA exam'
        });
      }
      examData = {
        examId: exam._id,
        examTitle: exam.title
      };
    }

    // Find or create an offer document for this institute
    let offer = await Offer.findOne({ instituteName });
    
    if (!offer) {
      // Create a new offer document with just package offers
      offer = new Offer({
        instituteName,
        courseOffers: [],
        tegaExamOffers: [],
        validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year default
        createdBy,
        description: 'Package offers for ' + instituteName
      });
    }

    // Validate validUntil date
    const validUntilDate = new Date(validUntil);
    if (isNaN(validUntilDate.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid valid until date format'
      });
    }

    if (validUntilDate <= new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Valid until date must be in the future'
      });
    }

    // Add package offer
    const newPackageOffer = {
      packageName,
      description: description || '',
      includedCourses: validCourses,
      includedExam: examData,
      price: Number(price),
      validUntil: validUntilDate,
      instituteName,
      isActive: true
    };

    offer.packageOffers.push(newPackageOffer);
    await offer.save();

    res.status(201).json({
      success: true,
      message: 'Package offer created successfully',
      data: newPackageOffer
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create package offer',
      error: error.message
    });
  }
};

// Get all package offers for an institute (for students)
export const getPackageOffersForInstitute = async (req, res) => {
  try {
    const { instituteName } = req.params;

    if (!instituteName) {
      return res.status(400).json({
        success: false,
        message: 'Institute name is required'
      });
    }

    // Find active offers with package offers for this institute
    const offers = await Offer.find({
      instituteName: { $regex: new RegExp(`^${instituteName}$`, 'i') },
      'packageOffers.isActive': true
    });

    // Extract active package offers
    const packageOffers = [];
    offers.forEach(offer => {
      offer.packageOffers.forEach(pkg => {
        if (pkg.isActive && pkg.instituteName === instituteName) {
          packageOffers.push({
            packageId: pkg._id.toString(),
            packageName: pkg.packageName,
            description: pkg.description,
            includedCourses: pkg.includedCourses,
            includedExam: pkg.includedExam,
            price: pkg.price,
            validUntil: pkg.validUntil,
            instituteName: pkg.instituteName
          });
        }
      });
    });

    res.json({
      success: true,
      data: packageOffers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch package offers',
      error: error.message
    });
  }
};

// Get all package offers (admin)
export const getAllPackageOffers = async (req, res) => {
  try {
    const offers = await Offer.find({
      'packageOffers.0': { $exists: true } // Has at least one package offer
    }).sort({ createdAt: -1 });

    const packageOffers = [];
    offers.forEach(offer => {
      offer.packageOffers.forEach(pkg => {
        packageOffers.push({
          _id: pkg._id.toString(),
          packageId: pkg._id.toString(),
          packageName: pkg.packageName,
          description: pkg.description,
          includedCourses: pkg.includedCourses,
          includedExam: pkg.includedExam,
          price: pkg.price,
          validUntil: pkg.validUntil,
          instituteName: pkg.instituteName,
          isActive: pkg.isActive,
          createdAt: pkg.createdAt,
          parentOfferId: offer._id
        });
      });
    });

    res.json({
      success: true,
      data: packageOffers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch package offers',
      error: error.message
    });
  }
};

// Update package offer
export const updatePackageOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    // Find the offer containing this package
    const offer = await Offer.findOne({ 'packageOffers._id': id });

    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Package offer not found'
      });
    }

    const packageOffer = offer.packageOffers.id(id);
    if (!packageOffer) {
      return res.status(404).json({
        success: false,
        message: 'Package offer not found'
      });
    }

    // Update fields
    if (updateData.packageName) packageOffer.packageName = updateData.packageName;
    if (updateData.description !== undefined) packageOffer.description = updateData.description;
    if (updateData.price) packageOffer.price = Number(updateData.price);
    if (updateData.validUntil) {
      const validUntilDate = new Date(updateData.validUntil);
      if (isNaN(validUntilDate.getTime())) {
        return res.status(400).json({
          success: false,
          message: 'Invalid valid until date format'
        });
      }
      if (validUntilDate <= new Date()) {
        return res.status(400).json({
          success: false,
          message: 'Valid until date must be in the future'
        });
      }
      packageOffer.validUntil = validUntilDate;
    }
    if (updateData.isActive !== undefined) packageOffer.isActive = updateData.isActive;

    // Update courses if provided
    if (updateData.includedCourses && Array.isArray(updateData.includedCourses)) {
      const validCourses = [];
      for (const courseData of updateData.includedCourses) {
        const courseId = courseData.courseId || courseData;
        const courseName = courseData.courseName || courseData;
        
        if (!courseId.startsWith('default-')) {
          const course = await RealTimeCourse.findById(courseId);
          if (course && course.status === 'published') {
            validCourses.push({
              courseId: courseId.toString(),
              courseName: course.title || courseName
            });
          }
        } else {
          validCourses.push({
            courseId: courseId,
            courseName: courseName || 'Default Course'
          });
        }
      }
      if (validCourses.length > 0) {
        packageOffer.includedCourses = validCourses;
      }
    }

    // Update exam if provided
    if (updateData.includedExam !== undefined) {
      if (updateData.includedExam && updateData.includedExam.examId) {
        const exam = await Exam.findById(updateData.includedExam.examId);
        if (exam && exam.isTegaExam) {
          packageOffer.includedExam = {
            examId: exam._id,
            examTitle: exam.title
          };
        }
      } else {
        packageOffer.includedExam = null;
      }
    }

    await offer.save();

    res.json({
      success: true,
      message: 'Package offer updated successfully',
      data: packageOffer
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update package offer',
      error: error.message
    });
  }
};

// Delete package offer
export const deletePackageOffer = async (req, res) => {
  try {
    const { id } = req.params;

    const offer = await Offer.findOne({ 'packageOffers._id': id });

    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Package offer not found'
      });
    }

    offer.packageOffers.id(id).remove();
    await offer.save();

    res.json({
      success: true,
      message: 'Package offer deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete package offer',
      error: error.message
    });
  }
};

// Toggle package offer status
export const togglePackageOfferStatus = async (req, res) => {
  try {
    const { id } = req.params;

    const offer = await Offer.findOne({ 'packageOffers._id': id });

    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Package offer not found'
      });
    }

    const packageOffer = offer.packageOffers.id(id);
    if (!packageOffer) {
      return res.status(404).json({
        success: false,
        message: 'Package offer not found'
      });
    }

    packageOffer.isActive = !packageOffer.isActive;
    await offer.save();

    res.json({
      success: true,
      message: `Package offer ${packageOffer.isActive ? 'activated' : 'deactivated'} successfully`,
      data: packageOffer
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to toggle package offer status',
      error: error.message
    });
  }
};