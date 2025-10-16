#!/usr/bin/env node

/**
 * Production Admin Creation Script
 * 
 * This script creates or updates the admin account in production.
 * Run this on your production server to ensure the admin account exists.
 * 
 * Usage:
 *   node scripts/create-admin.js
 * 
 * Environment Variables Required:
 *   MONGODB_URI - Your production MongoDB connection string
 */

import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Simple Admin schema (inline to avoid import issues)
const adminSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other']
  },
  acceptTerms: {
    type: Boolean,
    required: true,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  role: {
    type: String,
    default: 'admin'
  }
}, {
  timestamps: true
});

const Admin = mongoose.model('Admin', adminSchema);

const createProductionAdmin = async () => {
  try {
    console.log('🚀 Starting admin account creation/update...');
    
    // Check for MongoDB URI
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      console.error('❌ MONGODB_URI environment variable is required');
      console.error('Please set MONGODB_URI in your .env file or environment variables');
      process.exit(1);
    }
    
    // Connect to MongoDB
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(mongoURI);
    console.log('✅ Connected to MongoDB successfully');

    const email = 'sandspace.abdul@gmail.com';
    const password = 'Abdul@1144';

    console.log('\n🔍 Checking for existing admin account...');
    
    // Check if admin already exists
    const existingAdmin = await Admin.findOne({ email });
    
    if (existingAdmin) {
      console.log('⚠️  Admin account already exists');
      console.log('- Email:', existingAdmin.email);
      console.log('- Username:', existingAdmin.username);
      console.log('- Role:', existingAdmin.role);
      console.log('- Active:', existingAdmin.isActive);
      
      // Update password and ensure account is active
      console.log('\n🔄 Updating admin password and status...');
      const hashedPassword = await bcrypt.hash(password, 10);
      await Admin.findByIdAndUpdate(existingAdmin._id, { 
        password: hashedPassword,
        isActive: true,
        role: 'admin'
      });
      
      console.log('✅ Admin account updated successfully');
    } else {
      console.log('📝 Creating new admin account...');
      
      // Create new admin
      const hashedPassword = await bcrypt.hash(password, 10);
      const admin = new Admin({
        username: 'abdul_admin',
        email: email,
        password: hashedPassword,
        gender: 'Male',
        acceptTerms: true,
        isActive: true,
        role: 'admin'
      });
      
      await admin.save();
      console.log('✅ Admin account created successfully');
    }
    
    // Verify the admin exists and password works
    console.log('\n🔍 Verifying admin account...');
    const verifyAdmin = await Admin.findOne({ email });
    
    if (verifyAdmin) {
      const isMatch = await bcrypt.compare(password, verifyAdmin.password);
      
      console.log('\n✅ Admin Account Verification:');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('📧 Email:', verifyAdmin.email);
      console.log('👤 Username:', verifyAdmin.username);
      console.log('🔑 Role:', verifyAdmin.role);
      console.log('✅ Active:', verifyAdmin.isActive);
      console.log('🔐 Password Test:', isMatch ? '✅ PASS' : '❌ FAIL');
      console.log('📅 Created:', verifyAdmin.createdAt);
      console.log('🔄 Updated:', verifyAdmin.updatedAt);
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (isMatch) {
        console.log('\n🎉 SUCCESS! Admin account is ready for use!');
        console.log('\n📋 Login Credentials:');
        console.log('   Email: sandspace.abdul@gmail.com');
        console.log('   Password: Abdul@1144');
        console.log('\n🌐 You can now log in to the admin dashboard.');
      } else {
        console.log('\n❌ ERROR: Password verification failed!');
        process.exit(1);
      }
    } else {
      console.log('\n❌ ERROR: Admin account not found after creation!');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ Error creating admin account:');
    console.error('Message:', error.message);
    if (error.code) {
      console.error('Code:', error.code);
    }
    if (process.env.NODE_ENV === 'development') {
      console.error('Stack:', error.stack);
    }
    process.exit(1);
  } finally {
    // Close database connection
    if (mongoose.connection.readyState === 1) {
      await mongoose.connection.close();
      console.log('\n📡 Database connection closed');
    }
  }
};

// Run the script
createProductionAdmin();
