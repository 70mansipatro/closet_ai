import mongoose from 'mongoose';
import { CATEGORY_OPTIONS } from '../constants/clothingOptions.js';

const clothingSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    imageUrl: { type: String, default: '' },
    publicId: { type: String, default: '' },
    // Spec-facing alias of publicId, kept in sync on every write. See the
    // toJSON transform below for the read-side fallback on older documents.
    cloudinaryPublicId: { type: String, default: '' },
    category: {
      type: String,
      required: true,
      enum: CATEGORY_OPTIONS,
      trim: true,
    },
    name: { type: String, default: '', trim: true, maxlength: 120 },
    subCategory: { type: String, default: '', trim: true },
    color: { type: String, default: '', trim: true, maxlength: 50 },
    secondaryColor: { type: String, default: '', trim: true, maxlength: 50 },
    // Spec-facing array alias of secondaryColor.
    secondaryColors: { type: [String], default: [] },
    pattern: { type: String, default: 'solid', trim: true, maxlength: 50 },
    fabric: { type: String, default: 'unknown', trim: true, maxlength: 50 },
    // Spec-facing alias of fabric, kept in sync on every write.
    material: { type: String, default: '', trim: true, maxlength: 50 },
    style: { type: String, default: '', trim: true, maxlength: 50 },
    fit: { type: String, default: '', trim: true, maxlength: 40 },
    brand: { type: String, default: '', trim: true, maxlength: 80 },
    size: { type: String, default: '', trim: true, maxlength: 40 },
    season: {
      type: String,
      enum: ['spring', 'summer', 'autumn', 'winter', 'all-season'],
      default: 'all-season',
      trim: true,
    },
    occasion: { type: String, default: 'casual', trim: true, maxlength: 80 },
    // Spec-facing array alias of occasion.
    occasions: { type: [String], default: [] },
    weatherSuitability: { type: [String], default: [] },
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
    aiAnalysis: {
      analyzed: { type: Boolean, default: false },
      analyzedAt: { type: Date },
      confidence: {
        category: { type: Number },
        color: { type: Number },
        pattern: { type: Number },
        material: { type: Number },
        style: { type: Number },
        season: { type: Number },
      },
    },
  },
  { timestamps: true }
);

clothingSchema.index({ userId: 1, category: 1 });
clothingSchema.index({ userId: 1, favorite: 1 });
clothingSchema.index({ userId: 1, createdAt: -1 });

// Back-fills the spec's new field names from their legacy twins for
// documents written before this field existed, so old wardrobe items render
// correctly in the redesigned UI without a migration script.
const backfillLegacyAliases = (_doc, ret) => {
  ret.material = ret.material || ret.fabric || '';
  ret.cloudinaryPublicId = ret.cloudinaryPublicId || ret.publicId || '';
  ret.secondaryColors =
    Array.isArray(ret.secondaryColors) && ret.secondaryColors.length
      ? ret.secondaryColors
      : ret.secondaryColor
        ? [ret.secondaryColor]
        : [];
  ret.occasions =
    Array.isArray(ret.occasions) && ret.occasions.length
      ? ret.occasions
      : ret.occasion
        ? [ret.occasion]
        : [];
  return ret;
};

clothingSchema.set('toJSON', { transform: backfillLegacyAliases });
clothingSchema.set('toObject', { transform: backfillLegacyAliases });

const Clothing = mongoose.model('Clothing', clothingSchema);
export default Clothing;
