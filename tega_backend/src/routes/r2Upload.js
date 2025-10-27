import express from 'express';
import { 
  generateVideoUploadUrl,
  generateDocumentUploadUrl,
  confirmVideoUpload,
  uploadCourseMaterial,
  confirmDocumentUpload,
  getMaterialsByCourse,
  getMaterialsByLecture,
  generateMaterialDownloadUrl,
  deleteMaterial,
  uploadProfilePicture,
  generateProfilePictureUploadUrl,
  upload
} from '../controllers/r2UploadController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Admin routes - Video uploads
router.post('/generate-video-upload-url', adminAuth, generateVideoUploadUrl);
router.post('/confirm-video-upload', adminAuth, confirmVideoUpload);

// Admin routes - Document uploads
router.post('/generate-document-upload-url', adminAuth, generateDocumentUploadUrl);
router.post('/confirm-document-upload', adminAuth, confirmDocumentUpload);
router.post('/upload-material', adminAuth, upload.single('file'), uploadCourseMaterial);

// Admin routes - Material management
router.delete('/material/:materialId', adminAuth, deleteMaterial);

// Student/Admin routes - Material access
router.get('/materials/course/:courseId', getMaterialsByCourse);
router.get('/materials/lecture/:lectureId', getMaterialsByLecture);
router.get('/material/:materialId/download', generateMaterialDownloadUrl);

// Student routes - Profile picture upload
router.post('/profile-picture/upload', studentAuth, upload.single('profilePicture'), uploadProfilePicture);
router.post('/profile-picture/generate-upload-url', studentAuth, generateProfilePictureUploadUrl);

// Test route to verify R2 connection
router.get('/test-r2', async (req, res) => {
  try {
    // console.log('🔍 Testing R2 connection...');
    const { generatePresignedDownloadUrl } = await import('../config/r2.js');
    
    // Test with a dummy key to see if R2 service is working
    const testKey = 'profile-pictures/test-image.jpg';
    const result = await generatePresignedDownloadUrl(testKey, 3600);
    
    res.json({
      success: true,
      message: 'R2 service is working',
      testUrl: result.downloadUrl,
      r2Key: testKey
    });
  } catch (error) {
    // console.error('R2 test error:', error);
    res.status(500).json({
      success: false,
      message: 'R2 service error',
      error: error.message
    });
  }
});

// Fix route to update profile picture with correct R2 key
router.post('/fix-profile-picture', async (req, res) => {
  try {
    const { studentId, correctR2Key } = req.body;
    
    if (!studentId || !correctR2Key) {
      return res.status(400).json({ 
        success: false, 
        message: 'Student ID and correct R2 key are required' 
      });
    }
    
    // console.log('🔍 Fixing profile picture for student:', studentId, 'with key:', correctR2Key);
    
    // Find the student
    const Student = (await import('../models/Student.js')).default;
    let student = null;
    
    if (/^[0-9a-fA-F]{24}$/.test(studentId)) {
      student = await Student.findById(studentId);
    }
    
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }
    
    // Update the profile picture with the correct R2 key
    const publicUrl = `${process.env.SERVER_URL || 'http://localhost:5001'}/api/r2/profile-picture/${correctR2Key}`;
    
    student.profilePicture = {
      url: publicUrl,
      r2Key: correctR2Key,
      fileName: 'profile-picture',
      fileSize: 4093, // From the R2 listing
      mimeType: 'image/jpeg',
      uploadedAt: new Date()
    };
    
    student.profilePhoto = publicUrl; // Legacy field
    
    await student.save();
    
    // console.log('🔍 Profile picture fixed successfully');
    
    res.json({
      success: true,
      message: 'Profile picture fixed successfully',
      profilePicture: student.profilePicture
    });
    
  } catch (error) {
    // console.error('🔍 Fix profile picture error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Fix failed', 
      error: error.message 
    });
  }
});

// Debug route to list all files in R2 bucket
router.get('/list-all-files', async (req, res) => {
  try {
    // console.log('🔍 Listing all files in R2 bucket...');
    const { r2Client, R2_BUCKET_NAME } = await import('../config/r2.js');
    const { ListObjectsV2Command } = await import('@aws-sdk/client-s3');
    
    const command = new ListObjectsV2Command({ 
      Bucket: R2_BUCKET_NAME, 
      MaxKeys: 1000 // Get more files
    });
    const response = await r2Client.send(command);
    
    const allFiles = response.Contents?.map(obj => ({
      key: obj.Key,
      size: obj.Size,
      lastModified: obj.LastModified
    })) || [];
    
    // Filter for profile pictures
    const profilePictures = allFiles.filter(file => 
      file.key.includes('profile') || 
      file.key.includes('photo') || 
      file.key.includes('avatar') ||
      file.key.includes('1760423649751') || // Your specific file
      file.key.includes('68d27254a697da05f493b9aa') // Your user ID
    );
    
    // console.log('🔍 All files in bucket:', allFiles.length);
    // console.log('🔍 Profile pictures found:', profilePictures);
    
    res.json({ 
      success: true, 
      message: 'R2 bucket listing successful',
      bucketName: R2_BUCKET_NAME,
      totalFiles: allFiles.length,
      allFiles: allFiles,
      profilePictures: profilePictures
    });
  } catch (error) {
    // console.error('🔍 R2 bucket listing failed:', error);
    res.status(500).json({ 
      success: false, 
      message: 'R2 bucket listing failed',
      error: error.message 
    });
  }
});

// Proxy route to serve R2 images (CORS workaround)
router.get('/profile-picture/:r2Key', async (req, res) => {
  try {
    const { r2Key } = req.params;
    // console.log('🔍 Proxy route called for R2 key:', r2Key);
    
    // Set CORS headers first
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, HEAD');
    res.header('Access-Control-Allow-Headers', '*');
    
    // Try to get the file from R2 and stream it
    const { r2Client, R2_BUCKET_NAME } = await import('../config/r2.js');
    const { GetObjectCommand } = await import('@aws-sdk/client-s3');
    
    const command = new GetObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: r2Key
    });
    
    const response = await r2Client.send(command);
    
    // Set appropriate headers
    res.set({
      'Content-Type': response.ContentType || 'image/jpeg',
      'Content-Length': response.ContentLength,
      'Cache-Control': 'public, max-age=3600'
    });
    
    // Stream the file
    response.Body.pipe(res);
    
  } catch (error) {
    // console.error('Error serving profile picture:', error);
    
    // Set CORS headers even for errors
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, HEAD');
    res.header('Access-Control-Allow-Headers', '*');
    
    // If the key doesn't exist, try to find it with different paths
    if (error.Code === 'NoSuchKey') {
      // console.log('🔍 Key not found, trying alternative paths...');
      
      try {
        const { r2Client, R2_BUCKET_NAME } = await import('../config/r2.js');
        const { GetObjectCommand } = await import('@aws-sdk/client-s3');
        
        // Try different possible paths
        const alternativePaths = [
          `profile-photos/${req.params.r2Key}`,
          `profile-pictures/${req.params.r2Key}`,
          `images/${req.params.r2Key}`,
          req.params.r2Key
        ];
        
        for (const path of alternativePaths) {
          try {
            // console.log('🔍 Trying path:', path);
            const command = new GetObjectCommand({
              Bucket: R2_BUCKET_NAME,
              Key: path
            });
            
            const response = await r2Client.send(command);
            
            // Set appropriate headers
            res.set({
              'Content-Type': response.ContentType || 'image/jpeg',
              'Content-Length': response.ContentLength,
              'Cache-Control': 'public, max-age=3600'
            });
            
            // Stream the file
            response.Body.pipe(res);
            return; // Success, exit the function
            
          } catch (pathError) {
            // console.log('🔍 Path failed:', path, pathError.Code);
            continue; // Try next path
          }
        }
      } catch (fallbackError) {
        // console.error('🔍 All fallback paths failed:', fallbackError);
      }
    }
    
    // If we get here, no image was found
    res.status(404).json({
      success: false,
      message: 'Profile picture not found',
      error: 'Image not found in R2 bucket'
    });
  }
});

export default router;

