const mongoose = require("mongoose");

const collegeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  location: {
    type: String,
    trim: true,
  },
});

const College = mongoose.model("College", collegeSchema);
module.exports = College;
