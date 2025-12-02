import express from 'express';
import multer from 'multer';
import {
  getAllGalleryImages,
  getGalleryImage,
  generateGalleryUploadUrl,
  createGalleryImage,
  updateGalleryImage,
  deleteGalleryImage,
  bulkDeleteGalleryImages,
  uploadGalleryImage,
  proxyGalleryImage,
  reorderGalleryImages
} from '../controllers/galleryController.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Configure multer for gallery image uploads
const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only images (JPEG, PNG, WebP, GIF) are allowed.'), false);
    }
  },
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Public routes - Get gallery images
router.get('/', getAllGalleryImages);
router.get('/proxy/:r2Key', proxyGalleryImage); // Proxy route must come before /:id
router.get('/:id', getGalleryImage);

// Admin routes - Gallery management
router.post('/upload-url', adminAuth, generateGalleryUploadUrl);
router.post('/upload', adminAuth, upload.single('image'), uploadGalleryImage);
router.post('/', adminAuth, createGalleryImage);
router.put('/reorder', adminAuth, reorderGalleryImages); // Must come before /:id
router.put('/:id', adminAuth, updateGalleryImage);
router.delete('/bulk/delete', adminAuth, bulkDeleteGalleryImages); // Must come before /:id
router.delete('/:id', adminAuth, deleteGalleryImage);

export default router;

