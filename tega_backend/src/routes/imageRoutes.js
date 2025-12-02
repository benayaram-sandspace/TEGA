import express from 'express';
import multer from 'multer';
import { adminAuth } from '../middleware/adminAuth.js';
import { uploadToR2, generateR2Key, deleteFromR2, getR2Client, getR2BucketName } from '../config/r2.js';

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    const allowedTypes = new Set([
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/svg+xml',
      'image/webp',
      'image/heic',
      'image/heif'
    ]);
    if (!allowedTypes.has(file.mimetype)) {
      return cb(new Error('Only image files are allowed!'), false);
    }
    cb(null, true);
  },
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

const buildPublicUrl = (key) => {
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
  return key;
};

const uploadImageToR2 = async (file, adminId) => {
  const r2Key = generateR2Key('question-images', file.originalname);
  const uploadResult = await uploadToR2(file.buffer, r2Key, file.mimetype, {
    uploadedBy: adminId ? String(adminId) : 'system',
    originalName: file.originalname
  });

  const publicUrl = uploadResult.url || buildPublicUrl(r2Key);
  const proxyPath = `/api/images/proxy/${encodeURIComponent(r2Key)}`;

  return {
    r2Key,
    url: publicUrl,
    proxyPath,
    size: uploadResult.size ?? file.size,
    mimeType: uploadResult.contentType ?? file.mimetype
  };
};

// Upload single image
router.post('/upload', adminAuth, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image uploaded'
      });
    }

    const adminId = req.adminId || req.user?.id;
    const image = await uploadImageToR2(req.file, adminId);

    res.json({
      success: true,
      message: 'Image uploaded successfully',
      imageUrl: image.proxyPath,
      r2Key: image.r2Key,
      publicUrl: image.url,
      filename: image.r2Key
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to upload image',
      error: error.message
    });
  }
});

// Upload multiple images
router.post('/upload-multiple', adminAuth, upload.array('images', 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No images uploaded'
      });
    }

    const adminId = req.adminId || req.user?.id;
    const uploads = await Promise.all(req.files.map(async (file) => {
      const image = await uploadImageToR2(file, adminId);
      return {
        url: image.proxyPath,
        r2Key: image.r2Key,
        publicUrl: image.url,
        filename: image.r2Key
      };
    }));

    res.json({
      success: true,
      message: `${uploads.length} images uploaded successfully`,
      images: uploads
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to upload images',
      error: error.message
    });
  }
});

// Delete image
router.delete('/delete/:r2Key', adminAuth, async (req, res) => {
  try {
    const { r2Key } = req.params;
    const decodedKey = decodeURIComponent(r2Key);
    await deleteFromR2(decodedKey);

    res.json({
      success: true,
      message: 'Image deleted successfully'
    });
  } catch (error) {
    if (error.Code === 'NoSuchKey' || error.name === 'NoSuchKey') {
      return res.status(404).json({
        success: false,
        message: 'Image not found',
        error: error.message
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to delete image',
      error: error.message
    });
  }
});

// Proxy route to stream images from R2 (avoids exposing direct bucket URL)
router.get('/proxy/:r2Key', async (req, res) => {
  try {
    const decodedKey = decodeURIComponent(req.params.r2Key);
    const { GetObjectCommand } = await import('@aws-sdk/client-s3');
    const r2Client = getR2Client();
    const bucketName = getR2BucketName();

    if (!r2Client || !bucketName) {
      return res.status(503).json({
        success: false,
        message: 'R2 storage is not configured'
      });
    }

    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: decodedKey
    });

    const response = await r2Client.send(command);
    res.set({
      'Content-Type': response.ContentType || 'image/jpeg',
      'Cache-Control': 'public, max-age=3600'
    });

    if (typeof response.Body?.pipe === 'function') {
      response.Body.pipe(res);
    } else if (typeof response.Body?.transformToByteArray === 'function') {
      const buffer = Buffer.from(await response.Body.transformToByteArray());
      res.send(buffer);
    } else {
      res.status(500).json({
        success: false,
        message: 'Unable to read image stream'
      });
    }
  } catch (error) {
    if (error.Code === 'NoSuchKey' || error.name === 'NoSuchKey') {
      return res.status(404).json({
        success: false,
        message: 'Image not found'
      });
    }
    res.status(500).json({
      success: false,
      message: 'Failed to fetch image',
      error: error.message
    });
  }
});

export default router;
