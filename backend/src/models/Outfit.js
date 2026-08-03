import mongoose from 'mongoose';

const outfitSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    description: { type: String, maxlength: 1000 },
    items: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Clothing', required: true }],
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    occasion: { type: String, trim: true, maxlength: 100 },
    season: {
      type: String,
      enum: ['spring', 'summer', 'autumn', 'winter', 'all-season'],
      default: 'all-season',
    },
    isFavorite: { type: Boolean, default: false },
    aiGenerated: { type: Boolean, default: false },
    imageUrl: { type: String, default: '' },
  },
  { timestamps: true }
);

outfitSchema.index({ owner: 1, occasion: 1 });

const Outfit = mongoose.model('Outfit', outfitSchema);
export default Outfit;
