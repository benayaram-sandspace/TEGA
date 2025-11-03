import Resume from '../models/Resume.js';
import Student from '../models/Student.js';
import Template from '../models/Template.js';
import { buildResumePdf } from '../utils/resumeGenerator.js';
import cloudinary, { cloudinaryAvailable } from '../config/cloudinary.js';

const getResume = async (req, res) => {
  try {
    // Try to find existing resume, but don't require it
    let resume = await Resume.findOne({ student: req.user?.id });
    
    if (!resume) {
      // Return a clean default resume structure
      return res.json({
        personalInfo: {
          fullName: '',
          email: '',
          phone: '',
          location: '',
          linkedin: '',
          summary: '',
          title: ''
        },
        experience: [],
        education: [],
        projects: [],
        skills: [],
        certifications: [],
        achievements: [],
        extraCurricularActivities: [],
        languages: [],
        volunteerExperience: [],
        hobbies: []
      });
    }
    
    res.json(resume);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

const saveResume = async (req, res) => {
  try {
    
    const resumeData = req.body;
    const studentId = req.user?.id || req.studentId;

    if (!studentId) {
      return res.status(401).json({ 
        success: false,
        message: 'Authentication required - no student ID found' 
      });
    }

    // If we have a user ID, save with it, otherwise save without
    const query = { student: studentId };
    
    // Update or create resume
    const options = { 
      upsert: true,
      new: true,
      setDefaultsOnInsert: true
    };

    // Clean the data to match schema
    const cleanedData = {
      ...resumeData,
      student: studentId,
      // Ensure arrays are properly formatted with id fields
      experience: (resumeData.experience || []).map((item, index) => ({
        id: item.id || index + 1,
        company: item.company || '',
        position: item.position || '',
        startDate: item.startDate || '',
        endDate: item.endDate || '',
        current: item.current || false,
        description: item.description || ''
      })),
      education: (resumeData.education || []).map((item, index) => ({
        id: item.id || index + 1,
        institution: item.institution || '',
        degree: item.degree || '',
        field: item.field || '',
        startDate: item.startDate || '',
        endDate: item.endDate || '',
        current: item.current || false,
        gpa: item.gpa || ''
      })),
      projects: (resumeData.projects || []).map((item, index) => ({
        id: item.id || index + 1,
        name: item.name || '',
        description: item.description || '',
        technologies: item.technologies || '',
        link: item.link || ''
      })),
      skills: (resumeData.skills || []).map((item, index) => ({
        id: item.id || index + 1,
        name: item.name || ''
      })),
      certifications: (resumeData.certifications || []).map((item, index) => ({
        id: item.id || index + 1,
        name: item.name || '',
        issuer: item.issuer || '',
        date: item.date || '',
        link: item.link || ''
      })),
      achievements: (resumeData.achievements || []).map((item, index) => ({
        id: item.id || index + 1,
        title: item.title || '',
        description: item.description || ''
      })),
      extracurricularActivities: (resumeData.extracurricularActivities || []).map((item, index) => ({
        id: item.id || index + 1,
        organization: item.organization || '',
        role: item.role || '',
        description: item.description || ''
      })),
      languages: (resumeData.languages || []).map((item, index) => ({
        id: item.id || index + 1,
        name: item.name || '',
        proficiency: item.proficiency || ''
      })),
      volunteerExperience: (resumeData.volunteerExperience || []).map((item, index) => ({
        id: item.id || index + 1,
        organization: item.organization || '',
        role: item.role || '',
        description: item.description || ''
      })),
      hobbies: (resumeData.hobbies || []).map((item, index) => ({
        id: item.id || index + 1,
        name: item.name || ''
      })),
      sections: resumeData.sections || [],
      // Ensure personalInfo has all required fields
      personalInfo: {
        fullName: resumeData.personalInfo?.fullName || '',
        email: resumeData.personalInfo?.email || '',
        phone: resumeData.personalInfo?.phone || '',
        location: resumeData.personalInfo?.location || '',
        linkedin: resumeData.personalInfo?.linkedin || '',
        summary: resumeData.personalInfo?.summary || '',
        title: resumeData.personalInfo?.title || ''
      }
    };

    const updatedResume = await Resume.findOneAndUpdate(
      query,
      cleanedData,
      options
    );

    res.status(200).json({ 
      success: true,
      message: 'Resume saved successfully', 
      resume: updatedResume 
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'Error saving resume',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

const getTemplates = async (req, res) => {
  try {
    // Get all templates without checking student enrollment
    const allTemplates = await Template.find({}).lean();

    // Process templates for the client
    const templates = allTemplates.map(template => {
      // Ensure template has a URL-friendly name (lowercase, no spaces)
      const templateName = template.name?.toLowerCase().replace(/\s+/g, '-') || 'default';
      
      return {
        ...template,
        id: template._id, // Keep original ID for reference
        name: templateName, // URL-friendly name
        isLocked: false, // All templates are unlocked
        // Ensure we have all required fields with defaults
        isPremium: template.isPremium || false,
        thumbnail: template.thumbnail || '',
        description: template.description || ''
      };
    });

    res.json(templates);
  } catch (error) {
    res.status(500).json({ 
      message: 'Error fetching templates',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

const downloadResume = async (req, res) => {
  try {
    const { templateName } = req.params;
    const resumeData = req.body;

    // Validate required data
    if (!resumeData) {
      return res.status(400).json({ 
        success: false,
        message: 'Resume data is required' 
      });
    }

    // Default to classic template if none specified
    const templateToUse = templateName || 'classic';
    
    try {
      // Generate PDF with the specified template
      const pdfBuffer = await buildResumePdf(resumeData, templateToUse, false);
      
      // Set response headers for file download
      const filename = `${resumeData.personalInfo?.fullName?.replace(/[^\w\s.-]/gi, '').replace(/\s+/g, '_') || 'resume'}.pdf`;
      
      res.set({
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Content-Length': pdfBuffer.length,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      });
      
      return res.send(pdfBuffer);
      
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: 'Error generating PDF',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  } catch (error) {
    const statusCode = error.statusCode || 500;
    const message = error.message || 'Server error while generating resume';
    return res.status(statusCode).json({ 
      success: false,
      message: message || 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

const uploadResume = async (req, res) => {
  try {
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const studentId = req.user?.id;
    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Check if Cloudinary is available and configured
    if (!cloudinaryAvailable || !cloudinary || !process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      return handleLocalStorageUpload(req, res, studentId);
    }

    // Upload file to Cloudinary for production
    const uploadResult = await new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          resource_type: 'raw',
          folder: 'resumes',
          public_id: `resume-${studentId}-${Date.now()}`,
          format: req.file.mimetype === 'application/pdf' ? 'pdf' : 'doc'
        },
        (error, result) => {
          if (error) {
            reject(error);
          } else {
            resolve(result);
          }
        }
      );

      uploadStream.end(req.file.buffer);
    });

    // Create or update the resume record with Cloudinary file information
    const resumeData = {
      student: studentId,
      uploadedResume: {
        cloudinaryId: uploadResult.public_id,
        url: uploadResult.secure_url,
        originalName: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype,
        uploadedAt: new Date()
      }
    };

    // Update or create resume record
    const options = { 
      upsert: true,
      new: true,
      setDefaultsOnInsert: true
    };

    const updatedResume = await Resume.findOneAndUpdate(
      { student: studentId },
      resumeData,
      options
    );

    res.status(200).json({
      success: true,
      message: 'Resume uploaded successfully',
      data: {
        url: uploadResult.secure_url,
        originalName: req.file.originalname,
        size: req.file.size,
        uploadedAt: resumeData.uploadedResume.uploadedAt
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error uploading resume',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Fallback function for local storage when Cloudinary is not configured
const handleLocalStorageUpload = async (req, res, studentId) => {
  try {
    
    // Create uploads/resumes directory if it doesn't exist
    const fs = await import('fs');
    const path = await import('path');
    
    const uploadsDir = path.join(process.cwd(), 'uploads', 'resumes');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // Generate unique filename
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const filename = `resume-${studentId}-${uniqueSuffix}${path.extname(req.file.originalname)}`;
    const filepath = path.join(uploadsDir, filename);

    // Save file to local storage
    fs.writeFileSync(filepath, req.file.buffer);

    // Create or update the resume record with local file information
    const resumeData = {
      student: studentId,
      uploadedResume: {
        filename: filename,
        path: filepath,
        originalName: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype,
        uploadedAt: new Date()
      }
    };

    // Update or create resume record
    const options = { 
      upsert: true,
      new: true,
      setDefaultsOnInsert: true
    };

    const updatedResume = await Resume.findOneAndUpdate(
      { student: studentId },
      resumeData,
      options
    );

    res.status(200).json({
      success: true,
      message: 'Resume uploaded successfully',
      data: {
        filename: filename,
        originalName: req.file.originalname,
        size: req.file.size,
        uploadedAt: resumeData.uploadedResume.uploadedAt
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error uploading resume',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export {
  getResume,
  saveResume,
  getTemplates,
  downloadResume,
  uploadResume
};
