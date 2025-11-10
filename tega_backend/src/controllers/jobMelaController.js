import SandspaceDrive from '../models/SandspaceDrive.js';
import mongoose from 'mongoose';
import xlsx from 'xlsx';

// Register for job mela
export const registerJobMela = async (req, res) => {
  try {
    const {
      email,
      firstName,
      lastName,
      fatherHusbandName,
      dateOfBirth,
      gender,
      maritalStatus,
      mobile,
      alternateMobile,
      presentAddress,
      permanentAddress,
      sameAddress,
      fatherOccupation,
      education,
      skills
    } = req.body;

    // Validate required fields
    const requiredFields = {
      email,
      firstName,
      lastName,
      fatherHusbandName,
      dateOfBirth,
      gender,
      maritalStatus,
      mobile,
      alternateMobile,
      fatherOccupation
    };

    const missingFields = Object.entries(requiredFields)
      .filter(([key, value]) => {
        if (value === null || value === undefined) return true;
        if (typeof value === 'string' && !value.trim()) return true;
        return false;
      })
      .map(([key]) => key);

    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missingFields.join(', ')}`,
        missingFields
      });
    }

    // Validate address objects
    if (!presentAddress || typeof presentAddress !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Present address is required'
      });
    }

    if (!permanentAddress || typeof permanentAddress !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Permanent address is required'
      });
    }

    const requiredAddressFields = ['doorNoStreet', 'cityVillage', 'district', 'state', 'pinCode'];
    const missingPresentFields = requiredAddressFields.filter(
      field => !presentAddress[field] || !String(presentAddress[field]).trim()
    );
    const missingPermanentFields = requiredAddressFields.filter(
      field => !permanentAddress[field] || !String(permanentAddress[field]).trim()
    );

    if (missingPresentFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing present address fields: ${missingPresentFields.join(', ')}`
      });
    }

    if (missingPermanentFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing permanent address fields: ${missingPermanentFields.join(', ')}`
      });
    }

    // Validate education array
    if (!education || !Array.isArray(education) || education.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one education entry is required'
      });
    }

    // Validate skills array
    if (!skills || !Array.isArray(skills) || skills.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one skill is required'
      });
    }

    // Check for duplicate email
    const existingRegistration = await SandspaceDrive.findOne({ 
      email: email.toLowerCase().trim() 
    });
    if (existingRegistration) {
      return res.status(400).json({
        success: false,
        message: 'This email is already registered. Duplicate registrations are not allowed.'
      });
    }

    // Check for duplicate mobile
    const existingMobile = await SandspaceDrive.findOne({ 
      mobile: String(mobile).trim() 
    });
    if (existingMobile) {
      return res.status(400).json({
        success: false,
        message: 'This mobile number is already registered. Duplicate registrations are not allowed.'
      });
    }

    // Filter out empty education entries
    const validEducation = education
      .filter(edu => {
        if (!edu || !edu.institution || !edu.degree || !edu.startYear) return false;
        const startYear = parseInt(String(edu.startYear).trim());
        return !isNaN(startYear) && startYear > 1900 && startYear <= new Date().getFullYear() + 10;
      })
      .map(edu => {
        const startYear = parseInt(String(edu.startYear).trim());
        const endYear = edu.endYear ? parseInt(String(edu.endYear).trim()) : null;
        const percentage = edu.percentage ? parseFloat(String(edu.percentage).trim()) : null;
        
        return {
          institution: String(edu.institution).trim(),
          degree: String(edu.degree).trim(),
          fieldOfStudy: edu.fieldOfStudy ? String(edu.fieldOfStudy).trim() : '',
          startYear: startYear,
          endYear: (endYear && !isNaN(endYear)) ? endYear : null,
          isCurrent: edu.isCurrent || false,
          percentage: (percentage && !isNaN(percentage)) ? percentage : null,
          description: edu.description ? String(edu.description).trim() : ''
        };
      });

    if (validEducation.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one valid education entry with institution, degree, and start year is required'
      });
    }

    // Filter out empty skills entries
    const validSkills = skills
      .filter(skill => skill && skill.name && String(skill.name).trim())
      .map(skill => ({
        name: String(skill.name).trim(),
        level: skill.level || 'Intermediate'
      }));

    if (validSkills.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one valid skill is required'
      });
    }

    // Create new registration
    const registration = new SandspaceDrive({
      email: email.toLowerCase().trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      fatherHusbandName: fatherHusbandName.trim(),
      dateOfBirth: new Date(dateOfBirth),
      gender,
      maritalStatus,
      mobile: String(mobile).trim(),
      alternateMobile: String(alternateMobile).trim(),
      presentAddress: {
        doorNoStreet: String(presentAddress.doorNoStreet).trim(),
        cityVillage: String(presentAddress.cityVillage).trim(),
        district: String(presentAddress.district).trim(),
        state: String(presentAddress.state).trim(),
        pinCode: String(presentAddress.pinCode).trim()
      },
      permanentAddress: {
        doorNoStreet: String(permanentAddress.doorNoStreet).trim(),
        cityVillage: String(permanentAddress.cityVillage).trim(),
        district: String(permanentAddress.district).trim(),
        state: String(permanentAddress.state).trim(),
        pinCode: String(permanentAddress.pinCode).trim()
      },
      sameAddress: sameAddress || false,
      fatherOccupation: fatherOccupation.trim(),
      education: validEducation,
      skills: validSkills,
      status: 'pending'
    });

    await registration.save();

    res.status(201).json({
      success: true,
      message: 'Registration successful! Your application has been submitted.',
      data: {
        registrationId: registration.registrationId,
        email: registration.email,
        name: `${registration.firstName} ${registration.lastName}`,
        registeredAt: registration.registeredAt
      }
    });
  } catch (error) {
    // Handle duplicate key error
    if (error.code === 11000) {
      const field = Object.keys(error.keyPattern)[0];
      return res.status(400).json({
        success: false,
        message: `This ${field === 'email' ? 'email' : field} is already registered. Duplicate registrations are not allowed.`
      });
    }

    // Handle validation errors
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors,
        details: error.errors
      });
    }

    // Handle custom errors from pre-save hook
    if (error.statusCode === 400) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }

    // Handle type errors (e.g., calling trim on undefined)
    if (error instanceof TypeError) {
      return res.status(400).json({
        success: false,
        message: 'Invalid data format. Please check all required fields are filled correctly.',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error during registration. Please try again later.',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Check if email is already registered
export const checkEmailExists = async (req, res) => {
  try {
    const { email } = req.query;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const existing = await SandspaceDrive.findOne({ email: email.toLowerCase().trim() });
    
    res.json({
      success: true,
      exists: !!existing
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// Check if mobile number is already registered
export const checkMobileExists = async (req, res) => {
  try {
    const { mobile } = req.query;
    
    if (!mobile) {
      return res.status(400).json({
        success: false,
        message: 'Mobile number is required'
      });
    }

    // Validate mobile format (10 digits)
    if (!/^[0-9]{10}$/.test(mobile.trim())) {
      return res.json({
        success: true,
        exists: false // Invalid format, so not a duplicate
      });
    }

    const existing = await SandspaceDrive.findOne({ mobile: mobile.trim() });
    
    res.json({
      success: true,
      exists: !!existing
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// Get all registrations (admin only)
export const getAllRegistrations = async (req, res) => {
  try {
    const { page = 1, limit = 50, status, search } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const query = {};
    if (status) {
      query.status = status;
    }
    if (search) {
      query.$or = [
        { email: { $regex: search, $options: 'i' } },
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { mobile: { $regex: search, $options: 'i' } },
        { registrationId: { $regex: search, $options: 'i' } }
      ];
    }

    const registrations = await SandspaceDrive.find(query)
      .sort({ registeredAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select('-__v');

    const total = await SandspaceDrive.countDocuments(query);

    res.json({
      success: true,
      data: registrations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// Get registration by ID
export const getRegistrationById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Build query - check if it's a valid ObjectId
    const query = mongoose.Types.ObjectId.isValid(id) 
      ? { $or: [{ _id: id }, { registrationId: id }] }
      : { registrationId: id };
    
    const registration = await SandspaceDrive.findOne(query).select('-__v');

    if (!registration) {
      return res.status(404).json({
        success: false,
        message: 'Registration not found'
      });
    }

    res.json({
      success: true,
      data: registration
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// Export registrations to Excel
export const exportRegistrationsToExcel = async (req, res) => {
  try {
    const { status, search } = req.query;

    const query = {};
    if (status) {
      query.status = status;
    }
    if (search) {
      query.$or = [
        { email: { $regex: search, $options: 'i' } },
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { mobile: { $regex: search, $options: 'i' } },
        { registrationId: { $regex: search, $options: 'i' } }
      ];
    }

    // Get all registrations (no pagination for export)
    const registrations = await SandspaceDrive.find(query)
      .sort({ registeredAt: -1 })
      .select('-__v -_id');

    if (registrations.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No registrations found to export'
      });
    }

    // Prepare data for Excel
    const excelData = registrations.map((reg, index) => {
      // Flatten nested objects
      const row = {
        'S.No': index + 1,
        'Registration ID': reg.registrationId || '',
        'First Name': reg.firstName || '',
        'Last Name': reg.lastName || '',
        'Email': reg.email || '',
        'Mobile': reg.mobile || '',
        'Alternate Mobile': reg.alternateMobile || '',
        'Father/Husband Name': reg.fatherHusbandName || '',
        'Date of Birth': reg.dateOfBirth ? new Date(reg.dateOfBirth).toLocaleDateString('en-IN') : '',
        'Gender': reg.gender || '',
        'Marital Status': reg.maritalStatus || '',
        'Father Occupation': reg.fatherOccupation || '',
        // Present Address
        'Present Address - Door No & Street': reg.presentAddress?.doorNoStreet || '',
        'Present Address - City/Village': reg.presentAddress?.cityVillage || '',
        'Present Address - District': reg.presentAddress?.district || '',
        'Present Address - State': reg.presentAddress?.state || '',
        'Present Address - Pin Code': reg.presentAddress?.pinCode || '',
        // Permanent Address
        'Permanent Address - Door No & Street': reg.permanentAddress?.doorNoStreet || '',
        'Permanent Address - City/Village': reg.permanentAddress?.cityVillage || '',
        'Permanent Address - District': reg.permanentAddress?.district || '',
        'Permanent Address - State': reg.permanentAddress?.state || '',
        'Permanent Address - Pin Code': reg.permanentAddress?.pinCode || '',
        'Same as Present Address': reg.sameAddress ? 'Yes' : 'No',
        // Family Members
        'Family Members': reg.familyMembers?.map(m => `${m.name} (${m.relation}, ${m.age} years, ${m.occupation})`).join('; ') || '',
        // Education
        'Education': reg.education?.map(edu => 
          `${edu.degree} from ${edu.institution} (${edu.startYear}${edu.endYear ? '-' + edu.endYear : ''})${edu.percentage ? ' - ' + edu.percentage + '%' : ''}`
        ).join('; ') || '',
        // Skills
        'Primary Skill': reg.skills?.[0]?.name || '',
        'Additional Skills': reg.skills?.slice(1).map(s => `${s.name} (${s.level})`).join('; ') || '',
        // Metadata
        'Status': reg.status || '',
        'Registered At': reg.registeredAt ? new Date(reg.registeredAt).toLocaleString('en-IN') : '',
        'Notes': reg.notes || ''
      };
      return row;
    });

    // Create workbook and worksheet
    const worksheet = xlsx.utils.json_to_sheet(excelData);
    const workbook = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(workbook, worksheet, 'Job Mela Registrations');

    // Set column widths
    const columnWidths = [
      { wch: 6 },   // S.No
      { wch: 20 },  // Registration ID
      { wch: 15 },  // First Name
      { wch: 15 },  // Last Name
      { wch: 25 },  // Email
      { wch: 12 },  // Mobile
      { wch: 12 },  // Alternate Mobile
      { wch: 20 },  // Father/Husband Name
      { wch: 12 },  // Date of Birth
      { wch: 10 },  // Gender
      { wch: 12 },  // Marital Status
      { wch: 20 },  // Father Occupation
      { wch: 25 },  // Present Address fields
      { wch: 15 },
      { wch: 15 },
      { wch: 15 },
      { wch: 10 },
      { wch: 25 },  // Permanent Address fields
      { wch: 15 },
      { wch: 15 },
      { wch: 15 },
      { wch: 10 },
      { wch: 20 },  // Same Address
      { wch: 50 },  // Family Members
      { wch: 60 },  // Education
      { wch: 20 },  // Primary Skill
      { wch: 40 },  // Additional Skills
      { wch: 12 },  // Status
      { wch: 20 },  // Registered At
      { wch: 30 }   // Notes
    ];
    worksheet['!cols'] = columnWidths;

    // Generate Excel file buffer
    const excelBuffer = xlsx.write(workbook, { type: 'buffer', bookType: 'xlsx' });

    // Set response headers
    const filename = `Job_Mela_Registrations_${new Date().toISOString().split('T')[0]}.xlsx`;
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-Length', excelBuffer.length);

    // Send the Excel file
    res.send(excelBuffer);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error during export'
    });
  }
};