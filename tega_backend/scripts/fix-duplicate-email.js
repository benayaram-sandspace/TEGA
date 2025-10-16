import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Student from '../src/models/Student.js';

dotenv.config();

async function run() {
  const targetEmail = process.env.DUPLICATE_FIX_EMAIL || 'nunnasivasuryamanikanta@gmail.com';
  try {
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      process.exit(1);
    }
    await mongoose.connect(mongoURI);

    const users = await Student.find({ email: targetEmail }).select('email role _id firstName lastName');
    users.forEach(u => console.log(` - ${u._id} | ${u.role} | ${u.firstName} ${u.lastName}`));

    const student = await Student.findOne({ email: targetEmail, role: 'student' });
    if (!student) {
      return;
    }

    // Safety: ensure a principal exists for this email before deleting student
    const principal = await Student.findOne({ email: targetEmail, role: 'principal' });
    if (!principal) {
      return;
    }

    const res = await Student.deleteOne({ _id: student._id });

    const after = await Student.find({ email: targetEmail }).select('email role _id');
    after.forEach(u => console.log(` - ${u._id} | ${u.role}`));
  } catch (err) {
  } finally {
    await mongoose.disconnect();
  }
}

run();


