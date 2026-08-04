import jwt from 'jsonwebtoken';
import RefreshToken from '../models/RefreshToken.js';
import { jwtConfig } from '../config/jwt.js';
import { createOtp } from '../services/ai.service.js';
import { sendOtpEmail } from '../services/email.service.js';
import {
  registerSchema,
  loginSchema,
  refreshSchema,
  forgotPasswordSchema,
  verifyOtpSchema,
  resetPasswordSchema,
  profileUpdateSchema,
} from '../validators/auth.validator.js';
import { createUser, findUserByEmail, findUserById, updateUserProfile, deleteUserById } from '../repositories/user.repository.js';
import { AppError } from '../utils/appError.js';

export const signTokens = async (user) => {
  console.log('[AUTH JWT] creating tokens for user', { userId: user?._id, email: user?.email });
  const accessToken = jwt.sign({ userId: user._id, role: user.role }, jwtConfig.accessTokenSecret, { expiresIn: jwtConfig.accessTokenExpiry });
  const refreshToken = jwt.sign({ userId: user._id }, jwtConfig.refreshTokenSecret, { expiresIn: jwtConfig.refreshTokenExpiry });

  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  const refreshRecord = await RefreshToken.create({ user: user._id, token: refreshToken, expiresAt });
  console.log('[AUTH JWT] refresh token stored in MongoDB', { refreshTokenId: refreshRecord?._id, userId: user?._id });

  return { accessToken, refreshToken };
};

const sanitizeUser = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone || '',
  profileImage: user.profileImage || '',
  gender: user.gender || 'prefer-not-to-say',
  height: user.height || 0,
  weight: user.weight || 0,
  preferredStyle: user.preferredStyle || 'casual',
  role: user.role,
  isVerified: user.isVerified || false,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

export const registerUser = async (req, res, next) => {
  try {
    console.log('[AUTH REGISTER] Incoming Register Request');
    console.log('[AUTH REGISTER] headers', req.headers);
    console.log('[AUTH REGISTER] body', req.body);

    const payload = {
      ...req.body,
      phone: req.body.phone ?? undefined,
      gender: req.body.gender ?? undefined,
      height: req.body.height == null ? undefined : req.body.height,
      weight: req.body.weight == null ? undefined : req.body.weight,
      preferredStyle: req.body.preferredStyle ?? undefined,
      role: req.body.role ?? undefined,
    };

    const { error, value } = registerSchema.validate(payload, { abortEarly: false, stripUnknown: true });
    console.log('[AUTH REGISTER] validation result', {
      hasError: Boolean(error),
      details: error?.details || null,
      sanitizedValue: value
        ? {
            name: value.name,
            email: value.email,
            passwordLength: value.password?.length || 0,
          }
        : null,
    });

    if (error) {
      const messages = error.details.map((detail) => detail.message).join(', ');
      console.warn('[AUTH REGISTER] validation failed', {
        body: req.body,
        details: error.details,
      });
      throw new AppError(messages, 400);
    }

    const existing = await findUserByEmail(value.email);
    console.log('[AUTH REGISTER] existing user lookup result', { found: Boolean(existing), email: value.email });
    if (existing) {
      console.warn('[AUTH REGISTER] duplicate email', { email: value.email });
      throw new AppError('Email already registered', 409);
    }

    const user = await createUser({ ...value, email: value.email.toLowerCase() });
    console.log('[AUTH REGISTER] MongoDB create result', { userId: user?._id, email: user?.email });

    const tokens = await signTokens(user);
    console.log('[AUTH REGISTER] JWT creation complete', { userId: user?._id });

    res.status(201).json({ success: true, user: sanitizeUser(user), ...tokens });
  } catch (error) {
    console.error('[AUTH REGISTER] registration failed', {
      email: req.body?.email,
      message: error.message,
      stack: error.stack,
    });
    next(error);
  }
};

export const loginUser = async (req, res, next) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const user = await findUserByEmail(value.email);
    if (!user) throw new AppError('Invalid credentials', 401);

    const isMatch = await user.comparePassword(value.password);
    if (!isMatch) throw new AppError('Invalid credentials', 401);

    const tokens = await signTokens(user);
    res.json({ user: sanitizeUser(user), ...tokens });
  } catch (error) {
    next(error);
  }
};

export const refreshAccessToken = async (req, res, next) => {
  try {
    const { error, value } = refreshSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const decoded = jwt.verify(value.refreshToken, jwtConfig.refreshTokenSecret);
    const stored = await RefreshToken.findOne({ token: value.refreshToken, revoked: false });

    if (!stored || stored.expiresAt < new Date()) {
      throw new AppError('Invalid refresh token', 401);
    }

    const user = await findUserById(decoded.userId, '-password');
    if (!user) throw new AppError('User not found', 401);

    const tokens = await signTokens(user);
    res.json({ user: sanitizeUser(user), ...tokens });
  } catch (error) {
    next(error);
  }
};

export const logoutUser = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await RefreshToken.deleteMany({ token: refreshToken });
    }
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    next(error);
  }
};

export const forgotPassword = async (req, res, next) => {
  try {
    const { error, value } = forgotPasswordSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const user = await findUserByEmail(value.email);
    if (!user) throw new AppError('User not found', 404);

    const otp = createOtp();
    user.otp = otp;
    user.otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    await sendOtpEmail(user.email, otp);
    res.json({ message: 'OTP sent to your email' });
  } catch (error) {
    next(error);
  }
};

export const verifyOtp = async (req, res, next) => {
  try {
    const { error, value } = verifyOtpSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const user = await findUserByEmail(value.email);
    if (!user || user.otp !== value.otp || !user.otpExpiresAt || user.otpExpiresAt < new Date()) {
      throw new AppError('Invalid or expired OTP', 400);
    }

    user.isVerified = true;
    user.otp = '';
    user.otpExpiresAt = null;
    await user.save();

    res.json({ message: 'OTP verified successfully' });
  } catch (error) {
    next(error);
  }
};

export const resetPassword = async (req, res, next) => {
  try {
    const { error, value } = resetPasswordSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const user = await findUserByEmail(value.email);
    if (!user || user.otp !== value.otp || !user.otpExpiresAt || user.otpExpiresAt < new Date()) {
      throw new AppError('Invalid or expired OTP', 400);
    }

    user.password = value.password;
    user.otp = '';
    user.otpExpiresAt = null;
    await user.save();

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    next(error);
  }
};

export const getProfile = async (req, res, next) => {
  try {
    res.json({ user: sanitizeUser(req.user) });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const { error, value } = profileUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const user = await updateUserProfile(req.user._id, value);
    res.json({ user: sanitizeUser(user) });
  } catch (error) {
    next(error);
  }
};

export const deleteAccount = async (req, res, next) => {
  try {
    await deleteUserById(req.user._id);
    await RefreshToken.deleteMany({ user: req.user._id });
    res.status(200).json({ message: 'Account deleted successfully' });
  } catch (error) {
    next(error);
  }
};
