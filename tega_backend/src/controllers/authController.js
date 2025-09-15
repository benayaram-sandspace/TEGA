import User from "../models/userModel.js";
import Student from "../models/studentModel.js";
import jwt from "jsonwebtoken";
import { validationResult } from "express-validator";

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: "30d",
  });
};

const registerUser = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: "Validation errors occurred",
      errors: errors.array(),
    });
  }

  const { firstName, lastName, email, phone, password, course, year, college } =
    req.body;

  try {
    const userExists = await User.findOne({ email: email.toLowerCase() });

    if (userExists) {
      return res.status(400).json({
        success: false,
        message: "User already exists with this email address",
      });
    }

    if (!firstName || !lastName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "First name, last name, email, and password are required",
      });
    }

    const user = await User.create({
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.toLowerCase().trim(),
      phone: phone?.trim() || null,
      password: password,
      role: "user",
    });

    if (user) {
      if (user.role === "user") {
        const studentData = {
          user: user._id,
          college: college?.trim() || "Not Provided",
          course: course?.trim() || "Not Provided",
          year_of_study: year?.toString().trim() || "Not Provided",
        };

        try {
          const student = await Student.create(studentData);
          console.log("Student profile created:", student);
        } catch (studentError) {
          console.error("Error creating student profile:", studentError);
        }
      }

      // Return success response with the corrected structure
      return res.status(201).json({
        success: true,
        message: "Account created successfully! Welcome to TEGA.",
        token: generateToken(user._id), // CHANGED: Token is now at the top level
        user: {
          id: user._id, // CHANGED: Field name is now 'id' instead of '_id' for consistency
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          role: user.role,
        },
      });
    } else {
      return res.status(400).json({
        success: false,
        message: "Failed to create user account. Please try again.",
      });
    }
  } catch (error) {
    console.error("REGISTRATION ERROR:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "An account with this email already exists",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Server error occurred. Please try again later.",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
    });
  }
};

const loginUser = async (req, res) => {
  const { email, password } = req.body;

  try {
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });

    if (user && (await user.matchPassword(password))) {
      let studentProfile = null;
      if (user.role === "user") {
        try {
          studentProfile = await Student.findOne({ user: user._id });
        } catch (studentError) {
          console.error("Error fetching student profile:", studentError);
        }
      }

      return res.status(200).json({
        success: true,
        message: "Login successful",
        token: generateToken(user._id), // CHANGED: Token is now at the top level
        user: {
          id: user._id, // CHANGED: Field name is now 'id' instead of '_id' for consistency
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          role: user.role,
          ...(studentProfile && {
            college: studentProfile.college,
            course: studentProfile.course,
            yearOfStudy: studentProfile.year_of_study,
          }),
        },
      });
    } else {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }
  } catch (error) {
    console.error("LOGIN ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Server error occurred. Please try again later.",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
    });
  }
};

const getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    let response = {
      success: true,
      user: {
        id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        role: user.role,
      },
    };

    if (user.role === "user") {
      const studentProfile = await Student.findOne({ user: user._id });
      if (studentProfile) {
        response.user.college = studentProfile.college;
        response.user.course = studentProfile.course;
        response.user.yearOfStudy = studentProfile.year_of_study;
      }
    }

    return res.status(200).json(response);
  } catch (error) {
    console.error("GET PROFILE ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Server error occurred",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
    });
  }
};

const updateUserProfile = async (req, res) => {
  try {
    const { firstName, lastName, college, course, year } = req.body;

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (firstName) user.firstName = firstName.trim();
    if (lastName) user.lastName = lastName.trim();

    await user.save();

    if (user.role === "user") {
      const updateData = {};
      if (college) updateData.college = college.trim();
      if (course) updateData.course = course.trim();
      if (year) updateData.year_of_study = year.toString().trim();

      if (Object.keys(updateData).length > 0) {
        await Student.findOneAndUpdate({ user: user._id }, updateData, {
          upsert: true,
          new: true,
        });
      }
    }

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
    });
  } catch (error) {
    console.error("UPDATE PROFILE ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Server error occurred",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
    });
  }
};

export { registerUser, loginUser, getUserProfile, updateUserProfile };
