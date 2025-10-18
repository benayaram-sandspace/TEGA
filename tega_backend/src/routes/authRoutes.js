import express from "express";
import { 
  register, 
  login, 
  logout,
  verifyAuth,
  refreshToken,
  getCSRFToken
} from "../controllers/authController.js";

const router = express.Router();

// Public routes
router.post("/register", register);
router.post("/login", login);
router.post("/logout", logout);
router.get("/verify", verifyAuth);
router.post("/refresh", refreshToken);
router.get("/csrf-token", getCSRFToken);

// GET /api/auth/test
router.get("/test", (req, res) => {
  res.send("Auth routes working 🚀");
});

export default router;
