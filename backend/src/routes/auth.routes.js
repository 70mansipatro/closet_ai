import express from 'express';
import { protect } from '../middleware/auth.js';
import {
  registerUser,
  loginUser,
  refreshAccessToken,
  logoutUser,
  forgotPassword,
  verifyOtp,
  resetPassword,
  getProfile,
  updateProfile,
  deleteAccount,
} from '../controllers/auth.controller.js';

const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/refresh', refreshAccessToken);
router.post('/logout', protect, logoutUser);
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);
router.delete('/delete-account', protect, deleteAccount);

export default router;
