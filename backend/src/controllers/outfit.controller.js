import Outfit from '../models/Outfit.js';
import Clothing from '../models/Clothing.js';
import { createOutfitSchema, updateOutfitSchema } from '../validators/outfit.validator.js';
import { generateOutfitSuggestions } from '../services/ai.service.js';

export const createOutfit = async (req, res, next) => {
  try {
    const { error, value } = createOutfitSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const outfit = await Outfit.create({ ...value, owner: req.user._id });
    res.status(201).json(outfit);
  } catch (error) {
    next(error);
  }
};

export const listOutfits = async (req, res, next) => {
  try {
    const outfits = await Outfit.find({ owner: req.user._id }).populate('items').sort({ createdAt: -1 });
    res.json(outfits);
  } catch (error) {
    next(error);
  }
};

export const getOutfit = async (req, res, next) => {
  try {
    const outfit = await Outfit.findOne({ _id: req.params.id, owner: req.user._id }).populate('items');
    if (!outfit) return res.status(404).json({ message: 'Outfit not found' });
    res.json(outfit);
  } catch (error) {
    next(error);
  }
};

export const updateOutfit = async (req, res, next) => {
  try {
    const { error, value } = updateOutfitSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const outfit = await Outfit.findOne({ _id: req.params.id, owner: req.user._id });
    if (!outfit) return res.status(404).json({ message: 'Outfit not found' });

    Object.assign(outfit, value);
    await outfit.save();
    res.json(outfit);
  } catch (error) {
    next(error);
  }
};

export const deleteOutfit = async (req, res, next) => {
  try {
    const outfit = await Outfit.findOne({ _id: req.params.id, owner: req.user._id });
    if (!outfit) return res.status(404).json({ message: 'Outfit not found' });

    await outfit.deleteOne();
    res.json({ message: 'Outfit deleted successfully' });
  } catch (error) {
    next(error);
  }
};

export const aiGenerateOutfits = async (req, res, next) => {
  try {
    const { season, occasion, userStyle } = req.body;
    const wardrobe = await Clothing.find({ owner: req.user._id }).lean();
    const wardrobeSummary = wardrobe.map((item) => `${item.category}:${item.color || 'none'}`).join(', ');
    const suggestions = await generateOutfitSuggestions({ season, occasion, wardrobeSummary, userStyle });
    res.json({ suggestions });
  } catch (error) {
    next(error);
  }
};
