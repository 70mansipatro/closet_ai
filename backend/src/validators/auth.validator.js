import Joi from 'joi';

export const registerSchema = Joi.object({
  name: Joi.string().min(2).max(80).required(),
  email: Joi.string().email().required(),
  phone: Joi.string().allow('').optional(),
  password: Joi.string().min(6).required(),
  gender: Joi.string().valid('male', 'female', 'other', 'prefer-not-to-say').optional(),
  height: Joi.number().min(0).allow(null).optional(),
  weight: Joi.number().min(0).allow(null).optional(),
  preferredStyle: Joi.string().max(40).optional(),
  role: Joi.string().valid('user', 'admin').optional(),
});

export const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

export const refreshSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

export const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().required(),
});

export const verifyOtpSchema = Joi.object({
  email: Joi.string().email().required(),
  otp: Joi.string().length(6).required(),
});

export const resetPasswordSchema = Joi.object({
  email: Joi.string().email().required(),
  otp: Joi.string().length(6).required(),
  password: Joi.string().min(6).required(),
});

export const profileUpdateSchema = Joi.object({
  name: Joi.string().min(2).max(80).optional(),
  phone: Joi.string().allow('').optional(),
  gender: Joi.string().valid('male', 'female', 'other', 'prefer-not-to-say').optional(),
  height: Joi.number().min(0).optional(),
  weight: Joi.number().min(0).optional(),
  preferredStyle: Joi.string().max(40).optional(),
  profileImage: Joi.string().allow('').optional(),
});
