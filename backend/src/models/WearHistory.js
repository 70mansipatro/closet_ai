import mongoose from 'mongoose';

const wearHistorySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    clothingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clothing', required: true, index: true },
    outfitId: { type: mongoose.Schema.Types.ObjectId, ref: 'Outfit' },
    date: { type: Date, required: true, index: true },
    occasion: { type: String, trim: true, maxlength: 80, default: '' },
    weather: { type: String, trim: true, maxlength: 40, default: '' },
    rating: { type: Number, min: 0, max: 5 },
    favorite: { type: Boolean, default: false },
    notes: { type: String, default: '', maxlength: 1000 },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

wearHistorySchema.index({ userId: 1, clothingId: 1, date: 1 });

const WearHistory = mongoose.model('WearHistory', wearHistorySchema);
export default WearHistory;
