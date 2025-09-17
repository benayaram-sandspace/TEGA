// src/routes/userRoutes.js
const express = require("express");
const router = express.Router();
const { getUserProfile } = require("../controllers/userController");
const { protect } = require("../middleware/authMiddleware");

// This route is protected by the 'protect' middleware
router.get("/profile", protect, getUserProfile);

module.exports = router;
