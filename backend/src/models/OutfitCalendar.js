import mongoose from 'mongoose';

const outfitCalendarSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    date: { type: Date, required: true, index: true },
    outfitId: { type: mongoose.Schema.Types.ObjectId, ref: 'Outfit' },
    topId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clothing' },
    bottomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clothing' },
    footwearId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clothing' },
    outerwearId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clothing' },
    accessories: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Clothing' }],
    notes: { type: String, default: '', maxlength: 1000 },
    time: { type: String, trim: true, maxlength: 20, default: '' },
    occasion: { type: String, trim: true, maxlength: 80, default: 'casual' },
    weather: { type: String, trim: true, maxlength: 40, default: 'sunny' },
    temperature: { type: Number, default: 24 },
    status: { type: String, enum: ['Planned', 'Worn', 'Skipped'], default: 'Planned' },
  },
  { timestamps: true }
);

outfitCalendarSchema.index({ userId: 1, date: 1 });

const OutfitCalendar = mongoose.model('OutfitCalendar', outfitCalendarSchema);
export default OutfitCalendar;
