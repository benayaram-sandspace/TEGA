import { 
  generatePresignedUploadUrl, 
  generatePresignedDownloadUrl,
  uploadToR2,
  generateR2Key,
  deleteFromR2,
  getR2FileMetadata
} from '../config/r2.js';
import multer from 'multer';
import CourseMaterial from '../models/CourseMaterial.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import fs from 'fs';

// Configure multer for temporary storage before R2 upload
const storage = multer.memoryStorage(); // Store in memory for direct R2 upload

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 2 * 1024 * 1024 * 1024, // 2GB limit for videos
  },
  fileFilter: (req, file, cb) => {
    const allowedVideoTypes = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    const allowedDocTypes = ['.pdf', '.ppt', '.pptx', '.doc', '.docx'];
    const ext = file.originalname.toLowerCase().slice(file.originalname.lastIndexOf('.'));
    
    if ([...allowedVideoTypes, ...allowedDocTypes].includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed. Only videos and documents are supported.'), false);
    }
  }
});

/**
 * Generate presigned URL for direct browser upload to R2
 * This is ideal for large files (1GB+) as it allows direct upload from client to R2
 */
export const generateVideoUploadUrl = async (req, res) => {
  try {
    const { fileName, fileSize, contentType } = req.body;
    const adminId = req.adminId;

    if (!fileName || !fileSize || !contentType) {
      return res.status(400).json({
        success: false,
        message: 'File name, size, and content type are required'
      });
    }

    // Validate file size (max 5GB)
    if (fileSize > 5 * 1024 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        message: 'File size exceeds 5GB limit'
      });
    }

    // Generate unique R2 key
    const r2Key = generateR2Key('videos', fileName);

    // Generate presigned URL (valid for 2 hours for large uploads)
    const result = await generatePresignedUploadUrl(r2Key, contentType, 7200);

    res.json({
      success: true,
      message: 'Upload URL generated successfully',
      uploadUrl: result.uploadUrl,
      r2Key: r2Key,
      expiresIn: result.expiresIn
    });

  } catch (error) {
    console.error('Generate Upload URL Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate upload URL',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Generate presigned URL for document upload (PDF/PPT)
 */
export const generateDocumentUploadUrl = async (req, res) => {
  try {
    const { fileName, fileSize, contentType, type } = req.body;
    const adminId = req.adminId;

    if (!fileName || !fileSize || !contentType) {
      return res.status(400).json({
        success: false,
        message: 'File name, size, and content type are required'
      });
    }

    // Validate file size (max 500MB for documents)
    if (fileSize > 500 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        message: 'Document size exceeds 500MB limit'
      });
    }

    // Generate unique R2 key based on type
    const prefix = type === 'pdf' ? 'documents/pdfs' : 'documents/presentations';
    const r2Key = generateR2Key(prefix, fileName);

    // Generate presigned URL (valid for 1 hour)
    const result = await generatePresignedUploadUrl(r2Key, contentType, 3600);

    res.json({
      success: true,
      message: 'Upload URL generated successfully',
      uploadUrl: result.uploadUrl,
      r2Key: r2Key,
      expiresIn: result.expiresIn
    });

  } catch (error) {
    console.error('Generate Document Upload URL Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate upload URL',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Confirm video upload and create lecture record
 */
export const confirmVideoUpload = async (req, res) => {
  try {
    const { 
      r2Key, 
      sectionId, 
      title, 
      description, 
      duration,
      order,
      hasQuizAfterVideo,
      quiz 
    } = req.body;
    const adminId = req.adminId;

    if (!r2Key || !sectionId || !title) {
      return res.status(400).json({
        success: false,
        message: 'R2 key, section ID, and title are required'
      });
    }

    // Verify file exists in R2
    const metadata = await getR2FileMetadata(r2Key);

    // Get public URL
    const r2VideoUrl = process.env.R2_PUBLIC_URL 
      ? `${process.env.R2_PUBLIC_URL}/${r2Key}`
      : `${process.env.R2_ENDPOINT}/${process.env.R2_BUCKET_NAME}/${r2Key}`;

    // Create lecture record
    const lecture = new Lecture({
      sectionId,
      title,
      description,
      type: 'video',
      r2VideoKey: r2Key,
      r2VideoUrl: r2VideoUrl,
      videoUrl: r2VideoUrl, // Backward compatibility
      videoSize: metadata.size,
      duration: duration || '0:00',
      order: order || 0,
      hasQuizAfterVideo: hasQuizAfterVideo || false,
      quiz: hasQuizAfterVideo ? quiz : undefined,
      createdBy: adminId
    });

    await lecture.save();

    res.status(201).json({
      success: true,
      message: 'Video lecture created successfully',
      lecture
    });

  } catch (error) {
    console.error('Confirm Video Upload Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to confirm video upload',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Upload course material (PDF/PPT) to R2
 * For smaller files, direct server upload
 */
export const uploadCourseMaterial = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const { courseId, sectionId, lectureId, title, description, type, order } = req.body;
    const adminId = req.adminId;

    if (!courseId || !title) {
      return res.status(400).json({
        success: false,
        message: 'Course ID and title are required'
      });
    }

    // Generate R2 key
    const prefix = type === 'pdf' ? 'materials/pdfs' : 'materials/presentations';
    const r2Key = generateR2Key(prefix, req.file.originalname);

    // Upload to R2
    const uploadResult = await uploadToR2(
      req.file.buffer,
      r2Key,
      req.file.mimetype,
      {
        title: title,
        uploadedBy: adminId.toString()
      }
    );

    // Create course material record
    const material = new CourseMaterial({
      courseId,
      sectionId,
      lectureId,
      title,
      description,
      type: type || req.file.originalname.split('.').pop().toLowerCase(),
      r2Key: r2Key,
      r2Url: uploadResult.url,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      order: order || 0,
      uploadedBy: adminId
    });

    await material.save();

    // If lectureId provided, link to lecture
    if (lectureId) {
      await Lecture.findByIdAndUpdate(
        lectureId,
        { $push: { materials: material._id } }
      );
    }

    res.status(201).json({
      success: true,
      message: 'Course material uploaded successfully',
      material
    });

  } catch (error) {
    console.error('Upload Course Material Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload course material',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Confirm document upload after presigned URL upload
 */
export const confirmDocumentUpload = async (req, res) => {
  try {
    const { 
      r2Key, 
      courseId, 
      sectionId, 
      lectureId, 
      title, 
      description, 
      type,
      fileName,
      fileSize,
      mimeType,
      order 
    } = req.body;
    const adminId = req.adminId;

    if (!r2Key || !courseId || !title || !fileName) {
      return res.status(400).json({
        success: false,
        message: 'R2 key, course ID, title, and file name are required'
      });
    }

    // Get public URL
    const r2Url = process.env.R2_PUBLIC_URL 
      ? `${process.env.R2_PUBLIC_URL}/${r2Key}`
      : `${process.env.R2_ENDPOINT}/${process.env.R2_BUCKET_NAME}/${r2Key}`;

    // Create course material record
    const material = new CourseMaterial({
      courseId,
      sectionId,
      lectureId,
      title,
      description,
      type: type || fileName.split('.').pop().toLowerCase(),
      r2Key: r2Key,
      r2Url: r2Url,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      order: order || 0,
      uploadedBy: adminId
    });

    await material.save();

    // If lectureId provided, link to lecture
    if (lectureId) {
      await Lecture.findByIdAndUpdate(
        lectureId,
        { $push: { materials: material._id } }
      );
    }

    res.status(201).json({
      success: true,
      message: 'Course material created successfully',
      material
    });

  } catch (error) {
    console.error('Confirm Document Upload Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to confirm document upload',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get course materials by course
 */
export const getMaterialsByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;

    const materials = await CourseMaterial.find({ 
      courseId, 
      isActive: true 
    })
    .sort({ order: 1 })
    .populate('uploadedBy', 'name email');

    res.json({
      success: true,
      materials,
      count: materials.length
    });

  } catch (error) {
    console.error('Get Materials Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch materials',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get course materials by lecture
 */
export const getMaterialsByLecture = async (req, res) => {
  try {
    const { lectureId } = req.params;

    const materials = await CourseMaterial.find({ 
      lectureId, 
      isActive: true 
    })
    .sort({ order: 1 });

    res.json({
      success: true,
      materials,
      count: materials.length
    });

  } catch (error) {
    console.error('Get Lecture Materials Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch lecture materials',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Generate download URL for course material
 */
export const generateMaterialDownloadUrl = async (req, res) => {
  try {
    const { materialId } = req.params;
    const studentId = req.studentId;

    const material = await CourseMaterial.findById(materialId);

    if (!material) {
      return res.status(404).json({
        success: false,
        message: 'Material not found'
      });
    }

    // Generate presigned download URL (valid for 1 hour)
    const result = await generatePresignedDownloadUrl(material.r2Key, 3600);

    // Increment download count
    await material.incrementDownloadCount();

    res.json({
      success: true,
      downloadUrl: result.downloadUrl,
      fileName: material.fileName,
      fileSize: material.fileSize,
      expiresIn: result.expiresIn
    });

  } catch (error) {
    console.error('Generate Download URL Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate download URL',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Delete course material
 */
export const deleteMaterial = async (req, res) => {
  try {
    const { materialId } = req.params;
    const adminId = req.adminId;

    const material = await CourseMaterial.findById(materialId);

    if (!material) {
      return res.status(404).json({
        success: false,
        message: 'Material not found'
      });
    }

    if (material.uploadedBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own materials'
      });
    }

    // Delete from R2
    await deleteFromR2(material.r2Key);

    // Soft delete material
    material.isActive = false;
    await material.save();

    res.json({
      success: true,
      message: 'Material deleted successfully'
    });

  } catch (error) {
    console.error('Delete Material Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete material',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Upload profile picture to R2
 */
export const uploadProfilePicture = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Validate file type (only images)
    const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedImageTypes.includes(req.file.mimetype)) {
      return res.status(400).json({
        success: false,
        message: 'Only image files (JPEG, PNG, GIF, WebP) are allowed'
      });
    }

    // Validate file size (max 5MB for profile pictures)
    if (req.file.size > 5 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        message: 'Profile picture size exceeds 5MB limit'
      });
    }

    // Generate R2 key for profile picture
    const r2Key = generateR2Key('profile-pictures', req.file.originalname);

    // Upload to R2
    const uploadResult = await uploadToR2(
      req.file.buffer,
      r2Key,
      req.file.mimetype,
      {
        studentId: studentId.toString(),
        uploadedAt: new Date().toISOString(),
        type: 'profile-picture'
      }
    );

    // Get public URL
    const profilePictureUrl = process.env.R2_PUBLIC_URL 
      ? `${process.env.R2_PUBLIC_URL}/${r2Key}`
      : uploadResult.url;

    res.json({
      success: true,
      message: 'Profile picture uploaded successfully',
      data: {
        r2Key: r2Key,
        url: profilePictureUrl,
        fileName: req.file.originalname,
        fileSize: req.file.size,
        mimeType: req.file.mimetype
      }
    });

  } catch (error) {
    console.error('Upload Profile Picture Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload profile picture',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Generate presigned URL for profile picture upload
 */
export const generateProfilePictureUploadUrl = async (req, res) => {
  try {
    const { fileName, fileSize, contentType } = req.body;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!fileName || !fileSize || !contentType) {
      return res.status(400).json({
        success: false,
        message: 'File name, size, and content type are required'
      });
    }

    // Validate file type (only images)
    const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedImageTypes.includes(contentType)) {
      return res.status(400).json({
        success: false,
        message: 'Only image files (JPEG, PNG, GIF, WebP) are allowed'
      });
    }

    // Validate file size (max 5MB for profile pictures)
    if (fileSize > 5 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        message: 'Profile picture size exceeds 5MB limit'
      });
    }

    // Generate unique R2 key
    const r2Key = generateR2Key('profile-pictures', fileName);

    // Generate presigned URL (valid for 1 hour)
    const result = await generatePresignedUploadUrl(r2Key, contentType, 3600);

    res.json({
      success: true,
      message: 'Upload URL generated successfully',
      uploadUrl: result.uploadUrl,
      r2Key: r2Key,
      expiresIn: result.expiresIn
    });

  } catch (error) {
    console.error('Generate Profile Picture Upload URL Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate upload URL',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

export { upload };

