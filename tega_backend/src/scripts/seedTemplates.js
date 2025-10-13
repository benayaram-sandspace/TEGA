import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Template from '../models/Template.js';

dotenv.config();

const templates = [
  {
    name: 'classic',
    displayName: 'Classic',
    description: 'A clean and professional resume template',
    isPremium: false,
    thumbnail: '/templates/classic-thumbnail.jpg'
  },
  {
    name: 'modern',
    displayName: 'Modern',
    description: 'A modern and stylish resume template',
    isPremium: false,
    thumbnail: '/templates/modern-thumbnail.jpg'
  },
  {
    name: 'executive',
    displayName: 'Executive',
    description: 'An elegant template for senior professionals',
    isPremium: true,
    thumbnail: '/templates/executive-thumbnail.jpg'
  },
  {
    name: 'creative',
    displayName: 'Creative',
    description: 'A creative template for design professionals',
    isPremium: true,
    thumbnail: '/templates/creative-thumbnail.jpg'
  }
];

async function seedTemplates() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    // Clear existing templates
    await Template.deleteMany({});

    // Insert new templates
    const createdTemplates = await Template.insertMany(templates);

    // Close the connection
    await mongoose.connection.close();
  } catch (error) {
    process.exit(1);
  }
}

// Run the seed function
seedTemplates();
