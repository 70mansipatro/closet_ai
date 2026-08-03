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
    gender: { type: String, enum: ['male', 'female', 'other', 'prefer-not-to-say'], default: 'prefer-not-to-say' },
    height: { type: Number, default: 0 },
    weight: { type: Number, default: 0 },
    preferredStyle: { type: String, default: 'casual' },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    isVerified: { type: Boolean, default: false },
    refreshToken: { type: String, default: '' },
    otp: { type: String, default: '' },
    otpExpiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

const User = mongoose.model('User', userSchema);
export default User;
