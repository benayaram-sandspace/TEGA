import { S3Client } from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { PutObjectCommand, GetObjectCommand, DeleteObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';

// Cloudflare R2 configuration
// R2 is S3-compatible, so we use AWS SDK
const r2Client = new S3Client({
  region: 'auto',
  endpoint: process.env.R2_ENDPOINT, // e.g., https://[account_id].r2.cloudflarestorage.com
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  },
});

const R2_BUCKET_NAME = process.env.R2_BUCKET_NAME;
const R2_PUBLIC_URL = process.env.R2_PUBLIC_URL; // Optional: Custom domain for public URLs

/**
 * Upload a file to Cloudflare R2
 * Supports large files (1GB+) with multipart upload
 */
export const uploadToR2 = async (file, key, contentType, metadata = {}) => {
  try {
    const upload = new Upload({
      client: r2Client,
      params: {
        Bucket: R2_BUCKET_NAME,
        Key: key,
        Body: file,
        ContentType: contentType,
        Metadata: metadata,
      },
      // Configure for large file uploads
      queueSize: 4, // concurrent uploads
      partSize: 1024 * 1024 * 10, // 10MB parts
      leavePartsOnError: false,
    });

    upload.on('httpUploadProgress', (progress) => {
      console.log(`Upload Progress: ${Math.round((progress.loaded / progress.total) * 100)}%`);
    });

    const result = await upload.done();
    
    // Generate public URL
    const publicUrl = R2_PUBLIC_URL 
      ? `${R2_PUBLIC_URL}/${key}`
      : `${process.env.R2_ENDPOINT}/${R2_BUCKET_NAME}/${key}`;

    return {
      success: true,
      key: key,
      url: publicUrl,
      etag: result.ETag,
      location: result.Location,
    };
  } catch (error) {
    console.error('R2 Upload Error:', error);
    throw new Error(`Failed to upload to R2: ${error.message}`);
  }
};

/**
 * Generate a presigned URL for direct upload from client
 * This allows large video files to be uploaded directly from browser to R2
 */
export const generatePresignedUploadUrl = async (key, contentType, expiresIn = 3600) => {
  try {
    const command = new PutObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: key,
      ContentType: contentType,
    });

    const signedUrl = await getSignedUrl(r2Client, command, { expiresIn });
    
    return {
      success: true,
      uploadUrl: signedUrl,
      key: key,
      expiresIn: expiresIn,
    };
  } catch (error) {
    console.error('R2 Presigned URL Error:', error);
    throw new Error(`Failed to generate presigned URL: ${error.message}`);
  }
};

/**
 * Generate a presigned URL for downloading files
 */
export const generatePresignedDownloadUrl = async (key, expiresIn = 3600) => {
  try {
    const command = new GetObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: key,
    });

    const signedUrl = await getSignedUrl(r2Client, command, { expiresIn });
    
    return {
      success: true,
      downloadUrl: signedUrl,
      expiresIn: expiresIn,
    };
  } catch (error) {
    console.error('R2 Download URL Error:', error);
    throw new Error(`Failed to generate download URL: ${error.message}`);
  }
};

/**
 * Delete a file from R2
 */
export const deleteFromR2 = async (key) => {
  try {
    const command = new DeleteObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: key,
    });

    await r2Client.send(command);
    
    return {
      success: true,
      message: 'File deleted successfully',
    };
  } catch (error) {
    console.error('R2 Delete Error:', error);
    throw new Error(`Failed to delete from R2: ${error.message}`);
  }
};

/**
 * Check if a file exists in R2
 */
export const fileExistsInR2 = async (key) => {
  try {
    const command = new HeadObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: key,
    });

    await r2Client.send(command);
    return true;
  } catch (error) {
    if (error.name === 'NotFound') {
      return false;
    }
    throw error;
  }
};

/**
 * Get file metadata from R2
 */
export const getR2FileMetadata = async (key) => {
  try {
    const command = new HeadObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: key,
    });

    const response = await r2Client.send(command);
    
    return {
      success: true,
      size: response.ContentLength,
      contentType: response.ContentType,
      lastModified: response.LastModified,
      metadata: response.Metadata,
    };
  } catch (error) {
    console.error('R2 Metadata Error:', error);
    throw new Error(`Failed to get file metadata: ${error.message}`);
  }
};

/**
 * Generate a unique key for R2 storage
 */
export const generateR2Key = (prefix, filename) => {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 15);
  const sanitizedFilename = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
  return `${prefix}/${timestamp}-${random}-${sanitizedFilename}`;
};

export { r2Client, R2_BUCKET_NAME };

