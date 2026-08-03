import mongoose from 'mongoose';

const tripSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 100 },
    destination: { type: String, required: true, trim: true, maxlength: 100 },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    packingList: [
      {
        item: { type: String, required: true, trim: true },
        packed: { type: Boolean, default: false },
        category: { type: String, trim: true, default: 'other' },
      },
    ],
    notes: { type: String, maxlength: 2000 },
  },
  { timestamps: true }
);

tripSchema.index({ owner: 1, startDate: 1 });

const Trip = mongoose.model('Trip', tripSchema);
export default Trip;
