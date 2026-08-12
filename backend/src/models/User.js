import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, minlength: 2, maxlength: 80 },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^.+@.+\..+$/, 'Please enter a valid email'],
    },
    phone: { type: String, trim: true, default: '' },
    password: { type: String, required: true, minlength: 6 },
    profileImage: { type: String, default: '' },
    profileImagePublicId: { type: String, default: '' },
    gender: { type: String, enum: ['male', 'female', 'other', 'prefer-not-to-say'], default: 'prefer-not-to-say' },
    height: { type: Number, default: 0 },
    weight: { type: Number, default: 0 },
    preferredStyle: { type: String, default: 'casual' },
    role: { type: String, enum: ['user', 'admin', 'super_admin'], default: 'user', index: true },
    status: { type: String, enum: ['active', 'suspended', 'inactive'], default: 'active', index: true },
    lastLoginAt: { type: Date, default: null },
    isVerified: { type: Boolean, default: false },
    subscriptionStatus: { type: String, enum: ['free', 'active', 'expired', 'cancelled', 'past_due'], default: 'free' },
    subscriptionPlan: { type: String, default: 'free' },
    subscriptionStartDate: { type: Date, default: null },
    subscriptionEndDate: { type: Date, default: null },
    autoRenew: { type: Boolean, default: false },
    paymentProvider: { type: String, default: '' },
    paymentCustomerId: { type: String, default: '' },
    subscriptionId: { type: String, default: '' },
    refreshToken: { type: String, default: '' },
    otp: { type: String, default: '' },
    otpExpiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }

  console.log('[USER MODEL] hashing password for user', { email: this.email });
  this.password = await bcrypt.hash(this.password, 12);
  console.log('[USER MODEL] password hashed successfully', { email: this.email });
  next();
});

userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

userSchema.index({ createdAt: -1 });

const User = mongoose.model('User', userSchema);
export default User;
