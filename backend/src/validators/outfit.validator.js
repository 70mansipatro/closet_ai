import Joi from 'joi';

const recommendedItemSchema = Joi.object({
  _id: Joi.alternatives().try(Joi.string(), Joi.object()).required(),
  name: Joi.string().required(),
  category: Joi.string().required(),
});

export const createOutfitSchema = Joi.object({
  occasion: Joi.string().max(80).default('casual'),
  weather: Joi.string().max(40).default('sunny'),
  temperature: Joi.number().min(-30).max(60).default(24),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').default('all-season'),
  recommendedItems: Joi.array().items(recommendedItemSchema).default([]),
  top: Joi.string().allow('', null).max(120).default(''),
  bottom: Joi.string().allow('', null).max(120).default(''),
  footwear: Joi.string().allow('', null).max(120).default(''),
  outerwear: Joi.string().allow('', null).max(120).default(''),
  accessories: Joi.string().allow('', null).max(120).default(''),
  bag: Joi.string().allow('', null).max(120).default(''),
  watch: Joi.string().allow('', null).max(120).default(''),
  confidenceScore: Joi.number().min(0).max(100).default(0),
  reason: Joi.string().max(500).default(''),
  favorite: Joi.boolean().default(false),
  outfitName: Joi.string().allow('', null).max(120).default(''),
  style: Joi.string().allow('', null).max(50).default(''),
  colorPreference: Joi.string().allow('', null).max(50).default(''),
  aiGenerated: Joi.boolean().default(false),
  status: Joi.string().valid('saved', 'worn').default('saved'),
  suggestions: Joi.array().items(Joi.string().max(200)).default([]),
});

export const updateOutfitSchema = Joi.object({
  occasion: Joi.string().max(80).optional(),
  weather: Joi.string().max(40).optional(),
  temperature: Joi.number().min(-30).max(60).optional(),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').optional(),
  recommendedItems: Joi.array().items(recommendedItemSchema).optional(),
  top: Joi.string().allow('', null).max(120).optional(),
  bottom: Joi.string().allow('', null).max(120).optional(),
  footwear: Joi.string().allow('', null).max(120).optional(),
  outerwear: Joi.string().allow('', null).max(120).optional(),
  accessories: Joi.string().allow('', null).max(120).optional(),
  bag: Joi.string().allow('', null).max(120).optional(),
  watch: Joi.string().allow('', null).max(120).optional(),
  confidenceScore: Joi.number().min(0).max(100).optional(),
  reason: Joi.string().max(500).optional(),
  favorite: Joi.boolean().optional(),
  outfitName: Joi.string().allow('', null).max(120).optional(),
  style: Joi.string().allow('', null).max(50).optional(),
  colorPreference: Joi.string().allow('', null).max(50).optional(),
  aiGenerated: Joi.boolean().optional(),
  status: Joi.string().valid('saved', 'worn').optional(),
  suggestions: Joi.array().items(Joi.string().max(200)).optional(),
}).min(1);

export const generateOutfitSchema = Joi.object({
  occasion: Joi.string().max(80).default('casual'),
  weather: Joi.string().max(40).default('sunny'),
  temperature: Joi.number().min(-30).max(60).default(24),
  season: Joi.string().valid('spring', 'summer', 'autumn', 'winter', 'all-season').default('all-season'),
  style: Joi.string().max(50).default('ai'),
  colorPreference: Joi.string().max(50).default('any'),
  favoritesOnly: Joi.boolean().default(false),
  avoidRecentlyWorn: Joi.boolean().default(false),
});
