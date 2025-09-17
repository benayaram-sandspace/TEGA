const College = require("../models/collegeModel");

const getColleges = async (req, res) => {
  try {
    const colleges = await College.find({}).sort({ name: 1 });
    res.json(colleges);
  } catch (error) {
    console.error("Error fetching colleges:", error);
    res.status(500).json({ message: "Server Error" });
  }
};

module.exports = {
  getColleges,
};
