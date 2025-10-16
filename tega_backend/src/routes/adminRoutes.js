import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import nodemailer from 'nodemailer';
import Admin from '../models/Admin.js';
import Student from '../models/Student.js';
import Principal from '../models/Principal.js';
import { adminAuth } from '../middleware/adminAuth.js';
import Notification from '../models/Notification.js';
import RealTimeCourse from '../models/RealTimeCourse.js'; // Use RealTimeCourse only
import UPISettings from '../models/UPISettings.js';
import Payment from '../models/Payment.js'; // Added Payment model
import RazorpayPayment from '../models/RazorpayPayment.js'; // Added RazorpayPayment model
import { getPrincipalWelcomeTemplate } from '../utils/emailTemplates.js';

// Ensure environment variables are loaded
dotenv.config();

const router = express.Router();









// Admin Dashboard Data
router.get('/dashboard', adminAuth, async (req, res) => {
  try {
    // Get statistics
    const totalAdmins = await Admin.countDocuments();
    const totalStudents = await Student.countDocuments();
    const totalPrincipals = await Principal.countDocuments();
    const recentRegistrations = await Student.countDocuments({
      createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
    });

    // Get recent users
    const recentStudents = await Student.find()
      .select('username firstName lastName email institute createdAt studentId')
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      success: true,
      stats: {
        totalAdmins,
        totalStudents,
        totalPrincipals,
        recentRegistrations
      },
      recentStudents
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to load dashboard data'
    });
  }
});

// Note: Delete user functionality is implemented later in this file

// Get all principals
router.get('/principals', adminAuth, async (req, res) => {
  try {
    const principals = await Principal.find().sort({ createdAt: -1 });
    res.json({
      success: true,
      principals: principals
    });
  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to load principals data'
    });
  }
});

// Get a single principal by ID
router.get('/principals/:principalId', adminAuth, async (req, res) => {
  try {
    const { principalId } = req.params;
    const principal = await Principal.findById(principalId).select('-password');

    if (!principal) {
      return res.status(404).json({ success: false, message: 'Principal not found' });
    }

    res.json({ success: true, principal });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to load principal data' });
  }
});

// Update a principal
router.put('/principals/:principalId', adminAuth, async (req, res) => {
  try {
    const { principalId } = req.params;
    const updatedData = req.body;

    // Prevent password from being updated through this route
    delete updatedData.password;

    const principal = await Principal.findByIdAndUpdate(principalId, updatedData, {
      new: true,
      runValidators: true,
    }).select('-password');

    if (!principal) {
      return res.status(404).json({ success: false, message: 'Principal not found' });
    }

    res.json({ success: true, message: 'Principal updated successfully', principal });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to update principal' });
  }
});

// Test route to check if Principal model is working
router.get('/principals/test/:principalId', adminAuth, async (req, res) => {
  try {
    const { principalId } = req.params;

    const principal = await Principal.findById(principalId);

    if (principal) {

    }
    
    res.json({ 
      success: true, 
      principalFound: !!principal,
      principal: principal ? {
        id: principal._id,
        name: principal.principalName,
        email: principal.email
      } : null
    });
  } catch (error) {

    res.status(500).json({ 
      success: false, 
      message: 'Test route failed',
      error: error.message
    });
  }
});

// Bulk import endpoint (newly added)
router.post('/bulk-import', adminAuth, async (req, res) => {
  try {
    const students = req.body.students;
    const savedStudents = await Student.insertMany(students);
    res.json({
      success: true,
      message: 'Students imported successfully',
      savedStudents
    });
  } catch (saveError) {

    // Log detailed error information
    if (saveError.name === 'ValidationError') {

    }
    
    return res.status(500).json({
      success: false,
      message: 'An error occurred while saving student data.',
      error: saveError.message,
      errorDetails: process.env.NODE_ENV === 'development' ? {
        name: saveError.name,
        code: saveError.code,
        keyPattern: saveError.keyPattern,
        keyValue: saveError.keyValue
      } : undefined
    });
  }
});

// Delete a principal
router.delete('/principals/:principalId', adminAuth, async (req, res) => {
  // ... (rest of the code remains the same)
  try {
    const { principalId } = req.params;

    // First, let's check if the principal exists
    const existingPrincipal = await Principal.findById(principalId);
    if (!existingPrincipal) {

      return res.status(404).json({ success: false, message: 'Principal not found' });
    }

    // Now try to delete
    const principal = await Principal.findByIdAndDelete(principalId);
    
    if (!principal) {

      return res.status(500).json({ success: false, message: 'Principal deletion failed' });
    }

    // Try to create notification, but don't fail if it doesn't work
    try {
      const notification = new Notification({
        recipient: req.adminId,
        recipientModel: 'Admin',
        message: `You deleted principal: ${principal.principalName}`,
        type: 'info'
      });
      await notification.save();

    } catch (notificationError) {

      // Don't fail the delete operation if notification fails
    }

    res.json({ success: true, message: 'Principal deleted successfully' });
  } catch (error) {


    // Send more specific error message
    let errorMessage = 'Failed to delete principal';
    if (error.name === 'CastError') {
      errorMessage = 'Invalid principal ID format';
    } else if (error.name === 'ValidationError') {
      errorMessage = 'Principal data validation failed';
    }
    
    res.status(500).json({ 
      success: false, 
      message: errorMessage,
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get a single user (student or principal)
router.get('/users/:userId', adminAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Try to find the user as a student first
    let user = await Student.findById(userId).select('-password');
    let userType = 'student';

    // If not found as student, try as principal
    if (!user) {
      user = await Principal.findById(userId).select('-password');
      userType = 'principal';
    }

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, user, userType });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to load user data' });
  }
});

// Update a user (student or principal)
router.put('/users/:userId', adminAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const updatedData = req.body;

    // Prevent password from being updated through this route
    delete updatedData.password;
    
    // Clean and validate the update data
    const cleanedData = { ...updatedData };
    
    // Remove any fields that shouldn't be updated
    delete cleanedData._id;
    delete cleanedData.createdAt;
    delete cleanedData.updatedAt;
    
    // Normalize gender field for both Student and Principal models
    if (cleanedData.gender) {

      const normalizedGender = cleanedData.gender.toLowerCase().trim();

      // Validate against enum values
      const validGenders = ['male', 'female', 'other'];
      if (!validGenders.includes(normalizedGender)) {

        return res.status(400).json({ 
          success: false, 
          message: `Invalid gender value: ${normalizedGender}. Valid values are: ${validGenders.join(', ')}` 
        });
      }
      
      // Capitalize for Student model (which only accepts capitalized values)
      // Principal model accepts both, so capitalized works for both
      cleanedData.gender = normalizedGender.charAt(0).toUpperCase() + normalizedGender.slice(1);

    }
    
    // Normalize other enum fields if needed
    if (cleanedData.role) {
      cleanedData.role = cleanedData.role.toLowerCase();
    }

    // Try to update as student first

    let user = await Student.findByIdAndUpdate(userId, cleanedData, {
      new: true,
      runValidators: true,
    }).select('-password');

    let userType = 'student';

    // If not found as student, try as principal
    if (!user) {

      try {
        user = await Principal.findByIdAndUpdate(userId, cleanedData, {
          new: true,
          runValidators: true,
        }).select('-password');
        userType = 'principal';

      } catch (principalError) {



        throw principalError; // Re-throw to be caught by outer catch
      }
    }



    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, message: 'User updated successfully', user, userType });
  } catch (error) {





    res.status(500).json({ 
      success: false, 
      message: 'Failed to update user',
      error: error.message 
    });
  }
});

// Delete a user (student or principal)
router.delete('/users/:userId', adminAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Try to delete as student first
    let user = await Student.findByIdAndDelete(userId);
    let userType = 'student';

    // If not found as student, try as principal
    if (!user) {
      user = await Principal.findByIdAndDelete(userId);
      userType = 'principal';
    }
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Create notification for the admin
    const notification = new Notification({
      recipient: req.adminId,
      recipientModel: 'Admin',
      message: `You deleted ${userType}: ${user.studentName || user.principalName}`,
      type: 'info'
    });
    await notification.save();

    res.json({ success: true, message: `${userType} deleted successfully` });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to delete user' });
  }
});

// Get students by college name (MUST be before /students route)
router.get('/students/college/:collegeName', adminAuth, async (req, res) => {
  try {
    const { collegeName } = req.params;

    if (!collegeName) {
      return res.status(400).json({
        success: false,
        message: 'College name is required'
      });
    }

    const decodedCollegeName = decodeURIComponent(collegeName);

    // First, let's see all students and their institutes
    const allStudents = await Student.find({}).select('studentName username email studentId institute course major yearOfStudy');

    // Find students by institute field (case-insensitive)
    // Escape special regex characters in the college name
    const escapedCollegeName = decodedCollegeName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const students = await Student.find({ 
      institute: { $regex: new RegExp(escapedCollegeName, 'i') }
    })
    .select('studentName username email studentId institute course major yearOfStudy phone gender createdAt')
    .sort({ studentName: 1 });

    // Log student details for debugging
    if (students.length > 0) {

    }

    res.json({
      success: true,
      students,
      collegeName: decodedCollegeName,
      count: students.length
    });
  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to load students for this college'
    });
  }
});

// Get all students
router.get('/students', adminAuth, async (req, res) => {
  try {
    const students = await Student.find().sort({ createdAt: -1 });
    res.json({
      success: true,
      students
    });
  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to load students data'
    });
  }
});

// Bulk import students
router.post('/students/bulk-import', adminAuth, async (req, res) => {
  try {
    const { students } = req.body;
    
    // Note: Student IDs will be auto-generated by the Student model

    if (!students || !Array.isArray(students) || students.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Student data is required and must be an array.'
      });
    }

    // Process each student
    const studentsToInsert = [];
    const errors = [];
    
    // Process each student
    for (const [index, student] of students.entries()) {
      const rowNumber = index + 1;
      
      try {
        // Validate required fields
        const requiredFields = ['username', 'studentName', 'email', 'password'];
        const missingFields = requiredFields.filter(field => !student[field]);
        
        if (missingFields.length > 0) {
          errors.push(`Row ${rowNumber}: Missing required fields: ${missingFields.join(', ')}`);
          continue;
        }
        
        const { email, username } = student;
        
        // Check for duplicates
        const existingStudent = await Student.findOne({ 
          $or: [
            { email },
            { username }
          ]
        });

        if (existingStudent) {
          let message = `Row ${rowNumber}: A student with this `;
          if (existingStudent.email === email) {
            message += 'email already exists.';
          } else if (existingStudent.username === username) {
            message += 'username already exists.';
          } else {
            message += 'information already exists.';
          }
          
          errors.push(message);
          continue;
        }

        // Normalize gender to match enum values: 'Male', 'Female', 'Other'
        let normalizedGender = 'Other'; // Default value
        if (student.gender && typeof student.gender === 'string') {
          const genderLower = student.gender.trim().toLowerCase();
          if (genderLower === 'male') {
            normalizedGender = 'Male';
          } else if (genderLower === 'female') {
            normalizedGender = 'Female';
          } else if (genderLower === 'other') {
            normalizedGender = 'Other';
          }
        }

        // Process year of study
        let yearOfStudy = 1;
        if (student.yearOfStudy) {
          const parsed = parseInt(student.yearOfStudy);
          if (!isNaN(parsed) && parsed >= 1 && parsed <= 10) {
            yearOfStudy = parsed;
          }
        }

        // Ensure studentName is set
        let studentName = student.studentName;
        if (!studentName && (student.firstName || student.lastName)) {
          studentName = `${student.firstName || ''} ${student.lastName || ''}`.trim();
        }
        if (!studentName && student.username) {
          studentName = student.username;
        }

        // Ensure firstName and lastName are set
        let firstName = student.firstName;
        let lastName = student.lastName;
        if (!firstName && !lastName && studentName) {
          const nameParts = studentName.split(' ');
          firstName = nameParts[0] || '';
          lastName = nameParts.slice(1).join(' ') || '';
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(student.password, salt);

        // Create student object with processed data
        // Explicitly define fields to avoid including studentId
        const studentData = {
          username: student.username,
          studentName,
          firstName,
          lastName,
          email: student.email,
          phone: student.phone,
          password: hashedPassword,
          institute: student.institute,
          course: student.course,
          major: student.major,
          yearOfStudy,
          dob: student.dob,
          gender: normalizedGender,
          address: student.address,
          landmark: student.landmark,
          zipcode: student.zipcode,
          city: student.city,
          district: student.district,
          role: 'student',
          acceptTerms: true
        };
        
        const newStudent = new Student(studentData);

        // Add the new student to the array to be inserted
        studentsToInsert.push(newStudent);
        
      } catch (studentError) {

        errors.push(`Error processing row ${rowNumber}: ${studentError.message}`);
      }
    }

  if (studentsToInsert.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid students to import. Please check your data.',
        errors: errors
      });
    }

    try {

      // Save all students one by one to get detailed error information
      const result = [];
      for (const student of studentsToInsert) {
        try {
          const savedStudent = await student.save();
          result.push(savedStudent);
        } catch (saveError) {

          errors.push(`Error saving student ${student.email || 'unknown'}: ${saveError.message}`);
        }
      }

      const response = {
        success: true,
        message: `${result.length} students imported successfully.`,
        createdCount: result.length,
        totalProcessed: students.length,
        errors: errors.length > 0 ? errors : undefined
      };

      if (errors.length > 0) {
        response.message += ` ${errors.length} rows had errors.`;

      }

      return res.status(201).json(response);

    } catch (saveError) {

      // Handle duplicate key errors and other validation issues
      if (saveError.code === 11000 || saveError.name === 'MongoBulkWriteError') {
        const createdCount = saveError.result?.nInserted || 0;
        const duplicateCount = saveError.writeErrors?.length || 0;
        
        // Try to extract duplicate student IDs for better error reporting
        const duplicateIds = [];
        if (saveError.writeErrors) {
          saveError.writeErrors.forEach(err => {
            if (err.errmsg && err.errmsg.includes('duplicate key')) {
              const match = err.errmsg.match(/studentId: "(.*?)"/);
              if (match && match[1]) {
                duplicateIds.push(match[1]);
              }
            }
          });
        }
        
        return res.status(409).json({
          success: false,
          message: `Import completed with errors. ${createdCount} new students imported, ${duplicateCount} duplicates found.`,
          createdCount,
          duplicateCount,
          duplicateIds: duplicateIds.length > 0 ? duplicateIds : undefined,
          errors: [
            ...errors,
            ...(duplicateIds.length > 0 
              ? [`Duplicate student IDs found: ${duplicateIds.join(', ')}`]
              : ['One or more students already exist in the system.']
            )
          ]
        });
      }

      // For other errors, include the original error message in development
      const errorMessage = process.env.NODE_ENV === 'development' 
        ? (saveError.message || 'An unknown error occurred')
        : 'An error occurred while saving student data.';
      
      // Ensure errors is an array and contains the error message
      const allErrors = Array.isArray(errors) 
        ? [...errors, errorMessage]
        : [errorMessage];
      
      return res.status(500).json({
        success: false,
        message: 'Failed to import students.',
        error: errorMessage,
        errors: allErrors
      });
    }
  } catch (error) {

    // Handle different types of errors with appropriate messages
    let errorMessage = 'An unexpected error occurred during bulk import.';
    let detailedError = process.env.NODE_ENV === 'development' ? error.message : undefined;
    let errorDetails = [];
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      errorMessage = 'Validation error during student import.';
      for (let field in error.errors) {
        errorDetails.push(`${field}: ${error.errors[field].message}`);
      }
    } 
    // Handle duplicate key errors
    else if (error.code === 11000) {
      errorMessage = 'Duplicate key error during import.';
      const keyMatch = error.message.match(/index: (\w+)/);
      if (keyMatch && keyMatch[1]) {
        errorDetails.push(`Duplicate value for field: ${keyMatch[1]}`);
      }
    }
    
    // If no specific details were added, use the general error message
    if (errorDetails.length === 0) {
      errorDetails.push(error.message || 'Unknown error occurred');
    }
    
    const response = {
      success: false,
      message: errorMessage || 'An error occurred during the operation',
      errors: errorDetails
    };
    
    // Only include error details in development
    if (process.env.NODE_ENV === 'development') {
      response.error = error.message;
      response.stack = error.stack;
    }
    
    res.status(500).json(response);
  }
});

// Bulk import principals
router.post('/principals/bulk-import', adminAuth, async (req, res) => {
  try {
    const { principals } = req.body;

    if (!principals || !Array.isArray(principals) || principals.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Principal data is required and must be an array.'
      });
    }

    // Process each principal with password hashing
    const processedPrincipals = [];
    for (const principal of principals) {
      const { principalName, email, university, password, gender = 'other' } = principal;

      // Basic validation (password is optional)
      if (!principalName || !email || !university) {
        continue; // Skip invalid entries
      }

      // Normalize gender to match schema
      let normalizedGender = 'other';
      if (gender && typeof gender === 'string') {
        const genderLower = gender.toLowerCase();
        if (genderLower === 'male' || genderLower === 'female') {
          normalizedGender = genderLower;
        }
      }

      // Check if principal already exists
      const existingPrincipal = await Principal.findOne({ email });
      if (existingPrincipal) {
        continue; // Skip duplicates
      }

      // Use default password if empty
      const finalPassword = password && password.trim() ? password.trim() : 'principal123';
      
      // Hash password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(finalPassword, salt);

      // Split principalName for first and last name
      const nameParts = principalName.trim().split(/\s+/);
      const firstName = nameParts[0] || '';
      const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';

      processedPrincipals.push({
        principalName,
        firstName,
        lastName,
        email,
        university,
        password: hashedPassword,
        gender: normalizedGender,
        role: 'principal',
        acceptTerms: true
      });
    }

    if (processedPrincipals.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid principals to import. Please check your data.'
      });
    }

    // Use insertMany for efficient bulk insertion
    const result = await Principal.insertMany(processedPrincipals, { ordered: false });

    res.status(201).json({
      success: true,
      message: `${result.length} principals imported successfully.`,
      createdCount: result.length
    });

  } catch (error) {
    // Handle duplicate key errors and other validation issues
    if (error.code === 11000 || error.name === 'MongoBulkWriteError') {
      const createdCount = error.result?.nInserted || 0;
      const duplicateCount = error.writeErrors?.length || 0;
      return res.status(409).json({
        success: false,
        message: `Import completed with errors. ${createdCount} new principals imported, ${duplicateCount} duplicates found.`,
        createdCount,
        duplicateCount
      });
    }

    res.status(500).json({
      success: false,
      message: 'An unexpected error occurred during bulk import.'
    });
  }
});

// Register Principal
router.post('/register-principal', adminAuth, async (req, res) => {
  try {
    const { principalName, email, university, password, gender, firstName, lastName } = req.body;

    // Comprehensive validation
    const requiredFields = ['principalName', 'email', 'university', 'password', 'gender'];
    const missingFields = [];
    
    for (const field of requiredFields) {
      if (!req.body[field]) {
        missingFields.push(field);
      }
    }
    
    if (missingFields.length > 0) {
      return res.status(400).json({ 
        success: false,
        message: `The following fields are required: ${missingFields.join(', ')}`
      });
    }

    // Password validation
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(password)) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 8 characters long and include an uppercase letter, a lowercase letter, a number, and a special character."
      });
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ 
        success: false,
        message: "Please provide a valid email address." 
      });
    }

    // Check if a principal with this email already exists
    const existingPrincipal = await Principal.findOne({ 
      $or: [
        { email: email.toLowerCase() },
        { principalName: { $regex: new RegExp(`^${principalName}$`, 'i') } }
      ]
    });
    
    if (existingPrincipal) {
      let message = 'A principal with this information already exists.';
      if (existingPrincipal.email.toLowerCase() === email.toLowerCase()) {
        message = 'A principal with this email already exists.';
      } else if (existingPrincipal.principalName.toLowerCase() === principalName.toLowerCase()) {
        message = 'A principal with this name already exists.';
      }
      
      return res.status(409).json({ 
        success: false,
        message 
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Generate first and last name if not provided
    let finalFirstName = firstName;
    let finalLastName = lastName;
    
    if (!finalFirstName || !finalLastName) {
      const nameParts = principalName.trim().split(/\s+/);
      finalFirstName = nameParts[0] || '';
      finalLastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';
    }

    // Create new principal
    const newPrincipal = new Principal({
      principalName: principalName.trim(),
      firstName: finalFirstName,
      lastName: finalLastName,
      email: email.toLowerCase().trim(),
      university: university.trim(),
      password: hashedPassword,
      gender: gender.toLowerCase(),
      role: 'principal',
      acceptTerms: true,
      isActive: true
    });

    await newPrincipal.save();

    // Notify the admin who performed the action
    const notification = new Notification({
      recipient: req.adminId, // From adminAuth middleware
      recipientModel: 'Admin',
      message: `You registered a new principal: ${newPrincipal.principalName}`,
      type: 'registration'
    });
    await notification.save();

    // Send welcome email to the principal
    try {
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS
        }
      });
      
      const mailOptions = {
        from: process.env.EMAIL_USER,
        to: newPrincipal.email,
        subject: 'Your Principal Account has been created - TEGA Platform',
        html: getPrincipalWelcomeTemplate(newPrincipal.principalName, newPrincipal.email, password)
      };
      await transporter.sendMail(mailOptions);
    } catch (emailError) {

      // Continue even if email fails
    }

    // Prepare response data without sensitive information
    const principalData = {
      _id: newPrincipal._id,
      principalName: newPrincipal.principalName,
      firstName: newPrincipal.firstName,
      lastName: newPrincipal.lastName,
      email: newPrincipal.email,
      university: newPrincipal.university,
      gender: newPrincipal.gender,
      role: newPrincipal.role,
      isActive: newPrincipal.isActive,
      createdAt: newPrincipal.createdAt,
      updatedAt: newPrincipal.updatedAt
    };

    res.status(201).json({
      success: true,
      message: 'Principal registered successfully',
      principal: principalData
    });
  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Server error while creating principal',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Create Student by Admin
router.post('/create-student', adminAuth, async (req, res) => {
  try {
    // Remove studentId from destructuring to prevent manual setting
    const { username, studentName, firstName, lastName, dob, gender, institute, course, major, yearOfStudy, address, landmark, zipcode, city, district, phone, email, password } = req.body;

    // Comprehensive validation - studentId is not required as it will be auto-generated
    const requiredFields = [
      'username', 'studentName', 'firstName', 'lastName', 'dob', 'gender', 'institute', 'course', 'major',
      'yearOfStudy', 'address', 'landmark', 'zipcode', 'city', 'district', 'phone',
      'email', 'password'
    ];
    
    // Validate required fields
    const missingFields = [];
    for (const field of requiredFields) {
      if (!req.body[field]) {
        missingFields.push(field);
      }
    }
    
    if (missingFields.length > 0) {
      return res.status(400).json({ 
        success: false,
        message: `The following fields are required: ${missingFields.join(', ')}` 
      });
    }

    // Password validation
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(password)) {
      return res.status(400).json({
        message: "Password must be at least 8 characters long and include an uppercase letter, a lowercase letter, a number, and a special character."
      });
    }

    // Email validation
    const emailRegex = /\S+@\S+\.\S+/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: "Please provide a valid email address." });
    }

    // Phone validation
    const phoneRegex = /^\d{10}$/;
    if (!phoneRegex.test(phone)) {
      return res.status(400).json({ message: "Phone number must be exactly 10 digits." });
    }

    // Check for uniqueness (only check email and username)
    const query = { $or: [{ email }, { username }] };
    
    const existingStudent = await Student.findOne(query);
    if (existingStudent) {
      let message = 'A student with this information already exists.';
      if (existingStudent.email === email) {
        message = 'A student with this email already exists.';
      } else if (existingStudent.username === username) {
        message = 'A student with this username already exists.';
      }
      return res.status(409).json({ 
        success: false,
        message 
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create the student (studentId will be auto-generated by the pre-save hook)
    const studentData = {
      username,
      studentName,
      firstName,
      lastName,
      dob,
      gender,
      institute,
      course,
      major,
      yearOfStudy,
      address,
      landmark,
      zipcode,
      city,
      district,
      phone,
      email,
      password: hashedPassword,
      role: 'student',
      acceptTerms: true, // Admin accepts terms on behalf of student
      // Explicitly exclude studentId to ensure it's not set
    };
    
    // Create the student with the prepared data
    const newStudent = new Student(studentData);
    
    // Log the student data for debugging

    await newStudent.save();

    // Notify admin
    const notification = new Notification({
      recipient: req.adminId,
      recipientModel: 'Admin',
      message: `You created a new student: ${newStudent.username}`,
      type: 'registration'
    });
    await notification.save();

    // Don't send the password back
    const student = newStudent.toObject();
    delete student.password;

    // Prepare the response data
    const response = {
      success: true,
      message: 'Student created successfully',
      student: {
        _id: student._id,
        studentId: student.studentId, // This will be the auto-generated ID if not provided
        username: student.username,
        studentName: student.studentName,
        firstName: student.firstName,
        lastName: student.lastName,
        email: student.email,
        phone: student.phone,
        institute: student.institute,
        course: student.course,
        major: student.major,
        yearOfStudy: student.yearOfStudy,
        isAutoGeneratedId: student.isAutoGeneratedId,
        createdAt: student.createdAt,
        updatedAt: student.updatedAt
      }
    };

    res.status(201).json(response);

  } catch (error) {

    // Handle specific error types
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(val => val.message);
      return res.status(400).json({ 
        success: false, 
        message: 'Validation error',
        errors: messages,
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
    
    // Handle duplicate key errors
    if (error.code === 11000) {
      const field = Object.keys(error.keyPattern)[0];
      const value = error.keyValue[field];
      return res.status(409).json({
        success: false,
        message: `A student with this ${field} (${value}) already exists.`,
        field,
        value
      });
    }
    
    // Generic error response
    res.status(500).json({ 
      success: false, 
      message: 'Server error while creating student',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Get all notifications for admin
router.get('/notifications', adminAuth, async (req, res) => {
  try {
    const notifications = await Notification.find({ 
      recipientModel: 'Admin',
      recipient: req.adminId 
    }).sort({ createdAt: -1 });

    res.json({ success: true, notifications });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to load notifications' });
  }
});

// Delete a notification
router.delete('/notifications/:notificationId', adminAuth, async (req, res) => {
  try {
    const { notificationId } = req.params;

    const notification = await Notification.findOneAndDelete({
      _id: notificationId,
      recipient: req.adminId, // Ensure the notification belongs to the admin
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found or you do not have permission to delete it.',
      });
    }

    res.json({ success: true, message: 'Notification deleted successfully' });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to delete notification' });
  }
});

// Get payment notifications for admin
router.get('/payment-notifications', adminAuth, async (req, res) => {
  try {

    // Get notifications from both old and new payment systems
    const paymentNotifications = await Notification.find({ 
      $or: [
        { recipientModel: 'Admin', recipient: req.adminId },
        { recipientModel: 'Admin' } // Get all admin notifications
      ],
      $and: [
        {
          $or: [
            { message: { $regex: /payment|UPI|enrolled|razorpay/i } },
            { type: { $in: ['payment_received', 'payment_success', 'payment_update'] } }
          ]
        }
      ]
    }).sort({ createdAt: -1 });

    res.json({ success: true, data: paymentNotifications });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to load payment notifications' });
  }
});

// Get all payments for admin (unified from both Payment and RazorpayPayment models)
router.get('/payments', adminAuth, async (req, res) => {
  try {

    // Get payments from both models (using static imports)
    const [oldPayments, razorpayPayments] = await Promise.all([
      Payment.find()
        .populate('studentId', 'username email firstName lastName')
        .populate('courseId', 'courseName price')
        .sort({ createdAt: -1 }),
      RazorpayPayment.find()
        .populate('studentId', 'username email firstName lastName')
        .populate('courseId', 'courseName price')
        .sort({ createdAt: -1 })
    ]);

    // Debug: Check if we have any payments
    if (oldPayments.length > 0) {

    }
    
    if (razorpayPayments.length > 0) {

    }

    // Normalize both payment types to a common format
    const normalizedOldPayments = oldPayments.map(payment => ({
      _id: payment._id,
      studentId: payment.studentId,
      courseId: payment.courseId,
      courseName: payment.courseName,
      amount: payment.amount,
      currency: payment.currency || 'INR',
      paymentMethod: payment.paymentMethod || 'UPI',
      status: payment.status,
      transactionId: payment.transactionId,
      paymentDate: payment.paymentDate,
      description: payment.description,
      examAccess: payment.examAccess,
      validUntil: payment.validUntil,
      upiId: payment.upiId,
      upiReferenceId: payment.upiReferenceId,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
      source: 'old_payment' // Explicitly set source for old payments
    }));

    const normalizedRazorpayPayments = razorpayPayments.map(payment => ({
      _id: payment._id,
      studentId: payment.studentId,
      courseId: payment.courseId,
      courseName: payment.courseName,
      amount: payment.amount,
      currency: payment.currency || 'INR',
      paymentMethod: 'Razorpay',
      status: payment.status,
      transactionId: payment.transactionId || payment.razorpayPaymentId,
      paymentDate: payment.paymentDate,
      description: payment.description,
      examAccess: payment.examAccess,
      validUntil: payment.validUntil,
      razorpayOrderId: payment.razorpayOrderId,
      razorpayPaymentId: payment.razorpayPaymentId,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
      source: 'razorpay_payment' // Explicitly set source for Razorpay payments
    }));

    // Combine and sort by creation date
    const allPayments = [...normalizedOldPayments, ...normalizedRazorpayPayments]
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));



    // Debug: Log sample payments to see source field
    if (allPayments.length > 0) {

    }

    res.json({ success: true, data: allPayments });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to load payments' });
  }
});

// Course Management Routes
router.post('/courses', adminAuth, async (req, res) => {
  try {
    const { courseName, description, price, duration, category, instructor, level } = req.body;

    // Validation
    if (!courseName || !description || !price || !duration || !category) {
      return res.status(400).json({
        success: false,
        message: 'Course name, description, price, duration, and category are required'
      });
    }

    if (price <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Price must be greater than 0'
      });
    }

    const course = new Course({
      courseName,
      description,
      price,
      duration,
      category,
      instructor,
      level: level || 'Beginner'
    });

    await course.save();

    res.status(201).json({
      success: true,
      message: 'Course created successfully',
      course
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to create course'
    });
  }
});

router.get('/courses', adminAuth, async (req, res) => {
  try {
    const courses = await Course.find().sort({ createdAt: -1 });
    res.json({
      success: true,
      data: courses
    });
  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to load courses'
    });
  }
});

router.get('/courses/:courseId', adminAuth, async (req, res) => {
  try {
    const { courseId } = req.params;
    const course = await Course.findById(courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    res.json({
      success: true,
      course
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to load course'
    });
  }
});

router.put('/courses/:courseId', adminAuth, async (req, res) => {
  try {
    const { courseId } = req.params;
    const updateData = req.body;

    // Remove fields that shouldn't be updated
    delete updateData._id;
    delete updateData.createdAt;
    delete updateData.updatedAt;

    const course = await Course.findByIdAndUpdate(
      courseId,
      updateData,
      { new: true, runValidators: true }
    );

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    res.json({
      success: true,
      message: 'Course updated successfully',
      course
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to update course'
    });
  }
});

router.delete('/courses/:courseId', adminAuth, async (req, res) => {
  try {
    const { courseId } = req.params;
    const course = await Course.findByIdAndDelete(courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    res.json({
      success: true,
      message: 'Course deleted successfully'
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to delete course'
    });
  }
});

// UPI Settings Routes
router.get('/upi-settings', adminAuth, async (req, res) => {
  try {
    let settings = await UPISettings.findOne({ isEnabled: true });
    
    if (!settings) {
      // Create default UPI settings if none exist
      settings = new UPISettings({
        upiId: '9347623445@ybl',
        merchantName: 'TEGA Platform',
        isEnabled: true,
        description: 'TEGA Course Payment',
        supportedApps: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'],
        environment: 'development'
      });
      await settings.save();
    }

    res.json({
      success: true,
      data: settings
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to load UPI settings'
    });
  }
});

router.put('/upi-settings', adminAuth, async (req, res) => {
  try {
    const updateData = req.body;
    
    let settings = await UPISettings.findOne({ isEnabled: true });
    
    if (!settings) {
      // Create new UPI settings if none exist
      settings = new UPISettings(updateData);
    } else {
      // Update existing settings
      Object.assign(settings, updateData);
    }

    await settings.save();

    res.json({
      success: true,
      message: 'UPI settings updated successfully',
      data: settings
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to update UPI settings'
    });
  }
});

export default router;
