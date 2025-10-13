import Course from '../models/Course.js';
import Section from '../models/Section.js';
import Lecture from '../models/Lecture.js';
import Enrollment from '../models/Enrollment.js';

// Create new course with sections and lessons
export const createCourseWithContent = async (req, res) => {
  try {
    const {
      title,
      description,
      category,
      language,
      price,
      isFree,
      allowPreview,
      thumbnail,
      difficulty,
      duration,
      features,
      requirements,
      outcomes,
      instructor,
      sections
    } = req.body;

    const adminId = req.adminId;

    // Create course
    const course = new Course({
      title,
      description,
      category,
      language,
      price: isFree ? 0 : price,
      isFree: isFree || price === 0,
      allowPreview,
      thumbnail,
      difficulty,
      duration,
      features: features || [],
      requirements: requirements || [],
      outcomes: outcomes || [],
      instructor: instructor || {},
      createdBy: adminId
    });

    await course.save();

    // Create sections and lectures
    if (sections && sections.length > 0) {
      for (const sectionData of sections) {
        const section = new Section({
          title: sectionData.title,
          description: sectionData.description,
          order: sectionData.order,
          courseId: course._id,
          createdBy: adminId
        });

        await section.save();

        // Create lectures for this section
        if (sectionData.lectures && sectionData.lectures.length > 0) {
          for (const lectureData of sectionData.lectures) {
            const lecture = new Lecture({
              title: lectureData.title,
              description: lectureData.description,
              type: lectureData.type || 'video',
              videoUrl: lectureData.videoUrl,
              fileUrl: lectureData.fileUrl,
              duration: lectureData.duration,
              order: lectureData.order,
              isPreview: lectureData.isPreview || false,
              sectionId: section._id,
              createdBy: adminId
            });

            await lecture.save();
          }
        }
      }
    }

    // Get the complete course with sections and lectures
    const completeCourse = await Course.getCourseWithContent(course._id);

    res.status(201).json({
      success: true,
      message: 'Course created successfully',
      course: completeCourse
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Add section to existing course
export const addSectionToCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { title, description, order } = req.body;
    const adminId = req.adminId;

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    const section = new Section({
      title,
      description,
      order: order || 0,
      courseId,
      createdBy: adminId
    });

    await section.save();

    res.status(201).json({
      success: true,
      message: 'Section added successfully',
      section
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to add section',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Add lesson to existing section
export const addLessonToSection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const {
      title,
      description,
      type,
      videoUrl,
      fileUrl,
      duration,
      order,
      isPreview
    } = req.body;
    const adminId = req.adminId;

    const section = await Section.findById(sectionId);
    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Section not found'
      });
    }

    const lecture = new Lecture({
      title,
      description,
      type: type || 'video',
      videoUrl,
      fileUrl,
      duration: duration || '0:00',
      order: order || 0,
      isPreview: isPreview || false,
      sectionId,
      createdBy: adminId
    });

    await lecture.save();

    res.status(201).json({
      success: true,
      message: 'Lesson added successfully',
      lecture
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to add lesson',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update course
export const updateCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const updateData = req.body;

    // Remove fields that shouldn't be updated directly
    delete updateData._id;
    delete updateData.createdBy;
    delete updateData.createdAt;
    delete updateData.updatedAt;

    const course = await Course.findByIdAndUpdate(
      courseId,
      updateData,
      { new: true, runValidators: true }
    );

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    res.json({
      success: true,
      message: 'Course updated successfully',
      course
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete course
export const deleteCourse = async (req, res) => {
  try {
    const { courseId } = req.params;

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Delete all related data
    await Promise.all([
      // Delete lectures
      Lecture.deleteMany({ sectionId: { $in: await Section.find({ courseId }).distinct('_id') } }),
      // Delete sections
      Section.deleteMany({ courseId }),
      // Delete enrollments
      Enrollment.deleteMany({ courseId }),
      // Delete course
      Course.findByIdAndDelete(courseId)
    ]);

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

// Update lesson
export const updateLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;
    const updateData = req.body;

    // Remove fields that shouldn't be updated directly
    delete updateData._id;
    delete updateData.sectionId;
    delete updateData.createdBy;
    delete updateData.createdAt;
    delete updateData.updatedAt;

    const lecture = await Lecture.findByIdAndUpdate(
      lessonId,
      updateData,
      { new: true, runValidators: true }
    );

    if (!lecture) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    res.json({
      success: true,
      message: 'Lesson updated successfully',
      lecture
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update lesson',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete lesson
export const deleteLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;

    const lecture = await Lecture.findByIdAndDelete(lessonId);
    if (!lecture) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    res.json({
      success: true,
      message: 'Lesson deleted successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete lesson',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get course analytics
export const getCourseAnalytics = async (req, res) => {
  try {
    const { courseId } = req.params;

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Get enrollment statistics
    const enrollmentStats = await Enrollment.aggregate([
      { $match: { courseId: course._id } },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    // Get total enrollments
    const totalEnrollments = await Enrollment.countDocuments({ courseId: course._id });

    // Get sections and lectures count
    const sections = await Section.find({ courseId: course._id });
    const totalLectures = await Lecture.countDocuments({
      sectionId: { $in: sections.map(s => s._id) }
    });

    res.json({
      success: true,
      analytics: {
        course: {
          title: course.title,
          price: course.price,
          isFree: course.isFree,
          createdAt: course.createdAt
        },
        enrollments: {
          total: totalEnrollments,
          byStatus: enrollmentStats
        },
        content: {
          sections: sections.length,
          lectures: totalLectures
        }
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get course analytics',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
