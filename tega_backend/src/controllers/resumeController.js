import Resume from '../models/Resume.js';
import Student from '../models/Student.js';
import Template from '../models/Template.js';
import { buildResumePdf } from '../utils/resumeGenerator.js';
import cloudinary, { cloudinaryAvailable } from '../config/cloudinary.js';
import { uploadToR2, generateR2Key } from '../config/r2.js';

const buildR2PublicUrl = (key) => {
  if (process.env.R2_PUBLIC_URL) {
    return `${process.env.R2_PUBLIC_URL}/${key}`;
  }
  if (process.env.R2_ENDPOINT && process.env.R2_BUCKET_NAME) {
    const endpoint = process.env.R2_ENDPOINT.replace(/\/$/, '');
    return `${endpoint}/${process.env.R2_BUCKET_NAME}/${key}`;
  }
  if (process.env.R2_ACCOUNT_ID) {
    return `https://pub-${process.env.R2_ACCOUNT_ID}.r2.dev/${key}`;
  }
  return null;
};

const getResume = async (req, res) => {
  try {
    // Prevent caching so the client always receives the latest data
    res.set({
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    });
    const studentId = req.user?.id || req.studentId || req.student?._id;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Try to find existing resume, but don't require it
    let resume = await Resume.findOne({ student: studentId });
    
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
    const studentId = req.user?.id || req.studentId || req.student?._id;

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

    // Prevent caching of the save response
    res.set({
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    });
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

// Download the student's last uploaded resume file
const downloadUploadedResume = async (req, res) => {
  try {
    const studentId = req.user?.id || req.studentId || req.student?._id;
    if (!studentId) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }

    // Find resume with uploaded file info
    const resumeDoc = await Resume.findOne({ student: studentId }).lean();
    const uploaded = resumeDoc?.uploadedResume;
    if (!uploaded || !(uploaded.url || uploaded.publicUrl)) {
      return res.status(404).json({ success: false, message: 'No uploaded resume found' });
    }

    const sourceUrl = uploaded.url || uploaded.publicUrl;
    const filename = (uploaded.originalName && String(uploaded.originalName).trim()) || 'resume.pdf';

    // Prevent caching
    res.set({
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    });

    // If we have an internal proxy route (e.g. /api/r2/resume/:key), fetch from R2 directly
    if (sourceUrl.includes('/api/r2/resume/')) {
      try {
        // Extract the R2 key from the URL
        const urlMatch = sourceUrl.match(/\/api\/r2\/resume\/([^?]+)/);
        if (!urlMatch || !urlMatch[1]) {
          return res.status(400).json({ success: false, message: 'Invalid resume URL format' });
        }
        
        const r2Key = decodeURIComponent(urlMatch[1]);
        
        // Import R2 config
        const { getR2Client, getR2BucketName } = await import('../config/r2.js');
        const r2Client = getR2Client();
        const R2_BUCKET_NAME = getR2BucketName();
        
        if (!r2Client || !R2_BUCKET_NAME) {
          return res.status(503).json({ success: false, message: 'R2 storage is not configured' });
        }
        
        const { GetObjectCommand } = await import('@aws-sdk/client-s3');
        
        // Try different possible key paths
        const possibleKeys = [
          r2Key,
          `resumes/${r2Key}`,
          `uploads/resumes/${r2Key}`
        ];
        
        let objectResponse = null;
        for (const key of possibleKeys) {
          try {
            const command = new GetObjectCommand({
              Bucket: R2_BUCKET_NAME,
              Key: key
            });
            objectResponse = await r2Client.send(command);
            break; // Success, exit loop
          } catch (keyError) {
            if (keyError.Code === 'NoSuchKey' || keyError.name === 'NoSuchKey') {
              continue; // Try next key
            }
            throw keyError; // Re-throw if it's a different error
          }
        }
        
        if (!objectResponse) {
          return res.status(404).json({ success: false, message: 'Resume file not found in storage' });
        }
        
        // Set headers for download
        const contentType = objectResponse.ContentType || uploaded.mimetype || 'application/octet-stream';
        res.setHeader('Content-Type', contentType);
        res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(filename)}"`);
        if (objectResponse.ContentLength) {
          res.setHeader('Content-Length', objectResponse.ContentLength);
        }
        
        // Stream the file
        objectResponse.Body.pipe(res);
        return;
      } catch (r2Error) {
        return res.status(500).json({ 
          success: false, 
          message: 'Error fetching resume from R2 storage', 
          error: process.env.NODE_ENV === 'development' ? r2Error.message : undefined 
        });
      }
    }

    // Otherwise stream the file to the client from external URL
    try {
      const fileResponse = await fetch(sourceUrl);
      if (!fileResponse.ok) {
        return res.status(502).json({ success: false, message: 'Failed to fetch resume from storage' });
      }

      // Pass through content-type and disposition
      const contentType = fileResponse.headers.get('content-type') || uploaded.mimetype || 'application/octet-stream';
      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

      // Stream the body
      fileResponse.body.pipe(res);
    } catch (err) {
      return res.status(500).json({ success: false, message: 'Error streaming resume', error: process.env.NODE_ENV === 'development' ? err.message : undefined });
    }
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Server error while downloading resume' });
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

    const studentId = req.user?.id || req.studentId || req.student?._id;
    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Check if Cloudinary is available and configured
    if (!cloudinaryAvailable || !cloudinary || !process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      return handleR2Upload(req, res, studentId);
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

    // Ensure clients don't cache this response
    res.set({
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    });
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

// Fallback function using Cloudflare R2 when Cloudinary is not configured
const handleR2Upload = async (req, res, studentId) => {
  try {
    const contentType = req.file.mimetype || 'application/octet-stream';
    const r2Key = generateR2Key('resumes', req.file.originalname || `resume-${studentId}.pdf`);

    const uploadResult = await uploadToR2(req.file.buffer, r2Key, contentType, {
      studentId: String(studentId),
      originalName: req.file.originalname || 'resume'
    });

    const publicUrl = uploadResult.url || buildR2PublicUrl(r2Key);
    const serverUrl = process.env.SERVER_URL || process.env.API_URL ||
      (process.env.NODE_ENV === 'development'
        ? `http://localhost:${process.env.PORT || 5001}`
        : process.env.CLIENT_URL || 'http://localhost:5001');
    const proxyUrl = `${serverUrl}/api/r2/resume/${encodeURIComponent(r2Key)}`;

    const resumeData = {
      student: studentId,
      uploadedResume: {
        r2Key,
        url: proxyUrl,
        publicUrl,
        originalName: req.file.originalname,
        size: req.file.size,
        mimetype: contentType,
        uploadedAt: new Date()
      }
    };

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

    // Ensure clients don't cache this response
    res.set({
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    });
    res.status(200).json({
      success: true,
      message: 'Resume uploaded successfully',
      data: {
        url: resumeData.uploadedResume.url,
        r2Key: resumeData.uploadedResume.r2Key,
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
  uploadResume,
  downloadUploadedResume
};
