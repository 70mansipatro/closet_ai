import mongoose from 'mongoose';

const laundryHistorySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    clothingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clothing', required: true, index: true },
    previousStatus: { type: String, trim: true, required: true },
    newStatus: { type: String, trim: true, required: true, index: true },
    changedAt: { type: Date, required: true, default: Date.now, index: true },
    method: { type: String, trim: true, default: '' },
    notes: { type: String, default: '', maxlength: 1000 },
  },
  { timestamps: true },
);

laundryHistorySchema.index({ userId: 1, clothingId: 1, changedAt: -1, newStatus: 1 });

const LaundryHistory = mongoose.model('LaundryHistory', laundryHistorySchema);
export default LaundryHistory;
