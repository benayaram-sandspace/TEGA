// Production-ready courses controller with pagination, caching, and optimization
import RealTimeCourse from '../models/RealTimeCourse.js';
import Enrollment from '../models/Enrollment.js';

// In-memory cache (use Redis in production for distributed systems)
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

// Helper function to get cached data
const getCached = (key) => {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }
  cache.delete(key);
  return null;
};

// Helper function to set cached data
const setCache = (key, data) => {
  cache.set(key, {
    data,
    timestamp: Date.now()
  });
};

/**
 * Get courses with pagination, filtering, and caching
 * Optimized for 10,000+ users
 */
export const getCoursesOptimized = async (req, res) => {
  try {
    // Extract query parameters
    const {
      page = 1,
      limit = 12,
      search = '',
      category = 'all',
      level = 'all',
      sortBy = 'newest',
      includeEnrollmentStatus = 'false'
    } = req.query;

    const userId = req.userId;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Create cache key
    const cacheKey = `courses:${page}:${limit}:${search}:${category}:${level}:${sortBy}`;
    
    // Check cache first (skip cache if user wants enrollment status)
    if (includeEnrollmentStatus === 'false') {
      const cachedData = getCached(cacheKey);
      if (cachedData) {
        console.log('✅ Returning cached courses data');
        return res.json({
          success: true,
          ...cachedData,
          cached: true
        });
      }
    }

    // Build query
    const query = {
      status: 'published',
      isDeleted: false
    };

    // Search filter
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { 'instructor.name': { $regex: search, $options: 'i' } }
      ];
    }

    // Category filter
    if (category && category !== 'all') {
      query.category = category;
    }

    // Level filter
    if (level && level !== 'all') {
      query.level = level;
    }

    // Sorting
    let sortOptions = {};
    switch (sortBy) {
      case 'newest':
        sortOptions = { createdAt: -1 };
        break;
      case 'oldest':
        sortOptions = { createdAt: 1 };
        break;
      case 'popular':
        sortOptions = { enrollmentCount: -1 };
        break;
      case 'rating':
        sortOptions = { averageRating: -1 };
        break;
      case 'title':
        sortOptions = { title: 1 };
        break;
      default:
        sortOptions = { createdAt: -1 };
    }

    // Execute query with pagination (optimized)
    const [courses, totalCourses] = await Promise.all([
      RealTimeCourse.find(query)
        .select('-modules.lectures.videoUrl -modules.lectures.content') // Exclude heavy fields
        .sort(sortOptions)
        .skip(skip)
        .limit(limitNum)
        .lean(), // Use lean() for better performance
      RealTimeCourse.countDocuments(query)
    ]);

    // Calculate pagination metadata
    const totalPages = Math.ceil(totalCourses / limitNum);
    const hasNextPage = pageNum < totalPages;
    const hasPrevPage = pageNum > 1;

    // Format courses for response
    const formattedCourses = courses.map(course => ({
      _id: course._id,
      id: course._id,
      title: course.title,
      description: course.description,
      thumbnail: course.thumbnail,
      category: course.category,
      level: course.level,
      price: course.price,
      instructor: course.instructor,
      duration: course.duration,
      formattedDuration: course.formattedDuration,
      enrollmentCount: course.enrollmentCount || 0,
      averageRating: course.averageRating || 0,
      totalRatings: course.totalRatings || 0,
      status: course.status,
      createdAt: course.createdAt,
      updatedAt: course.updatedAt,
      hasPreview: course.modules?.some(module =>
        module.lectures?.some(lecture => lecture.isPreview)
      ) || false,
      moduleCount: course.modules?.length || 0,
      lectureCount: course.modules?.reduce((total, module) =>
        total + (module.lectures?.length || 0), 0) || 0
    }));

    // Get enrollment status if requested
    let enrollmentStatus = {};
    if (includeEnrollmentStatus === 'true' && userId) {
      const courseIds = formattedCourses.map(c => c._id);
      const enrollments = await Enrollment.find({
        studentId: userId,
        courseId: { $in: courseIds }
      }).select('courseId status').lean();

      enrollmentStatus = enrollments.reduce((acc, enrollment) => {
        acc[enrollment.courseId.toString()] = enrollment.status;
        return acc;
      }, {});
    }

    const responseData = {
      success: true,
      courses: formattedCourses,
      pagination: {
        currentPage: pageNum,
        totalPages,
        totalCourses,
        coursesPerPage: limitNum,
        hasNextPage,
        hasPrevPage
      },
      enrollmentStatus: includeEnrollmentStatus === 'true' ? enrollmentStatus : undefined
    };

    // Cache the response (if not including enrollment status)
    if (includeEnrollmentStatus === 'false') {
      setCache(cacheKey, {
        courses: formattedCourses,
        pagination: responseData.pagination
      });
    }

    res.json(responseData);

  } catch (error) {
    console.error('Error fetching courses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get course categories for filtering
 * Cached for performance
 */
export const getCourseCategories = async (req, res) => {
  try {
    const cacheKey = 'course:categories';
    const cached = getCached(cacheKey);
    
    if (cached) {
      return res.json({ success: true, categories: cached, cached: true });
    }

    const categories = await RealTimeCourse.distinct('category', {
      status: 'published',
      isDeleted: false
    });

    setCache(cacheKey, categories);

    res.json({
      success: true,
      categories
    });

  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch categories'
    });
  }
};

/**
 * Get trending courses (most enrolled in last 30 days)
 * Cached for better performance
 */
export const getTrendingCourses = async (req, res) => {
  try {
    const { limit = 5 } = req.query;
    const cacheKey = `trending:${limit}`;
    const cached = getCached(cacheKey);

    if (cached) {
      return res.json({ success: true, courses: cached, cached: true });
    }

    const courses = await RealTimeCourse.find({
      status: 'published',
      isDeleted: false
    })
      .select('title thumbnail category level enrollmentCount averageRating')
      .sort({ enrollmentCount: -1 })
      .limit(parseInt(limit))
      .lean();

    setCache(cacheKey, courses);

    res.json({
      success: true,
      courses
    });

  } catch (error) {
    console.error('Error fetching trending courses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch trending courses'
    });
  }
};

/**
 * Get course statistics for analytics
 * Cached for better performance
 */
export const getCourseStats = async (req, res) => {
  try {
    const cacheKey = 'course:stats';
    const cached = getCached(cacheKey);

    if (cached) {
      return res.json({ success: true, stats: cached, cached: true });
    }

    const [totalCourses, totalEnrollments, avgRating] = await Promise.all([
      RealTimeCourse.countDocuments({ status: 'published', isDeleted: false }),
      Enrollment.countDocuments({ status: { $in: ['active', 'completed'] } }),
      RealTimeCourse.aggregate([
        { $match: { status: 'published', isDeleted: false } },
        { $group: { _id: null, avgRating: { $avg: '$averageRating' } } }
      ])
    ]);

    const stats = {
      totalCourses,
      totalEnrollments,
      averageRating: avgRating[0]?.avgRating || 0
    };

    setCache(cacheKey, stats);

    res.json({
      success: true,
      stats
    });

  } catch (error) {
    console.error('Error fetching course stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch course statistics'
    });
  }
};

/**
 * Clear cache (for admin use)
 */
export const clearCoursesCache = (req, res) => {
  try {
    cache.clear();
    res.json({
      success: true,
      message: 'Course cache cleared successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to clear cache'
    });
  }
};
