import mongoose from 'mongoose';

const clothingSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    imageUrl: { type: String, default: '' },
    publicId: { type: String, default: '' },
    category: {
      type: String,
      required: true,
      enum: ['top', 'bottom', 'dress', 'outerwear', 'shoes', 'accessory', 'other'],
      trim: true,
    },
    subCategory: { type: String, default: '', trim: true },
    color: { type: String, default: '', trim: true, maxlength: 50 },
    secondaryColor: { type: String, default: '', trim: true, maxlength: 50 },
    pattern: { type: String, default: 'solid', trim: true, maxlength: 50 },
    fabric: { type: String, default: 'unknown', trim: true, maxlength: 50 },
    brand: { type: String, default: '', trim: true, maxlength: 80 },
    size: { type: String, default: '', trim: true, maxlength: 40 },
    season: {
      type: String,
      enum: ['spring', 'summer', 'autumn', 'winter', 'all-season'],
      default: 'all-season',
      trim: true,
    },
    occasion: { type: String, default: 'casual', trim: true, maxlength: 80 },
    purchaseDate: { type: Date },
    purchasePrice: { type: Number, default: 0 },
    favorite: { type: Boolean, default: false },
    laundryStatus: {
      type: String,
      enum: ['clean', 'dirty', 'washing', 'drying', 'ironing', 'ready', 'in-use', 'repair'],
      default: 'clean',
      trim: true,
    },
    lastWashedAt: { type: Date },
    nextWashDueAt: { type: Date },
    laundryCount: { type: Number, default: 0 },
    dryCleaningRequired: { type: Boolean, default: false },
    laundryNotes: { type: String, default: '', maxlength: 1000 },
    wearCount: { type: Number, default: 0 },
    lastWorn: { type: Date },
    notes: { type: String, default: '', maxlength: 1000 },
  },
  { timestamps: true }
);

clothingSchema.index({ userId: 1, category: 1 });
clothingSchema.index({ userId: 1, favorite: 1 });
clothingSchema.index({ userId: 1, createdAt: -1 });

const Clothing = mongoose.model('Clothing', clothingSchema);
export default Clothing;
