import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { seedCourses } from './courseSeeder.js';

// Load environment variables
dotenv.config();

const runSeeders = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tega-auth-starter');

    // Run seeders

    // Seed courses
    await seedCourses();

  } catch (error) {
  } finally {
    // Close database connection
    await mongoose.connection.close();
    process.exit(0);
  }
};

// Run seeders if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runSeeders();
}

export { runSeeders };
