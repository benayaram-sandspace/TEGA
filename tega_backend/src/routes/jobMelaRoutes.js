import express from 'express';
import { 
  registerJobMela, 
  checkEmailExists,
  checkMobileExists,
  getAllRegistrations,
  getRegistrationById,
  exportRegistrationsToExcel
} from '../controllers/jobMelaController.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Public routes
router.post('/register', registerJobMela);
router.get('/check-email', checkEmailExists);
router.get('/check-mobile', checkMobileExists);

// Admin routes
router.get('/registrations', adminAuth, getAllRegistrations);
router.get('/registrations/:id', adminAuth, getRegistrationById);
router.get('/export-excel', adminAuth, exportRegistrationsToExcel);

export default router;

