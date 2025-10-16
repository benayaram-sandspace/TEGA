import Course from '../models/Course.js';
import Section from '../models/Section.js';
import Lecture from '../models/Lecture.js';
import Admin from '../models/Admin.js';
import multer from 'multer';
import xlsx from 'xlsx';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['.xlsx', '.xls', '.pdf'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowedTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only Excel (.xlsx, .xls) and PDF files are allowed'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Helper function to validate video URL
const isValidVideoUrl = (url) => {
  if (!url || typeof url !== 'string') return false;
  
  
  // Check for valid video file extensions
  const videoExtensions = ['.mp4', '.webm', '.ogg', '.avi', '.mov', '.wmv', '.flv', '.mkv', '.m4v', '.3gp'];
  const hasVideoExtension = videoExtensions.some(ext => url.toLowerCase().includes(ext));
  
  // Check for valid video platforms
  const validVideoPlatforms = [
    'youtube.com', 'youtu.be', 'vimeo.com', 'dailymotion.com', 
    'twitch.tv', 'facebook.com', 'instagram.com', 'tiktok.com',
    'commondatastorage.googleapis.com', 'storage.googleapis.com',
    'drive.google.com', 'dropbox.com', 'onedrive.live.com',
    // Bunny Stream URLs - including mediadelivery.net CDN
    'bunnycdn.com', 'b-cdn.net', 'bunny.net', 
    'stream.bunnycdn.com', 'iframe.bunnycdn.com',
    'dash.bunny.net', 'stream.bunny.net',
    'iframe.bunny.net', 'embed.bunny.net',
    'mediadelivery.net', 'iframe.mediadelivery.net' // Bunny Stream CDN
  ];
  const hasValidPlatform = validVideoPlatforms.some(platform => {
    const contains = url.includes(platform);
    if (contains) console.log('Found valid platform:', platform);
    return contains;
  });
  
  // Exclude invalid URLs
  const invalidPatterns = [
    'flic.kr', 
    'search.yahoo.com', 
    'google.com/search',
    'youtube.com/results',
    'youtube.com/search',
    'youtube.com/channel',
    'youtube.com/user',
    'youtube.com/c/'
  ];
  const hasInvalidPattern = invalidPatterns.some(pattern => {
    const contains = url.includes(pattern);
    if (contains) console.log('Found invalid pattern:', pattern);
    return contains;
  });
  
  const result = (hasVideoExtension || hasValidPlatform) && !hasInvalidPattern;
  
  return result;
};

// Single course upload (updated for new structure)
export const uploadSingleCourse = async (req, res) => {
  try {
    const { title, description, category, language, price, thumbnail, difficulty, duration, features, requirements, outcomes, instructor, professorName, videoLink, modules, image } = req.body;
    const adminId = req.adminId;
    

    // Validation
    if (!title || !description) {
      return res.status(400).json({ 
        success: false, 
        message: 'Title and description are required' 
      });
    }

    // Validate video URL if provided
    if (videoLink && !isValidVideoUrl(videoLink)) {
      
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid video URL. Please provide a valid video link from supported platforms (YouTube, Vimeo, Bunny Stream including dash.bunny.net and mediadelivery.net, etc.) or a direct video file URL. Note: YouTube search results URLs are not valid video links.' 
      });
    }

    // Create course with schema-aligned structure
    const normalizedLevel = (difficulty || 'beginner').toLowerCase();
    const levelMap = { beginner: 'Beginner', intermediate: 'Intermediate', advanced: 'Advanced' };

    const resolvedInstructor = professorName || 
      (typeof instructor === 'string' ? instructor : (instructor && instructor.name)) || 
      'Instructor';

    // Process modules if provided
    let processedModules = [];
    
    if (modules && Array.isArray(modules) && modules.length > 0) {
      processedModules = modules.map((module, index) => {
        return {
          title: module.title || `Module ${index + 1}`,
          description: module.description || '',
          order: module.order || index,
          videos: Array.isArray(module.videos) ? module.videos.map((video, videoIndex) => ({
            title: video.title || `Lesson ${videoIndex + 1}`,
            videoLink: video.videoLink || video.videoUrl || '',
            duration: video.duration || '0:00',
            isPreview: video.isPreview || false,
            order: video.order || videoIndex
          })) : []
        };
      });
    } else {
    }

    const course = new Course({
      courseName: title, // map title -> courseName
      description,
      category: category || 'programming',
      price: price || 0,
      duration: duration || '4 weeks',
      instructor: resolvedInstructor, // must be a string in schema
      level: levelMap[normalizedLevel] || 'Beginner',
      thumbnail: thumbnail || undefined,
      image: image || undefined,
      videoUrl: videoLink || undefined,
      requirements: Array.isArray(requirements) ? requirements : [],
      outcomes: Array.isArray(outcomes) ? outcomes : [],
      syllabus: [], // schema expects syllabus; we can map modules later
      modules: processedModules, // Save modules to the course
      isActive: true
    });


    await course.save();

    res.status(201).json({
      success: true,
      message: 'Course uploaded successfully',
      course: {
        id: course._id,
        courseName: course.courseName,
        description: course.description,
        category: course.category,
        price: course.price,
        level: course.level,
        duration: course.duration,
        instructor: course.instructor,
        modules: course.modules,
        modulesCount: course.modules.length
      }
    });

  } catch (error) {
    
    res.status(500).json({ 
      success: false, 
      message: 'Failed to upload course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Bulk course upload
export const uploadBulkCourses = async (req, res) => {
  try {
    
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please upload a file' 
      });
    }
    

    const adminId = req.adminId;
    const filePath = req.file.path;
    const fileExt = path.extname(req.file.originalname).toLowerCase();
    
    // Validate file type
    if (fileExt !== '.xlsx' && fileExt !== '.xls') {
      return res.status(400).json({
        success: false,
        message: 'Only Excel files (.xlsx, .xls) are supported'
      });
    }
    
    let courses = [];

    // Parse Excel file
    const workbook = xlsx.readFile(filePath);
    
    const sheetName = workbook.SheetNames[0];
    
    const worksheet = workbook.Sheets[sheetName];
    
    courses = xlsx.utils.sheet_to_json(worksheet);
    
    // Show first few rows for debugging
    if (courses && courses.length > 0) {
    } else {
    }
    
    // If no courses found, try different parsing options
    if (!courses || courses.length === 0) {
      
      // Try with header row
      courses = xlsx.utils.sheet_to_json(worksheet, { header: 1 });
      
      if (courses && courses.length > 0) {
        // Convert array format to object format
        const headers = courses[0];
        
        const convertedCourses = [];
        for (let i = 1; i < courses.length; i++) {
          const row = courses[i];
          if (row && row.length > 0) {
            const courseObj = {};
            headers.forEach((header, index) => {
              if (header && row[index] !== undefined) {
                courseObj[header] = row[index];
              }
            });
            if (Object.keys(courseObj).length > 0) {
              convertedCourses.push(courseObj);
            }
          }
        }
        courses = convertedCourses;
      }
    }

    if (!courses || courses.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'No courses found in the uploaded file. The file might be empty or have no data rows.',
        details: {
          fileProcessed: true,
          coursesFound: 0,
          possibleIssues: [
            'Excel file is completely empty',
            'Excel file has no data rows (only headers)',
            'Data is in a different sheet than the first one',
            'File format is corrupted or not supported'
          ]
        }
      });
    }

    // Validate and process courses
    const validCourses = [];
    const errors = [];

    for (let i = 0; i < courses.length; i++) {
      const courseData = courses[i];
      
      // Extract course details from Excel columns
      const title = courseData['Course Title'] || courseData['Title'] || courseData['courseTitle'] || courseData['title'];
      const professorName = courseData['Professor Name'] || courseData['Professor'] || courseData['professorName'] || courseData['instructor'];
      const duration = courseData['Course Duration'] || courseData['Duration'] || courseData['duration'] || '4 weeks';
      const numberOfModules = parseInt(courseData['Number of Modules'] || courseData['Modules'] || courseData['modules'] || '1');
      const videoLinksString = courseData['Video Links/URLs'] || courseData['Video Links'] || courseData['Video URLs'] || courseData['videoLinks'] || courseData['videoUrls'];
      
      
      // Check required fields
      if (!title || !professorName || !videoLinksString) {
        const missingFields = [];
        if (!title) missingFields.push('Course Title');
        if (!professorName) missingFields.push('Professor Name');
        if (!videoLinksString) missingFields.push('Video Links/URLs');
        
        const errorMsg = `Row ${i + 1}: Missing required fields (${missingFields.join(', ')})`;
        errors.push(errorMsg);
        continue;
      }
      

      // Generate unique course ID
      const courseId = title.toLowerCase().replace(/[^a-z0-9]/g, '-') + '-' + Date.now() + '-' + i;

      // Parse video links
      const videoUrls = videoLinksString.split(',').map(url => url.trim()).filter(url => url);
      
      // Validate video URLs
      const validVideoUrls = [];
      const invalidUrls = [];
      
      videoUrls.forEach((url, index) => {
        if (isValidVideoUrl(url)) {
          validVideoUrls.push(url);
        } else {
          invalidUrls.push(url);
        }
      });
      
      if (invalidUrls.length > 0) {
        errors.push(`Course "${title}": Invalid video URLs - ${invalidUrls.join(', ')}`);
      }
      
      if (validVideoUrls.length === 0) {
        errors.push(`Course "${title}": No valid video URLs found`);
        continue;
      }
      
      // Create modules and distribute videos
      const modules = [];
      const videosPerModule = Math.ceil(validVideoUrls.length / numberOfModules);
      
      for (let moduleIndex = 0; moduleIndex < numberOfModules; moduleIndex++) {
        const startIndex = moduleIndex * videosPerModule;
        const endIndex = Math.min(startIndex + videosPerModule, validVideoUrls.length);
        const moduleVideos = validVideoUrls.slice(startIndex, endIndex);
        
        const moduleVideosArray = moduleVideos.map((videoUrl, videoIndex) => ({
          id: `video-${moduleIndex + 1}-${videoIndex + 1}`,
          title: `Lesson ${videoIndex + 1}`,
          videoLink: videoUrl,
          duration: '0:00',
          isPreview: videoIndex === 0, // First video in each module is preview
          order: videoIndex
        }));
        
        modules.push({
          id: `module-${moduleIndex + 1}`,
          title: `Module ${moduleIndex + 1}`,
          description: `Module ${moduleIndex + 1} content`,
          order: moduleIndex,
          videos: moduleVideosArray
        });
      }
      

      validCourses.push({
        courseId,
        title,
        name: title,
        professorName,
        description: `${title} - A comprehensive course taught by ${professorName}`,
        category: courseData['Category'] || 'programming',
        difficulty: courseData['Difficulty'] || 'beginner',
        price: courseData['Price'] || 799,
        duration: duration,
        modules: modules,
        isActive: true,
        createdBy: adminId,
        instructor: {
          name: professorName
        }
      });
    }


    if (validCourses.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'No valid courses found in the uploaded file. Please check that your Excel file has the correct format with headers in the first row.',
        details: {
          fileProcessed: true,
          totalRowsProcessed: courses.length,
          validCoursesFound: validCourses.length,
          errorsFound: errors.length,
          possibleIssues: [
            'Excel file is empty or has no data rows',
            'Column headers do not match expected format',
            'Required fields are missing',
            'Invalid video URLs provided',
            'Data is in a different sheet than the first one'
          ],
          expectedColumns: [
            'Course Title (required)',
            'Professor Name (required)', 
            'Course Duration (required)',
            'Number of Modules (required)',
            'Video Links/URLs (required)',
            'Category (optional)',
            'Difficulty (optional)',
            'Price (optional)'
          ]
        },
        errors: errors
      });
    }

    // Insert courses into database
    const insertedCourses = await Course.insertMany(validCourses);

    // Clean up uploaded file
    fs.unlinkSync(filePath);

    res.status(201).json({
      success: true,
      message: `${insertedCourses.length} courses uploaded successfully`,
      courses: insertedCourses.map(course => ({
        id: course._id,
        courseId: course.courseId,
        title: course.title,
        professorName: course.professorName,
        description: course.description,
        modules: course.modules,
        category: course.category,
        difficulty: course.difficulty,
        price: course.price,
        duration: course.duration
      })),
      errors: errors.length > 0 ? errors : undefined
    });

  } catch (error) {
    
    // Clean up uploaded file if it exists
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }

    res.status(500).json({ 
      success: false, 
      message: 'Failed to upload courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      details: process.env.NODE_ENV === 'development' ? {
        name: error.name,
        code: error.code,
        keyValue: error.keyValue
      } : undefined
    });
  }
};

// Get all courses for users
export const getAllCourses = async (req, res) => {
  try {
    // User-facing courses - exclude Tega Exam
    const courses = await Course.find({ 
      isActive: true,
      courseName: { $ne: 'Tega Exam' } // Exclude Tega Exam from user courses
    })
      .select('_id courseName description category level price duration instructor thumbnail image videoUrl enrolledStudents maxStudents')
      .sort({ createdAt: -1 });

    const isValidUrlLocal = (url) => {
      if (!url || typeof url !== 'string') return false;
      try { new URL(url); return true; } catch { return false; }
    };

    const coursesWithVideoInfo = courses.map((course) => {
      const courseObj = course.toObject();
      const hasValidMainVideo = isValidUrlLocal(courseObj.videoUrl);
      const hasValidVideosArray = Array.isArray(courseObj.videos) && courseObj.videos.some(v => isValidUrlLocal(v.videoLink));
        return {
        ...courseObj,
        title: courseObj.courseName, // keep backward compatibility for UI using title
        hasVideoContent: hasValidMainVideo || hasValidVideosArray
        };
    });

    res.json({
      success: true,
      courses: coursesWithVideoInfo
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get all courses for admin (including Tega Exam)
export const getAllCoursesForAdmin = async (req, res) => {
  try {
    // Admin should see all courses including Tega Exam for exam creation
    const courses = await Course.find({ 
      isActive: true
    })
      .select('_id courseName description category level price duration instructor thumbnail image videoUrl enrolledStudents maxStudents')
      .sort({ createdAt: -1 });

    const isValidUrlLocal = (url) => {
      if (!url || typeof url !== 'string') return false;
      try { new URL(url); return true; } catch { return false; }
    };

    const coursesWithVideoInfo = courses.map((course) => {
      const courseObj = course.toObject();
      const hasValidMainVideo = isValidUrlLocal(courseObj.videoUrl);
      const hasValidVideosArray = Array.isArray(courseObj.videos) && courseObj.videos.some(v => isValidUrlLocal(v.videoLink));
        return {
        ...courseObj,
        title: courseObj.courseName, // keep backward compatibility for UI using title
        hasVideoContent: hasValidMainVideo || hasValidVideosArray
        };
    });

    res.json({
      success: true,
      courses: coursesWithVideoInfo
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get courses for admin
export const getAdminCourses = async (req, res) => {
  try {
    
    const courses = await Course.find()
      .select('_id courseName description category level price duration instructor isActive enrolledStudents maxStudents syllabus requirements outcomes thumbnail videoUrl modules')
      .sort({ createdAt: -1 });

    // Ensure all courses have isActive field set to true if not explicitly set
    const coursesWithDefaults = courses.map(course => ({
      ...course.toObject(),
      isActive: course.isActive !== undefined ? course.isActive : true
    }));

    res.json({
      success: true,
      courses: coursesWithDefaults
    });

  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update course
export const updateCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const updateData = req.body;


    // Handle field mapping from frontend to backend
    if (updateData.title && !updateData.courseName) {
      updateData.courseName = updateData.title;
    }
    
    if (updateData.professorName) {
      updateData.instructor = updateData.professorName;
      // Keep professorName for backward compatibility
    }
    
    // Map videoLink to videoUrl field
    if (updateData.videoLink) {
      updateData.videoUrl = updateData.videoLink;
    }

    // Ensure required fields have default values
    if (!updateData.price) {
      updateData.price = 799; // Default price
    }
    
    if (!updateData.duration) {
      updateData.duration = '4 weeks'; // Default duration
    }
    
    if (!updateData.category) {
      updateData.category = 'programming'; // Default category
    }
    
    if (!updateData.isActive) {
      updateData.isActive = true; // Default to active
    }

    // Validate required fields
    if (!updateData.courseName && !updateData.title) {
      return res.status(400).json({
        success: false,
        message: 'Course name is required'
      });
    }
    
    if (!updateData.description) {
      return res.status(400).json({
        success: false,
        message: 'Description is required'
      });
    }

    // Validate category if provided
    if (updateData.category && !['programming', 'ai', 'web', 'cloud', 'cyber', 'office', 'comprehensive', 'data-science', 'mobile', 'devops'].includes(updateData.category)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid category'
      });
    }

    // Validate difficulty if provided
    if (updateData.difficulty && !['beginner', 'intermediate', 'advanced'].includes(updateData.difficulty.toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid difficulty level'
      });
    }

    // Map difficulty to level field
    if (updateData.difficulty) {
      updateData.level = updateData.difficulty.charAt(0).toUpperCase() + updateData.difficulty.slice(1).toLowerCase();
    }
    
    // Clean up modules and videos to fix Mongoose CastError
    if (updateData.modules && Array.isArray(updateData.modules)) {
      updateData.modules = updateData.modules.map(module => {
        const cleanModule = { ...module };
        
        // Remove any id field that might cause ObjectId casting issues
        delete cleanModule.id;
        delete cleanModule._id;
        
        // Clean up videos array
        if (cleanModule.videos && Array.isArray(cleanModule.videos)) {
          cleanModule.videos = cleanModule.videos.map(video => {
            const cleanVideo = { ...video };
            
            // Remove any id field that might cause ObjectId casting issues
            delete cleanVideo.id;
            delete cleanVideo._id;
            
            // Ensure required fields are present
            if (!cleanVideo.title) cleanVideo.title = 'Untitled Video';
            if (!cleanVideo.videoLink) cleanVideo.videoLink = '';
            if (!cleanVideo.duration) cleanVideo.duration = '0:00';
            if (cleanVideo.isPreview === undefined) cleanVideo.isPreview = false;
            if (cleanVideo.order === undefined) cleanVideo.order = 0;
            
            return cleanVideo;
          });
        }
        
        // Ensure required module fields
        if (!cleanModule.title) cleanModule.title = 'Untitled Module';
        if (!cleanModule.description) cleanModule.description = '';
        if (cleanModule.order === undefined) cleanModule.order = 0;
        
        return cleanModule;
      });
    }

    if (updateData.modules) {
    }

    // Try to find course by courseId first, then by _id
    let course = await Course.findOneAndUpdate(
      { courseId: courseId },
      updateData,
      { new: true, runValidators: false } // Disable validators temporarily to avoid issues
    );

    // If not found by courseId, try by _id
    if (!course) {
      course = await Course.findByIdAndUpdate(
        courseId,
        updateData,
        { new: true, runValidators: false } // Disable validators temporarily to avoid issues
      );
    }
    

    if (!course) {
      return res.status(404).json({ 
        success: false, 
        message: 'Course not found' 
      });
    }


    res.json({
      success: true,
      message: 'Course updated successfully',
      course: course
    });

  } catch (error) {
    
    res.status(500).json({ 
      success: false, 
      message: 'Failed to update course',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Delete course
export const deleteCourse = async (req, res) => {
  try {
    const { courseId } = req.params;

    // Try to find course by courseId first, then by _id
    let course = await Course.findOneAndDelete({ courseId: courseId });

    // If not found by courseId, try by _id
    if (!course) {
      course = await Course.findByIdAndDelete(courseId);
    }

    if (!course) {
      return res.status(404).json({ 
        success: false, 
        message: 'Course not found' 
      });
    }

    res.json({
      success: true,
      message: 'Course deleted successfully'
    });

  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to delete course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Helper function to parse PDF courses
const parsePDFCourses = (pdfText) => {
  // This is a basic parser - you might need to enhance it based on your PDF format
  const lines = pdfText.split('\n');
  const courses = [];
  let currentCourse = {};

  for (const line of lines) {
    const trimmedLine = line.trim();
    
    if (trimmedLine.includes('Course Title:') || trimmedLine.includes('Title:')) {
      if (Object.keys(currentCourse).length > 0) {
        courses.push(currentCourse);
      }
      currentCourse = { 'Course Title': trimmedLine.split(':')[1]?.trim() };
    } else if (trimmedLine.includes('Video Link:') || trimmedLine.includes('URL:')) {
      currentCourse['Course Video Link/URL'] = trimmedLine.split(':')[1]?.trim();
    } else if (trimmedLine.includes('Professor:') || trimmedLine.includes('Instructor:')) {
      currentCourse['Professor Name'] = trimmedLine.split(':')[1]?.trim();
    } else if (trimmedLine.includes('Description:') || trimmedLine.includes('Details:')) {
      currentCourse['Course Details/Description'] = trimmedLine.split(':')[1]?.trim();
    }
  }

  if (Object.keys(currentCourse).length > 0) {
    courses.push(currentCourse);
  }

  return courses;
};

// Get single course with sections and lectures (playlist style)
export const getCourseWithContent = async (req, res) => {
  try {
    const { courseId } = req.params;

    // Try to find by courseId (string) first, then by _id (ObjectId)
    let course = await Course.findOne({ courseId: courseId });
    if (!course) {
      course = await Course.findById(courseId);
    }
    if (!course) {
      // Backward compatibility: try by title
      course = await Course.findOne({ title: courseId });
    }

    if (!course) {
      return res.status(404).json({ success: false, message: 'Course not found' });
    }

    const c = course.toObject();


    // Build sections/lectures structure from modules if they exist
    let sections = [];
    
    if (c.modules && Array.isArray(c.modules) && c.modules.length > 0) {
      // Use modules structure
      sections = c.modules.map((module, moduleIndex) => {
        
        const lectures = module.videos ? module.videos.map((video, videoIndex) => {
          
          return {
            _id: video._id || `${c._id}-video-${moduleIndex}-${videoIndex}`,
            title: video.title,
            videoUrl: video.videoLink,
            duration: video.duration || '0:00',
            isPreview: video.isPreview || false,
            order: video.order || videoIndex
          };
        }) : [];
        
        return {
          _id: module._id || `${c._id}-module-${moduleIndex}`,
          title: module.title,
          description: module.description,
          order: module.order || moduleIndex,
          lectures
        };
      });
    } else {
      // Fallback to old structure
    const mainVideoLecture = c.videoUrl
      ? [{
          _id: `${c._id}-main`,
          title: c.courseName || c.title || 'Introduction',
          videoUrl: c.videoUrl,
          duration: c.duration || '0:00',
          isPreview: true
        }]
      : [];

    // Optionally map syllabus to sections without videos
    const syllabusSections = Array.isArray(c.syllabus)
      ? c.syllabus.map((s, idx) => ({
          _id: `${c._id}-syllabus-${idx}`,
          title: s.title || `Week ${s.week || idx + 1}`,
          lectures: []
        }))
      : [];

    if (mainVideoLecture.length > 0) {
      sections.push({ _id: `${c._id}-section-main`, title: 'Main', lectures: mainVideoLecture });
    }
    sections.push(...syllabusSections);
    }

    const courseWithContent = {
      ...c,
      title: c.courseName || c.title, // ensure player header shows a title
      sections
    };
    

    res.json({ success: true, course: courseWithContent });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch course content',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Add video to existing course
export const addVideoToCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { videoUrl, videoTitle, duration } = req.body;

    if (!videoUrl) {
      return res.status(400).json({
        success: false,
        message: 'Video URL is required'
      });
    }

    // Find the course
    let course = await Course.findOne({ courseId: courseId });
    if (!course) {
      course = await Course.findById(courseId);
    }
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Update the course with video
    const updatedCourse = await Course.findByIdAndUpdate(
      course._id,
      {
        $set: {
          videoLink: videoUrl,
          videos: [{
            id: `video-${Date.now()}`,
            title: videoTitle || 'Course Introduction',
            videoLink: videoUrl,
            duration: duration || '10:00',
            isPreview: true,
            order: 0
          }]
        }
      },
      { new: true }
    );

    res.json({
      success: true,
      message: 'Video added to course successfully',
      course: updatedCourse
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to add video to course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Create course (updated for new structure)
export const createCourse = async (req, res) => {
  try {
    const { title, description, category, language, price, thumbnail, difficulty, duration, features, requirements, outcomes, instructor, videoLink } = req.body;
    const adminId = req.adminId;

    // Validation
    if (!title || !description) {
      return res.status(400).json({
        success: false,
        message: 'Title and description are required'
      });
    }

    // Validate video URL if provided
    if (videoLink && !isValidVideoUrl(videoLink)) {
      
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid video URL. Please provide a valid video link from supported platforms (YouTube, Vimeo, Bunny Stream including dash.bunny.net and mediadelivery.net, etc.) or a direct video file URL. Note: YouTube search results URLs are not valid video links.' 
      });
    }

    // Create course
    const course = new Course({
      title,
      description,
      category: category || 'programming',
      language: language || 'English',
      price: price || 0,
      thumbnail,
      difficulty: difficulty || 'beginner',
      duration: duration || '4 weeks',
      features,
      requirements,
      outcomes,
      instructor,
      videoLink, // Add videoLink to course creation
      isActive: true, // Explicitly set to true
      createdBy: adminId
    });

    await course.save();

    res.status(201).json({
      success: true,
      message: 'Course created successfully',
      course
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Bulk import courses with sections and lectures
export const bulkImportCourses = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please upload a file'
      });
    }

    const adminId = req.adminId;
    const filePath = req.file.path;
    const fileExt = path.extname(req.file.originalname).toLowerCase();

    let coursesData = [];

    if (fileExt === '.xlsx' || fileExt === '.xls') {
      // Parse Excel file
      const workbook = xlsx.readFile(filePath);
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      coursesData = xlsx.utils.sheet_to_json(worksheet);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Only Excel files are supported for bulk import'
      });
    }

    if (!coursesData || coursesData.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No courses found in the uploaded file'
      });
    }

    const results = {
      coursesCreated: 0,
      sectionsCreated: 0,
      lecturesCreated: 0,
      errors: []
    };

    // Process each course
    for (let i = 0; i < coursesData.length; i++) {
      const courseData = coursesData[i];
      
      try {
        // Create course
        const course = new Course({
          title: courseData['Course Title'] || courseData['title'] || `Course ${i + 1}`,
          description: courseData['Description'] || courseData['description'] || 'No description provided',
          category: courseData['Category'] || courseData['category'] || 'programming',
          language: courseData['Language'] || courseData['language'] || 'English',
          price: courseData['Price'] || courseData['price'] || 0,
          difficulty: courseData['Difficulty'] || courseData['difficulty'] || 'beginner',
          duration: courseData['Duration'] || courseData['duration'] || '4 weeks',
          createdBy: adminId
        });

        await course.save();
        results.coursesCreated++;

        // Create sections if provided
        if (courseData['Sections']) {
          const sectionsData = typeof courseData['Sections'] === 'string' 
            ? JSON.parse(courseData['Sections']) 
            : courseData['Sections'];

          if (Array.isArray(sectionsData)) {
            for (let j = 0; j < sectionsData.length; j++) {
              const sectionData = sectionsData[j];
              
              const section = new Section({
                courseId: course._id,
                title: sectionData.title || `Section ${j + 1}`,
                description: sectionData.description,
                order: j,
                createdBy: adminId
              });

              await section.save();
              results.sectionsCreated++;

              // Create lectures if provided
              if (sectionData.lectures && Array.isArray(sectionData.lectures)) {
                for (let k = 0; k < sectionData.lectures.length; k++) {
                  const lectureData = sectionData.lectures[k];
                  
                  const lecture = new Lecture({
                    sectionId: section._id,
                    title: lectureData.title || `Lecture ${k + 1}`,
                    description: lectureData.description,
                    type: lectureData.type || 'video',
                    videoUrl: lectureData.videoUrl,
                    fileUrl: lectureData.fileUrl,
                    duration: lectureData.duration || '0:00',
                    order: k,
                    isPreview: lectureData.isPreview || false,
                    createdBy: adminId
                  });

                  await lecture.save();
                  results.lecturesCreated++;
                }
              }
            }
          }
        }

      } catch (error) {
        results.errors.push(`Row ${i + 1}: ${error.message}`);
      }
    }

    // Clean up uploaded file
    fs.unlinkSync(filePath);

    res.status(201).json({
      success: true,
      message: 'Bulk import completed',
      results
    });

  } catch (error) {
    
    // Clean up uploaded file if it exists
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }

    res.status(500).json({
      success: false,
      message: 'Failed to import courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Diagnostic endpoint to check Excel file content
export const diagnoseExcelFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please upload a file' 
      });
    }

    const filePath = req.file.path;
    const fileExt = path.extname(req.file.originalname).toLowerCase();
    

    if (fileExt !== '.xlsx' && fileExt !== '.xls') {
      return res.status(400).json({
        success: false,
        message: 'Only Excel files (.xlsx, .xls) are supported for diagnosis'
      });
    }

    // Read Excel file
    const workbook = xlsx.readFile(filePath);
    
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    
    // Get raw data
    const rawData = xlsx.utils.sheet_to_json(worksheet, { header: 1 });
    
    // Get parsed data
    const parsedData = xlsx.utils.sheet_to_json(worksheet);
    
    // Clean up file
    fs.unlinkSync(filePath);
    
    res.json({
      success: true,
      diagnosis: {
        fileName: req.file.originalname,
        fileSize: req.file.size,
        fileExtension: fileExt,
        sheetNames: workbook.SheetNames,
        activeSheet: sheetName,
        totalRows: rawData.length,
        hasHeaders: rawData.length > 0,
        headers: rawData.length > 0 ? rawData[0] : [],
        sampleData: rawData.slice(0, 3),
        parsedSample: parsedData.slice(0, 2),
        columnCount: rawData.length > 0 ? rawData[0].length : 0
      }
    });

  } catch (error) {
    
    // Clean up file if it exists
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to diagnose Excel file',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Test endpoint to create a simple course
export const testCreateCourse = async (req, res) => {
  try {
    
    const testCourse = {
      courseId: 'test-course-' + Date.now(),
      title: 'Test Course from API',
      professorName: 'Test Professor',
      description: 'This is a test course created via API',
      category: 'programming',
      difficulty: 'beginner',
      price: 799,
      duration: '4 weeks',
      modules: [{
        id: 'module-1',
        title: 'Test Module',
        description: 'Test module description',
        order: 0,
        videos: [{
          id: 'video-1-1',
          title: 'Test Video',
          videoLink: 'https://www.youtube.com/watch?v=test123',
          duration: '10:00',
          isPreview: true,
          order: 0
        }]
      }],
      isActive: true,
      instructor: {
        name: 'Test Professor'
      },
      createdBy: req.adminId // Add the required createdBy field
    };

    const course = new Course(testCourse);
    await course.save();
    


    res.json({
      success: true,
      message: 'Test course created successfully',
      course: {
        id: course._id,
        title: course.title,
        professorName: course.professorName
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create test course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Export multer upload middleware
export { upload };
