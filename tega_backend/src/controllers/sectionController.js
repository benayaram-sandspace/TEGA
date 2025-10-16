import Section from '../models/Section.js';
import Course from '../models/Course.js';
import Lecture from '../models/Lecture.js';

// Create a new section
export const createSection = async (req, res) => {
  try {
    const { courseId, title, description, order } = req.body;
    const adminId = req.adminId;

    // Validate required fields
    if (!courseId || !title) {
      return res.status(400).json({
        success: false,
        message: 'Course ID and title are required'
      });
    }

    // Check if course exists and belongs to admin
    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    if (course.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only add sections to your own courses'
      });
    }

    // Create section
    const section = new Section({
      courseId,
      title,
      description,
      order: order || 0,
      createdBy: adminId
    });

    await section.save();

    res.status(201).json({
      success: true,
      message: 'Section created successfully',
      section
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create section',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get sections by course
export const getSectionsByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;

    const sections = await Section.find({ courseId, isActive: true })
      .sort({ order: 1 })
      .populate('lecturesCount');

    // Get lectures for each section
    const sectionsWithLectures = await Promise.all(
      sections.map(async (section) => {
        const lectures = await Lecture.find({ sectionId: section._id, isActive: true })
          .sort({ order: 1 });
        return {
          ...section.toObject(),
          lectures
        };
      })
    );

    res.json({
      success: true,
      sections: sectionsWithLectures
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch sections',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update section
export const updateSection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const updateData = req.body;
    const adminId = req.adminId;

    // Check if section exists and belongs to admin
    const section = await Section.findById(sectionId);
    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Section not found'
      });
    }

    if (section.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own sections'
      });
    }

    const updatedSection = await Section.findByIdAndUpdate(
      sectionId,
      updateData,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Section updated successfully',
      section: updatedSection
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update section',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete section
export const deleteSection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const adminId = req.adminId;

    // Check if section exists and belongs to admin
    const section = await Section.findById(sectionId);
    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Section not found'
      });
    }

    if (section.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own sections'
      });
    }

    // Soft delete section and its lectures
    await Section.findByIdAndUpdate(sectionId, { isActive: false });
    await Lecture.updateMany({ sectionId }, { isActive: false });

    res.json({
      success: true,
      message: 'Section deleted successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete section',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Reorder sections
export const reorderSections = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { sections } = req.body; // Array of { sectionId, order }
    const adminId = req.adminId;

    // Check if course exists and belongs to admin
    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    if (course.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only reorder sections in your own courses'
      });
    }

    // Update section orders
    const updatePromises = sections.map(({ sectionId, order }) =>
      Section.findByIdAndUpdate(sectionId, { order })
    );

    await Promise.all(updatePromises);

    res.json({
      success: true,
      message: 'Sections reordered successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to reorder sections',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
