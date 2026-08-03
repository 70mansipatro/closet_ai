import mongoose from 'mongoose';

const clothingSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    category: {
      type: String,
      required: true,
      enum: ['top', 'bottom', 'dress', 'outerwear', 'shoes', 'accessory', 'other'],
    },
    color: { type: String, trim: true, maxlength: 50 },
    season: {
      type: String,
      enum: ['spring', 'summer', 'autumn', 'winter', 'all-season'],
      default: 'all-season',
    },
    occasion: { type: String, trim: true, maxlength: 100 },
    imageUrl: { type: String, required: true },
    publicId: { type: String, default: '' },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    tags: [{ type: String, trim: true }],
    isFavorite: { type: Boolean, default: false },
    notes: { type: String, maxlength: 1000 },
  },
  { timestamps: true }
);

clothingSchema.index({ owner: 1, category: 1 });
clothingSchema.index({ owner: 1, isFavorite: 1 });

const Clothing = mongoose.model('Clothing', clothingSchema);
export default Clothing;
