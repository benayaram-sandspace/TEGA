import mongoose from 'mongoose';
import Admin from '../src/models/Admin.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

async function listAdmins() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);

    // Get all admins
    const admins = await Admin.find({}).sort({ createdAt: -1 });

    if (admins.length === 0) {
      process.exit(0);
    }


    admins.forEach((admin, index) => {
    });


    process.exit(0);
  } catch (error) {
    process.exit(1);
  }
}


listAdmins();
