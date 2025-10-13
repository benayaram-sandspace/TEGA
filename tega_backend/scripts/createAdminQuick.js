import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import Admin from '../src/models/Admin.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

async function createAdminQuick() {
  try {
    // Get command line arguments
    const args = process.argv.slice(2);
    
    if (args.length < 3) {
      process.exit(1);
    }

    const [username, email, password, gender = 'Male'] = args;

    // Validate inputs
    if (!username || !email || !password) {
      process.exit(1);
    }

    if (password.length < 6) {
      process.exit(1);
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      process.exit(1);
    }

    if (!['Male', 'Female', 'Other'].includes(gender)) {
      process.exit(1);
    }

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);

    // Check if admin already exists
    const existingAdmin = await Admin.findOne({ 
      $or: [
        { email: email.toLowerCase() },
        { username: username }
      ]
    });

    if (existingAdmin) {
      if (existingAdmin.email === email.toLowerCase()) {
      }
      if (existingAdmin.username === username) {
      }
      process.exit(0);
    }

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create new admin
    const admin = new Admin({
      username: username,
      email: email.toLowerCase(),
      gender: gender,
      acceptTerms: true,
      password: hashedPassword,
      role: 'admin',
      isActive: true
    });

    await admin.save();




    process.exit(0);
  } catch (error) {
    if (error.code === 11000) {
    }
    process.exit(1);
  }
}


createAdminQuick();
