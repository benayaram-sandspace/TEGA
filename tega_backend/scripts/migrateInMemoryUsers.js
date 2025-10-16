// Script to migrate in-memory users to MongoDB
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { inMemoryUsers } from '../src/controllers/authController.js';
import Student from '../src/models/Student.js';

// Load environment variables
dotenv.config();

const migrateUsers = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tega-auth-starter');


    let migratedCount = 0;
    let skippedCount = 0;

    for (const [email, userData] of inMemoryUsers) {
      try {
        // Check if user already exists in database
        const existingUser = await Student.findOne({ email });
        
        if (existingUser) {
          skippedCount++;
          continue;
        }

        // Create new user in database
        const newUser = new Student(userData);
        await newUser.save();
        
        migratedCount++;
        
      } catch (error) {
      }
    }


  } catch (error) {
  } finally {
    await mongoose.disconnect();
  }
};

migrateUsers();
