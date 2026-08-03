import Clothing from '../models/Clothing.js';
import User from '../models/User.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.service.js';
import { createClothingSchema, updateClothingSchema } from '../validators/clothing.validator.js';

export const createClothing = async (req, res, next) => {
  try {
    const { error, value } = createClothingSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    let imageUrl = '';
    let publicId = '';

    if (req.file) {
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'closetai/clothing');
      imageUrl = uploadResult.secure_url;
      publicId = uploadResult.public_id;
    }

    const clothing = await Clothing.create({ ...value, owner: req.user._id, imageUrl, publicId });
    res.status(201).json(clothing);
  } catch (error) {
    next(error);
  }
};

export const listClothing = async (req, res, next) => {
  try {
    const clothing = await Clothing.find({ owner: req.user._id }).sort({ createdAt: -1 });
    res.json(clothing);
  } catch (error) {
    next(error);
  }
};

export const getClothing = async (req, res, next) => {
  try {
    const clothing = await Clothing.findOne({ _id: req.params.id, owner: req.user._id });
    if (!clothing) return res.status(404).json({ message: 'Clothing item not found' });
    res.json(clothing);
  } catch (error) {
    next(error);
  }
};

export const updateClothing = async (req, res, next) => {
  try {
    const { error, value } = updateClothingSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const clothing = await Clothing.findOne({ _id: req.params.id, owner: req.user._id });
    if (!clothing) return res.status(404).json({ message: 'Clothing item not found' });

    if (req.file) {
      if (clothing.publicId) await deleteFromCloudinary(clothing.publicId);
      const uploadResult = await uploadToCloudinary(req.file.buffer, 'closetai/clothing');
      value.imageUrl = uploadResult.secure_url;
      value.publicId = uploadResult.public_id;
    }

    Object.assign(clothing, value);
    await clothing.save();
    res.json(clothing);
  } catch (error) {
    next(error);
  }
};

export const deleteClothing = async (req, res, next) => {
  try {
    const clothing = await Clothing.findOne({ _id: req.params.id, owner: req.user._id });
    if (!clothing) return res.status(404).json({ message: 'Clothing item not found' });

    if (clothing.publicId) await deleteFromCloudinary(clothing.publicId);
    await clothing.deleteOne();
    res.json({ message: 'Clothing item deleted successfully' });
  } catch (error) {
    next(error);
  }
};

export const toggleFavoriteClothing = async (req, res, next) => {
  try {
    const clothing = await Clothing.findOne({ _id: req.params.id, owner: req.user._id });
    if (!clothing) return res.status(404).json({ message: 'Clothing item not found' });

    clothing.isFavorite = !clothing.isFavorite;
    await clothing.save();

    const user = await User.findById(req.user._id);
    if (clothing.isFavorite) {
      if (!user.favorites.includes(clothing._id)) user.favorites.push(clothing._id);
    } else {
      user.favorites = user.favorites.filter((id) => id.toString() !== clothing._id.toString());
    }
    await user.save();

    res.json({ clothing, message: clothing.isFavorite ? 'Added to favorites' : 'Removed from favorites' });
  } catch (error) {
    next(error);
  }
};
