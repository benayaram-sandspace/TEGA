let cloudinary = null;
let cloudinaryAvailable = false;

// Initialize Cloudinary asynchronously
const initCloudinary = async () => {
  try {
    const { v2 } = await import('cloudinary');
    cloudinary = v2;
    
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
    });
    
    cloudinaryAvailable = true;
  } catch (error) {
    cloudinaryAvailable = false;
  }
};

// Initialize Cloudinary
initCloudinary();

export default cloudinary;
export { cloudinaryAvailable };
