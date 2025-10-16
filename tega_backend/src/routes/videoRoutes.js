import express from "express";
import r2Service from "../services/r2Service.js";
import multer from "multer";
import path from "path";

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow video files
    const allowedTypes = [
      "video/mp4",
      "video/avi",
      "video/mov",
      "video/wmv",
      "video/flv",
      "video/webm",
    ];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Only video files are allowed"), false);
    }
  },
});

/**
 * GET /api/videos/stream/:filename
 * Stream video content directly
 */
router.get("/stream/:filename", async (req, res) => {
  try {
    const { filename } = req.params;
    const key = `videos/${filename}`;

    // Check if file exists
    const exists = await r2Service.objectExists(key);
    if (!exists) {
      return res.status(404).json({
        success: false,
        message: "Video not found",
      });
    }

    // Get file metadata
    const metadata = await r2Service.getFileMetadata(key);

    // Set appropriate headers for video streaming
    res.set({
      "Content-Type": metadata.contentType || "video/mp4",
      "Content-Length": metadata.size,
      "Accept-Ranges": "bytes",
      "Cache-Control": "public, max-age=3600",
    });

    // Stream the video
    const videoStream = await r2Service.streamVideo(key);
    videoStream.pipe(res);
  } catch (error) {
    console.error("Video streaming error:", error);
    res.status(500).json({
      success: false,
      message: "Error streaming video",
    });
  }
});

/**
 * GET /api/videos/signed-url/:filename
 * Get signed URL for video access
 */
router.get("/signed-url/:filename", async (req, res) => {
  try {
    const { filename } = req.params;
    const key = `videos/${filename}`;
    const expiresIn = parseInt(req.query.expires) || 3600; // Default 1 hour

    // Check if file exists
    const exists = await r2Service.objectExists(key);
    if (!exists) {
      return res.status(404).json({
        success: false,
        message: "Video not found",
      });
    }

    // Generate signed URL
    const signedUrl = await r2Service.getSignedUrl(key, expiresIn);

    res.json({
      success: true,
      signedUrl: signedUrl,
      expiresIn: expiresIn,
      filename: filename,
    });
  } catch (error) {
    console.error("Signed URL generation error:", error);
    res.status(500).json({
      success: false,
      message: "Error generating signed URL",
    });
  }
});

/**
 * POST /api/videos/upload
 * Upload video file
 */
router.post("/upload", upload.single("video"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No video file provided",
      });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const originalName = req.file.originalname;
    const extension = path.extname(originalName);
    const baseName = path.basename(originalName, extension);
    const filename = `${timestamp}-${baseName}${extension}`;
    const key = `videos/${filename}`;

    // Upload to R2
    const result = await r2Service.uploadFile(
      key,
      req.file.buffer,
      req.file.mimetype
    );

    res.json({
      success: true,
      message: "Video uploaded successfully",
      data: {
        filename: filename,
        key: key,
        url: result.location,
        size: req.file.size,
        contentType: req.file.mimetype,
      },
    });
  } catch (error) {
    console.error("Video upload error:", error);
    res.status(500).json({
      success: false,
      message: "Error uploading video",
    });
  }
});

/**
 * DELETE /api/videos/:filename
 * Delete video file
 */
router.delete("/:filename", async (req, res) => {
  try {
    const { filename } = req.params;
    const key = `videos/${filename}`;

    // Check if file exists
    const exists = await r2Service.objectExists(key);
    if (!exists) {
      return res.status(404).json({
        success: false,
        message: "Video not found",
      });
    }

    // Delete file
    await r2Service.deleteFile(key);

    res.json({
      success: true,
      message: "Video deleted successfully",
      filename: filename,
    });
  } catch (error) {
    console.error("Video deletion error:", error);
    res.status(500).json({
      success: false,
      message: "Error deleting video",
    });
  }
});

/**
 * GET /api/videos/metadata/:filename
 * Get video metadata
 */
router.get("/metadata/:filename", async (req, res) => {
  try {
    const { filename } = req.params;
    const key = `videos/${filename}`;

    const metadata = await r2Service.getFileMetadata(key);

    if (!metadata.exists) {
      return res.status(404).json({
        success: false,
        message: "Video not found",
      });
    }

    res.json({
      success: true,
      metadata: metadata,
    });
  } catch (error) {
    console.error("Metadata retrieval error:", error);
    res.status(500).json({
      success: false,
      message: "Error retrieving video metadata",
    });
  }
});

export default router;
