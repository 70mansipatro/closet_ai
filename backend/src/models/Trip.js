import mongoose from 'mongoose';

const tripSchema = new mongoose.Schema(
  {
    tripName: { type: String, required: true, trim: true, maxlength: 100, alias: 'title' },
    destination: { type: String, required: true, trim: true, maxlength: 100 },
    country: { type: String, required: true, trim: true, maxlength: 100 },
    city: { type: String, required: true, trim: true, maxlength: 100 },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    activities: { type: [String], default: [] },
    notes: { type: String, maxlength: 2000, default: '' },
    weatherSummary: { type: String, maxlength: 500, default: '' },
    averageTemperature: { type: Number, default: null },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
      alias: 'userId',
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

tripSchema.index({ owner: 1, startDate: 1 });
tripSchema.index({ tripName: 'text', destination: 'text', country: 'text', city: 'text', activities: 'text' });

const Trip = mongoose.model('Trip', tripSchema);
export default Trip;
