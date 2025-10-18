import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import Student from './src/models/Student.js';

async function createTestUser() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tega');
    console.log('✅ Connected to MongoDB');

    // Check if user already exists
    const existingUser = await Student.findOne({ email: 'runnov20@gmail.com' });
    if (existingUser) {
      console.log('✅ User already exists:', existingUser.email);
      await mongoose.disconnect();
      return;
    }

    // Create new user
    const hashedPassword = await bcrypt.hash('password123', 12);
    
    const newUser = new Student({
      email: 'runnov20@gmail.com',
      password: hashedPassword,
      username: 'runnov20',
      firstName: 'Test',
      lastName: 'User',
      role: 'student',
      isActive: true,
      emailVerified: true
    });

    await newUser.save();
    console.log('✅ Test user created successfully:', {
      email: newUser.email,
      username: newUser.username,
      role: newUser.role
    });

    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');

  } catch (error) {
    console.error('❌ Error creating test user:', error.message);
    process.exit(1);
  }
}

createTestUser();
