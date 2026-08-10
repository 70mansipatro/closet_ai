import mongoose from 'mongoose';

const packingListSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    tripId: { type: mongoose.Schema.Types.ObjectId, ref: 'Trip', required: true, index: true },
    category: {
      type: String,
      required: true,
      enum: ['Clothes', 'Shoes', 'Accessories', 'Electronics', 'Documents', 'Toiletries', 'Medicines', 'Other'],
      default: 'Other',
      trim: true,
    },
    name: { type: String, required: true, trim: true, maxlength: 200 },
    clothingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Clothing' },
    quantity: { type: Number, default: 1, min: 1 },
    packed: { type: Boolean, default: false },
    required: { type: Boolean, default: true },
    reason: { type: String, trim: true, maxlength: 1000, default: '' },
  },
  { timestamps: true }
);

packingListSchema.index({ userId: 1, tripId: 1, category: 1 });
packingListSchema.index({ tripId: 1, packed: 1 });

const PackingList = mongoose.model('PackingList', packingListSchema);
export default PackingList;
