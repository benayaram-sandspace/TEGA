/**
 * 🚀 Production-Ready Cloudflare R2 Service
 *
 * A comprehensive, enterprise-grade service for interacting with Cloudflare R2 storage.
 * Features multipart uploads, progress tracking, error handling, and more.
 *
 * @author TEGA Development Team
 * @version 2.0.0
 * @since 2024
 *
 * ## Environment Variables Required:
 * - R2_ACCESS_KEY_ID: Your R2 access key
 * - R2_SECRET_ACCESS_KEY: Your R2 secret key
 * - R2_BUCKET_NAME: Your R2 bucket name
 *
 * ## Environment Variables Optional:
 * - R2_ENDPOINT: Custom endpoint URL (or use R2_ACCOUNT_ID)
 * - R2_ACCOUNT_ID: Your R2 account ID (for auto-generating endpoint)
 * - R2_PUBLIC_URL: Custom domain for public URLs
 *
 * ## Features:
 * ✅ Multipart uploads for large files (1GB+)
 * ✅ Progress tracking and callbacks
 * ✅ Signed URL generation for secure access
 * ✅ Comprehensive error handling
 * ✅ Input validation and sanitization
 * ✅ Production-ready logging
 * ✅ Automatic retry mechanisms
 * ✅ Metadata support
 * ✅ Public URL generation
 * ✅ Service health checks
 *
 * ## Usage Examples:
 *
 * ### Backward Compatible API (for MERN team):
 * ```javascript
 * import { uploadToR2, generateR2Key, generatePresignedDownloadUrl } from './services/r2Service.js';
 *
 * // Same function signatures as old r2.js
 * const key = generateR2Key('videos', 'my-video.mp4');
 * const result = await uploadToR2(fileBuffer, key, 'video/mp4');
 * const signedUrl = await generatePresignedDownloadUrl(key, 3600);
 * ```
 *
 * ### Advanced API (for new features):
 * ```javascript
 * import r2Service from './services/r2Service.js';
 *
 * // Upload with progress tracking
 * const result = await r2Service.uploadFile(
 *   'videos/my-video.mp4',
 *   fileBuffer,
 *   'video/mp4',
 *   {
 *     metadata: { userId: '123' },
 *     onProgress: (percentage) => console.log(`${percentage}% uploaded`)
 *   }
 * );
 *
 * // Check if service is configured
 * if (r2Service.isServiceConfigured()) {
 *   console.log('R2 service is ready!');
 * }
 * ```
 */

import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand,
} from "@aws-sdk/client-s3";
import { Upload } from "@aws-sdk/lib-storage";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import stream from "stream";

class R2Service {
  constructor() {
    // Enhanced environment variable validation
    this.requiredEnvVars = [
      "R2_ACCESS_KEY_ID",
      "R2_SECRET_ACCESS_KEY",
      "R2_BUCKET_NAME",
    ];

    this.optionalEnvVars = ["R2_ACCOUNT_ID", "R2_ENDPOINT", "R2_PUBLIC_URL"];

    // Check required environment variables
    const missingVars = this.requiredEnvVars.filter(
      (varName) => !process.env[varName]
    );

    if (missingVars.length > 0) {
      console.error(
        `❌ R2 Service: Missing required environment variables: ${missingVars.join(
          ", "
        )}`
      );
      this.isConfigured = false;
      return;
    }

    // Build endpoint URL
    let endpoint;
    if (process.env.R2_ENDPOINT) {
      endpoint = process.env.R2_ENDPOINT;
    } else if (process.env.R2_ACCOUNT_ID) {
      endpoint = `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
    } else {
      console.error(
        "❌ R2 Service: Either R2_ENDPOINT or R2_ACCOUNT_ID must be provided"
      );
      this.isConfigured = false;
      return;
    }

    try {
      this.s3Client = new S3Client({
        region: "auto",
        endpoint: endpoint,
        credentials: {
          accessKeyId: process.env.R2_ACCESS_KEY_ID,
          secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
        },
        // Enhanced configuration for production
        maxAttempts: 3,
        retryMode: "adaptive",
      });

      this.bucketName = process.env.R2_BUCKET_NAME;
      this.publicUrl = process.env.R2_PUBLIC_URL;
      this.isConfigured = true;

      console.log(`✅ R2 Service initialized successfully`);
      console.log(`📦 Bucket: ${this.bucketName}`);
      console.log(`🌐 Endpoint: ${endpoint}`);
      if (this.publicUrl) {
        console.log(`🔗 Public URL: ${this.publicUrl}`);
      }
    } catch (error) {
      console.error("❌ R2 Service initialization failed:", error.message);
      this.isConfigured = false;
    }
  }

  /**
   * Get signed URL for downloading/streaming files
   * @param {string} key - The object key (file path)
   * @param {number} expiresIn - Expiration time in seconds (default: 1 hour)
   * @param {Object} options - Additional options
   * @returns {Promise<Object>} - Result with signed URL and metadata
   */
  async getSignedUrl(key, expiresIn = 3600, options = {}) {
    this._validateConfiguration();
    this._validateKey(key);

    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        ...options,
      });

      const signedUrl = await getSignedUrl(this.s3Client, command, {
        expiresIn,
      });

      return {
        success: true,
        downloadUrl: signedUrl,
        key: key,
        expiresIn: expiresIn,
        expiresAt: new Date(Date.now() + expiresIn * 1000).toISOString(),
      };
    } catch (error) {
      console.error(`❌ Error generating signed URL for key "${key}":`, error);
      throw new Error(`Failed to generate signed URL: ${error.message}`);
    }
  }

  /**
   * Generate a presigned URL for direct upload from client
   * @param {string} key - The object key (file path)
   * @param {string} contentType - MIME type
   * @param {number} expiresIn - Expiration time in seconds (default: 1 hour)
   * @param {Object} metadata - Additional metadata
   * @returns {Promise<Object>} - Result with upload URL and metadata
   */
  async generatePresignedUploadUrl(
    key,
    contentType,
    expiresIn = 3600,
    metadata = {}
  ) {
    this._validateConfiguration();
    this._validateKey(key);
    this._validateContentType(contentType);

    try {
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        ContentType: contentType,
        Metadata: metadata,
      });

      const signedUrl = await getSignedUrl(this.s3Client, command, {
        expiresIn,
      });

      return {
        success: true,
        uploadUrl: signedUrl,
        key: key,
        contentType: contentType,
        expiresIn: expiresIn,
        expiresAt: new Date(Date.now() + expiresIn * 1000).toISOString(),
      };
    } catch (error) {
      console.error(
        `❌ Error generating presigned upload URL for key "${key}":`,
        error
      );
      throw new Error(
        `Failed to generate presigned upload URL: ${error.message}`
      );
    }
  }

  /**
   * Stream video content directly
   * @param {string} key - The object key (file path)
   * @returns {Promise<stream.Readable>} - Video stream
   */
  async streamVideo(key) {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      const response = await this.s3Client.send(command);
      return response.Body;
    } catch (error) {
      console.error("Error streaming video:", error);
      throw new Error("Video not found");
    }
  }

  /**
   * Check if object exists
   * @param {string} key - The object key (file path)
   * @returns {Promise<boolean>} - True if exists
   */
  async objectExists(key) {
    if (!this.isConfigured) {
      return false;
    }

    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      await this.s3Client.send(command);
      return true;
    } catch (error) {
      if (error.name === "NotFound") {
        return false;
      }
      throw error;
    }
  }

  /**
   * Upload file to R2 with multipart support for large files
   * @param {string} key - The object key (file path)
   * @param {Buffer|stream.Readable|File} body - File content
   * @param {string} contentType - MIME type
   * @param {Object} options - Upload options
   * @returns {Promise<Object>} - Upload result
   */
  async uploadFile(key, body, contentType, options = {}) {
    this._validateConfiguration();
    this._validateKey(key);
    this._validateContentType(contentType);

    const {
      metadata = {},
      useMultipart = true,
      partSize = 10 * 1024 * 1024, // 10MB
      queueSize = 4,
      onProgress = null,
    } = options;

    try {
      // For large files, use multipart upload
      if (useMultipart && this._shouldUseMultipart(body)) {
        return await this._multipartUpload(key, body, contentType, {
          metadata,
          partSize,
          queueSize,
          onProgress,
        });
      }

      // For smaller files, use simple upload
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: body,
        ContentType: contentType,
        Metadata: metadata,
      });

      const result = await this.s3Client.send(command);
      const publicUrl = this._generatePublicUrl(key);

      return {
        success: true,
        key: key,
        etag: result.ETag,
        location: result.Location,
        url: publicUrl,
        size: this._getBodySize(body),
        contentType: contentType,
      };
    } catch (error) {
      console.error(`❌ Error uploading file "${key}":`, error);
      throw new Error(`Failed to upload file: ${error.message}`);
    }
  }

  /**
   * Multipart upload for large files
   * @private
   */
  async _multipartUpload(key, body, contentType, options) {
    const { metadata, partSize, queueSize, onProgress } = options;

    const upload = new Upload({
      client: this.s3Client,
      params: {
        Bucket: this.bucketName,
        Key: key,
        Body: body,
        ContentType: contentType,
        Metadata: metadata,
      },
      queueSize,
      partSize,
      leavePartsOnError: false,
    });

    // Progress tracking
    if (onProgress) {
      upload.on("httpUploadProgress", (progress) => {
        const percentage = Math.round((progress.loaded / progress.total) * 100);
        onProgress(percentage, progress.loaded, progress.total);
      });
    }

    const result = await upload.done();
    const publicUrl = this._generatePublicUrl(key);

    return {
      success: true,
      key: key,
      etag: result.ETag,
      location: result.Location,
      url: publicUrl,
      size: this._getBodySize(body),
      contentType: contentType,
      multipart: true,
    };
  }

  /**
   * Delete file from R2
   * @param {string} key - The object key (file path)
   * @returns {Promise<Object>} - Delete result
   */
  async deleteFile(key) {
    this._validateConfiguration();
    this._validateKey(key);

    try {
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      await this.s3Client.send(command);
      console.log(`✅ Successfully deleted file: ${key}`);
      return {
        success: true,
        key: key,
        message: "File deleted successfully",
      };
    } catch (error) {
      console.error(`❌ Error deleting file "${key}":`, error);
      throw new Error(`Failed to delete file: ${error.message}`);
    }
  }

  /**
   * Get file metadata
   * @param {string} key - The object key (file path)
   * @returns {Promise<Object>} - File metadata
   */
  async getFileMetadata(key) {
    this._validateConfiguration();
    this._validateKey(key);

    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      const response = await this.s3Client.send(command);
      return {
        success: true,
        exists: true,
        key: key,
        size: response.ContentLength,
        contentType: response.ContentType,
        lastModified: response.LastModified,
        etag: response.ETag,
        metadata: response.Metadata || {},
        url: this._generatePublicUrl(key),
      };
    } catch (error) {
      if (error.name === "NotFound") {
        return {
          success: true,
          exists: false,
          key: key,
        };
      }
      console.error(`❌ Error getting metadata for "${key}":`, error);
      throw new Error(`Failed to get file metadata: ${error.message}`);
    }
  }

  /**
   * Generate a unique key for R2 storage
   * @param {string} prefix - Key prefix (e.g., 'videos', 'images')
   * @param {string} filename - Original filename
   * @param {Object} options - Additional options
   * @returns {string} - Generated unique key
   */
  generateKey(prefix, filename, options = {}) {
    const {
      includeTimestamp = true,
      includeRandom = true,
      sanitizeFilename = true,
    } = options;

    let key = prefix ? `${prefix}/` : "";

    if (includeTimestamp) {
      key += `${Date.now()}-`;
    }

    if (includeRandom) {
      key += `${Math.random().toString(36).substring(2, 15)}-`;
    }

    if (sanitizeFilename) {
      key += filename.replace(/[^a-zA-Z0-9.-]/g, "_");
    } else {
      key += filename;
    }

    return key;
  }

  /**
   * Check if service is properly configured
   * @returns {boolean} - Configuration status
   */
  isServiceConfigured() {
    return this.isConfigured;
  }

  /**
   * Get service configuration info
   * @returns {Object} - Configuration details
   */
  getServiceInfo() {
    return {
      configured: this.isConfigured,
      bucketName: this.bucketName,
      publicUrl: this.publicUrl,
      endpoint: this.s3Client?.config?.endpoint?.toString(),
    };
  }

  // ==================== PRIVATE UTILITY METHODS ====================

  /**
   * Validate service configuration
   * @private
   */
  _validateConfiguration() {
    if (!this.isConfigured) {
      throw new Error(
        "R2 service not configured. Check environment variables."
      );
    }
  }

  /**
   * Validate object key
   * @private
   */
  _validateKey(key) {
    if (!key || typeof key !== "string" || key.trim() === "") {
      throw new Error("Invalid key: Key must be a non-empty string");
    }
  }

  /**
   * Validate content type
   * @private
   */
  _validateContentType(contentType) {
    if (!contentType || typeof contentType !== "string") {
      throw new Error(
        "Invalid content type: Content type must be a non-empty string"
      );
    }
  }

  /**
   * Determine if multipart upload should be used
   * @private
   */
  _shouldUseMultipart(body) {
    // Use multipart for files larger than 100MB
    const size = this._getBodySize(body);
    return size > 100 * 1024 * 1024;
  }

  /**
   * Get body size for multipart decision
   * @private
   */
  _getBodySize(body) {
    if (Buffer.isBuffer(body)) {
      return body.length;
    }
    if (body && typeof body.size === "number") {
      return body.size;
    }
    if (body && typeof body.length === "number") {
      return body.length;
    }
    return 0;
  }

  /**
   * Generate public URL for a key
   * @private
   */
  _generatePublicUrl(key) {
    if (this.publicUrl) {
      return `${this.publicUrl}/${key}`;
    }
    // Fallback to default R2 URL format
    return `https://pub-${
      process.env.R2_ACCOUNT_ID || "unknown"
    }.r2.dev/${key}`;
  }
}

// Create instance for internal use
const r2ServiceInstance = new R2Service();

// Export individual functions to match old r2.js API
export const uploadToR2 = async (file, key, contentType, metadata = {}) => {
  return await r2ServiceInstance.uploadFile(key, file, contentType, {
    metadata,
  });
};

export const generatePresignedUploadUrl = async (
  key,
  contentType,
  expiresIn = 3600
) => {
  return await r2ServiceInstance.generatePresignedUploadUrl(
    key,
    contentType,
    expiresIn
  );
};

export const generatePresignedDownloadUrl = async (key, expiresIn = 3600) => {
  return await r2ServiceInstance.getSignedUrl(key, expiresIn);
};

export const deleteFromR2 = async (key) => {
  return await r2ServiceInstance.deleteFile(key);
};

export const fileExistsInR2 = async (key) => {
  const result = await r2ServiceInstance.getFileMetadata(key);
  return result.exists;
};

export const getR2FileMetadata = async (key) => {
  return await r2ServiceInstance.getFileMetadata(key);
};

export const generateR2Key = (prefix, filename) => {
  return r2ServiceInstance.generateKey(prefix, filename);
};

// Export additional utilities that might be used by MERN team
export const r2Client = r2ServiceInstance.s3Client;
export const R2_BUCKET_NAME = r2ServiceInstance.bucketName;

// Also export the service instance for advanced usage
export default r2ServiceInstance;
