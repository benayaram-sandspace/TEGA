import express from "express";
import { 
  register, 
  login, 
  forgotPassword, 
  verifyOTP, 
  resetPassword, 
  sendRegistrationOTP, 
  verifyRegistrationOTP,
  refreshToken,
  checkEmailAvailability 
} from "../controllers/authController.js";

const router = express.Router();

// POST /api/auth/register
router.post("/register", register);

// POST /api/auth/check-email
router.post("/check-email", checkEmailAvailability);

// POST /api/auth/register/send-otp
router.post("/register/send-otp", sendRegistrationOTP);

// POST /api/auth/register/verify-otp
router.post("/register/verify-otp", verifyRegistrationOTP);

// POST /api/auth/login
router.post("/login", login);

// POST /api/auth/forgot-password
router.post("/forgot-password", forgotPassword);

// POST /api/auth/verify-otp
router.post("/verify-otp", verifyOTP);

// POST /api/auth/reset-password
router.post("/reset-password", resetPassword);

// POST /api/auth/refresh-token
router.post("/refresh-token", refreshToken);

// GET /api/auth/test
router.get("/test", (req, res) => {
  res.send("Auth routes working 🚀");
});

export default router;
