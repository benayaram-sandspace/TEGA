const express = require("express");
const router = express.Router();
const { check } = require("express-validator");
const { registerUser, loginUser } = require("../controllers/authController");

const registerValidation = [
  check("firstName", "First name is required").not().isEmpty(),
  check("lastName", "Last name is required").not().isEmpty(),
  check("email", "Please include a valid email").isEmail(),
  check("password", "Password must be at least 6 characters").isLength({
    min: 6,
  }),
];

const loginValidation = [
  check("email", "Please include a valid email").isEmail(),
  check("password", "Password is required").exists(),
];

router.post("/register", registerValidation, registerUser);
router.post("/login", loginValidation, loginUser);

module.exports = router;
