import mongoose from 'mongoose';

const outfitSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    occasion: { type: String, trim: true, maxlength: 80, default: 'casual' },
    weather: { type: String, trim: true, maxlength: 40, default: 'sunny' },
    temperature: { type: Number, default: 24 },
    season: {
      type: String,
      enum: ['spring', 'summer', 'autumn', 'winter', 'all-season'],
      default: 'all-season',
      trim: true,
    },
    recommendedItems: [
      {
        _id: { type: String, trim: true, required: true },
        name: { type: String, trim: true, required: true },
        category: { type: String, trim: true, required: true },
      },
    ],
    top: { type: String, trim: true, default: '' },
    bottom: { type: String, trim: true, default: '' },
    footwear: { type: String, trim: true, default: '' },
    outerwear: { type: String, trim: true, default: '' },
    accessories: { type: String, trim: true, default: '' },
    bag: { type: String, trim: true, default: '' },
    watch: { type: String, trim: true, default: '' },
    confidenceScore: { type: Number, default: 0 },
    reason: { type: String, trim: true, default: '' },
    favorite: { type: Boolean, default: false },
  },
  { timestamps: true }
);

outfitSchema.index({ userId: 1, createdAt: -1 });

const Outfit = mongoose.model('Outfit', outfitSchema);
export default Outfit;
