import Gallery from '../models/Gallery.js';
import { generatePresignedUploadUrl, generatePresignedDownloadUrl, uploadToR2, generateR2Key, getR2Client, getR2BucketName } from '../config/r2.js';
import { randomUUID } from 'crypto';
import { GetObjectCommand } from '@aws-sdk/client-s3';

// Helper function to build image URL (proxy or public URL)
const buildImageUrl = (image) => {
  if (image.r2Key) {
    // Use relative proxy endpoint for R2 images (works with Vite proxy in dev and same domain in prod)
    // In development, Vite proxy will forward /api/* to the backend
    // In production, if frontend and backend are on same domain, relative URL works
    // If on different domains, use SERVER_URL or API_URL env var
    if (process.env.SERVER_URL || process.env.API_URL) {
      const serverUrl = process.env.SERVER_URL || process.env.API_URL;
      return `${serverUrl}/api/gallery/proxy/${encodeURIComponent(image.r2Key)}`;
    }
    // Use relative URL (works with Vite proxy in dev)
    return `/api/gallery/proxy/${encodeURIComponent(image.r2Key)}`;
  }
  // Use the stored imageUrl for direct URLs
  return image.imageUrl;
};

// Get all gallery images
export const getAllGalleryImages = async (req, res) => {
  try {
    const { category, featured, isActive } = req.query;
    
    const query = {};
    if (category && category !== 'All') {
      query.category = category;
    }
    if (featured !== undefined) {
      query.featured = featured === 'true';
    }
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    } else {
      query.isActive = true; // Default to active only
    }

    const images = await Gallery.find(query)
      .sort({ order: 1, createdAt: -1 })
      .populate('uploadedBy', 'firstName lastName email')
      .lean();

    // Update image URLs to use proxy if r2Key exists
    const imagesWithUrls = images.map(img => ({
      ...img,
      imageUrl: buildImageUrl(img)
    }));

    res.json({
      success: true,
      data: imagesWithUrls,
      count: imagesWithUrls.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch gallery images',
      error: error.message
    });
  }
};

// Get single gallery image
export const getGalleryImage = async (req, res) => {
  try {
    const { id } = req.params;
    
    const image = await Gallery.findById(id)
      .populate('uploadedBy', 'firstName lastName email')
      .lean();

    if (!image) {
      return res.status(404).json({
        success: false,
        message: 'Gallery image not found'
      });
    }

    // Update image URL to use proxy if r2Key exists
    const imageWithUrl = {
      ...image,
      imageUrl: buildImageUrl(image)
    };

    res.json({
      success: true,
      data: imageWithUrl
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch gallery image',
      error: error.message
    });
  }
};

// Generate upload URL for gallery image
export const generateGalleryUploadUrl = async (req, res) => {
  try {
    const { fileName, fileType } = req.body;
    
    if (!fileName || !fileType) {
      return res.status(400).json({
        success: false,
        message: 'File name and file type are required'
      });
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedTypes.includes(fileType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid file type. Only images are allowed.'
      });
    }

    const fileExtension = fileName.split('.').pop();
    const uniqueFileName = `gallery/${randomUUID()}.${fileExtension}`;
    
    const uploadUrl = await generatePresignedUploadUrl(uniqueFileName, fileType, 3600);

    res.json({
      success: true,
      uploadUrl: uploadUrl.uploadUrl,
      r2Key: uniqueFileName,
      expiresIn: 3600
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to generate upload URL',
      error: error.message
    });
  }
};

// Create gallery image
export const createGalleryImage = async (req, res) => {
  try {
    const { title, alt, category, customCategory, imageUrl, r2Key, date, height, featured, order } = req.body;
    
    if (!title || !alt || !category || !imageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Title, alt text, category, and image URL are required'
      });
    }

    if (category === 'Other' && (!customCategory || !customCategory.trim())) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a custom category name when selecting Other'
      });
    }

    // Build image URL - use proxy if r2Key exists, otherwise use provided imageUrl
    let finalImageUrl = imageUrl;
    if (r2Key) {
      if (process.env.SERVER_URL || process.env.API_URL) {
        const serverUrl = process.env.SERVER_URL || process.env.API_URL;
        finalImageUrl = `${serverUrl}/api/gallery/proxy/${encodeURIComponent(r2Key)}`;
      } else {
        // Use relative URL (works with Vite proxy in dev)
        finalImageUrl = `/api/gallery/proxy/${encodeURIComponent(r2Key)}`;
      }
    }

    const normalizedCustomCategory = category === 'Other' ? (customCategory?.trim() || '') : '';

    const galleryImage = new Gallery({
      title,
      alt,
      category,
      imageUrl: finalImageUrl,
      r2Key: r2Key || null,
      customCategory: normalizedCustomCategory,
      date: date ? new Date(date) : new Date(),
      height: height || 'medium',
      featured: featured || false,
      order: order || 0,
      uploadedBy: req.adminId || req.admin?._id
    });

    await galleryImage.save();

    const populatedImage = await Gallery.findById(galleryImage._id)
      .populate('uploadedBy', 'firstName lastName email')
      .lean();

    // Update image URL to use proxy if r2Key exists
    const imageWithUrl = {
      ...populatedImage,
      imageUrl: buildImageUrl(populatedImage)
    };

    res.status(201).json({
      success: true,
      message: 'Gallery image added successfully',
      data: imageWithUrl
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create gallery image',
      error: error.message
    });
  }
};

// Update gallery image
export const updateGalleryImage = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, alt, category, customCategory, imageUrl, r2Key, date, height, featured, order, isActive } = req.body;
    
    const image = await Gallery.findById(id);
    
    if (!image) {
      return res.status(404).json({
        success: false,
        message: 'Gallery image not found'
      });
    }

    // Update fields
    if (title !== undefined) image.title = title;
    if (alt !== undefined) image.alt = alt;
    if (category !== undefined) image.category = category;
    if (date !== undefined) image.date = new Date(date);
    if (height !== undefined) image.height = height;
    if (featured !== undefined) image.featured = featured;
    if (order !== undefined) image.order = order;
    if (isActive !== undefined) image.isActive = isActive;

    // Update image URL if provided
    if (imageUrl !== undefined) {
      image.imageUrl = imageUrl;
    }
    if (r2Key !== undefined) {
      image.r2Key = r2Key;
      // Update image URL to use proxy if r2Key is provided
      if (r2Key) {
        if (process.env.SERVER_URL || process.env.API_URL) {
          const serverUrl = process.env.SERVER_URL || process.env.API_URL;
          image.imageUrl = `${serverUrl}/api/gallery/proxy/${encodeURIComponent(r2Key)}`;
        } else {
          // Use relative URL (works with Vite proxy in dev)
          image.imageUrl = `/api/gallery/proxy/${encodeURIComponent(r2Key)}`;
        }
      }
    }

    if (category === 'Other' && customCategory !== undefined && !customCategory?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a custom category name when selecting Other'
      });
    }

    if (customCategory !== undefined) {
      image.customCategory = image.category === 'Other'
        ? (customCategory?.trim() || '')
        : '';
    } else if (image.category !== 'Other') {
      // Ensure custom category cleared when switching away from Other
      image.customCategory = '';
    }

    if (image.category === 'Other' && (!image.customCategory || !image.customCategory.trim())) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a custom category name when selecting Other'
      });
    }

    await image.save();

    const updatedImage = await Gallery.findById(id)
      .populate('uploadedBy', 'firstName lastName email')
      .lean();

    // Update image URL to use proxy if r2Key exists
    const imageWithUrl = {
      ...updatedImage,
      imageUrl: buildImageUrl(updatedImage)
    };

    res.json({
      success: true,
      message: 'Gallery image updated successfully',
      data: imageWithUrl
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update gallery image',
      error: error.message
    });
  }
};

// Delete gallery image
export const deleteGalleryImage = async (req, res) => {
  try {
    const { id } = req.params;
    
    const image = await Gallery.findById(id);
    
    if (!image) {
      return res.status(404).json({
        success: false,
        message: 'Gallery image not found'
      });
    }

    await Gallery.findByIdAndDelete(id);

    res.json({
      success: true,
      message: 'Gallery image deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete gallery image',
      error: error.message
    });
  }
};

// Bulk delete gallery images
export const bulkDeleteGalleryImages = async (req, res) => {
  try {
    const { ids } = req.body;
    
    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Array of image IDs is required'
      });
    }

    const result = await Gallery.deleteMany({ _id: { $in: ids } });

    res.json({
      success: true,
      message: `${result.deletedCount} gallery image(s) deleted successfully`,
      deletedCount: result.deletedCount
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete gallery images',
      error: error.message
    });
  }
};

// Direct file upload to R2 for gallery images
export const uploadGalleryImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const file = req.file;
    const adminId = req.adminId || req.admin?._id;

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedTypes.includes(file.mimetype)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid file type. Only images (JPEG, PNG, WebP, GIF) are allowed.'
      });
    }

    // Validate file size (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        message: 'File too large. Maximum size is 10MB.'
      });
    }

    // Generate R2 key
    const r2Key = generateR2Key('gallery', file.originalname);

    // Upload to R2
    const uploadResult = await uploadToR2(
      file.buffer,
      r2Key,
      file.mimetype,
      {
        uploadedBy: adminId ? String(adminId) : 'system',
        originalName: file.originalname,
        uploadedAt: new Date().toISOString()
      }
    );

    // Build proxy URL for the image (use relative URL for better compatibility)
    let proxyUrl;
    if (process.env.SERVER_URL || process.env.API_URL) {
      const serverUrl = process.env.SERVER_URL || process.env.API_URL;
      proxyUrl = `${serverUrl}/api/gallery/proxy/${encodeURIComponent(r2Key)}`;
    } else {
      // Use relative URL (works with Vite proxy in dev)
      proxyUrl = `/api/gallery/proxy/${encodeURIComponent(r2Key)}`;
    }

    res.json({
      success: true,
      message: 'Image uploaded successfully to Cloudflare R2',
      data: {
        r2Key: r2Key,
        imageUrl: proxyUrl, // Use proxy URL for reliable access
        publicUrl: uploadResult.url,
        fileName: file.originalname,
        fileSize: file.size,
        mimeType: file.mimetype
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to upload image to Cloudflare R2',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Reorder gallery images
export const reorderGalleryImages = async (req, res) => {
  try {
    const { orders } = req.body;

    if (!orders || !Array.isArray(orders) || orders.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Orders array is required'
      });
    }

    // Validate each order entry
    for (const orderEntry of orders) {
      if (!orderEntry.id) {
        return res.status(400).json({
          success: false,
          message: 'Each order entry must have an id'
        });
      }
    }

    // Update each image's order
    const updateResults = await Promise.all(
      orders.map(async ({ id, order: imageOrder }) => {
        const image = await Gallery.findById(id);
        if (!image) {
          throw new Error(`Image with id ${id} not found`);
        }
        image.order = imageOrder !== undefined ? imageOrder : 0;
        return await image.save();
      })
    );

    res.json({
      success: true,
      message: 'Image order updated successfully',
      updatedCount: updateResults.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to reorder gallery images',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Proxy route to stream gallery images from R2
export const proxyGalleryImage = async (req, res) => {
  try {
    const decodedKey = decodeURIComponent(req.params.r2Key);
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
    
    // Set appropriate headers
    res.set({
      'Content-Type': response.ContentType || 'image/jpeg',
      'Cache-Control': 'public, max-age=31536000', // 1 year cache
      'Access-Control-Allow-Origin': '*'
    });

    // Stream the image
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
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

