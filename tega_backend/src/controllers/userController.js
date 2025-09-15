const User = require("../models/userModel");
const Student = require("../models/studentModel");

const getUserProfile = async (req, res) => {
  if (!req.user) {
    return res.status(404).json({ message: "User not found" });
  }

  // If the user is a student, find their detailed profile
  if (req.user.role === "user") {
    const studentProfile = await Student.findOne({ user: req.user._id });

    if (studentProfile) {
      // Combine and send data
      res.json({
        _id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        phone: req.user.phone,
        role: req.user.role,
        college: studentProfile.college,
        course: studentProfile.course,
        year: studentProfile.year_of_study,
        // you can add more fields from the student profile here
      });
    } else {
      res.status(404).json({ message: "Student profile not found" });
    }
  } else {
    // For admins or moderators, just send back the basic user info
    res.json({
      _id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      phone: req.user.phone,
      role: req.user.role,
    });
  }
};

module.exports = {
  getUserProfile,
};
