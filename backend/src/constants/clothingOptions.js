// Controlled vocabularies shared by the clothing validator (user input) and
// the AI normalizer (Gemini output) so both sides agree on the same values.

export const CATEGORY_OPTIONS = [
  'top',
  'bottom',
  'dress',
  'outerwear',
  'shoes',
  'accessory',
  'activewear',
  'innerwear',
  'other',
];

// Maps loose/AI-returned category words (and the spec's "Footwear" label)
// onto the stored enum values above. Anything not listed here that also
// isn't already a valid CATEGORY_OPTIONS value normalizes to null.
export const CATEGORY_ALIASES = {
  tops: 'top',
  bottoms: 'bottom',
  dresses: 'dress',
  footwear: 'shoes',
  footwears: 'shoes',
  shoe: 'shoes',
  sneakers: 'shoes',
  jacket: 'outerwear',
  coat: 'outerwear',
  outerwears: 'outerwear',
  accessories: 'accessory',
  activewears: 'activewear',
  sportswear: 'activewear',
  innerwears: 'innerwear',
  underwear: 'innerwear',
};

export const SEASON_OPTIONS = ['spring', 'summer', 'autumn', 'winter', 'all-season'];

export const SEASON_ALIASES = {
  fall: 'autumn',
  allseason: 'all-season',
  'all season': 'all-season',
};

export const STYLE_OPTIONS = [
  'casual',
  'formal',
  'party',
  'sporty',
  'streetwear',
  'traditional',
  'business',
  'minimal',
  'elegant',
  'ethnic',
];

export const PATTERN_OPTIONS = [
  'solid',
  'striped',
  'checked',
  'floral',
  'printed',
  'polka-dot',
  'geometric',
  'abstract',
  'embroidered',
  'other',
];

export const PATTERN_ALIASES = {
  'polka dot': 'polka-dot',
  polkadot: 'polka-dot',
  plain: 'solid',
};

export const MATERIAL_OPTIONS = [
  'cotton',
  'denim',
  'linen',
  'silk',
  'wool',
  'polyester',
  'leather',
  'rayon',
  'chiffon',
  'velvet',
  'other',
  'unknown',
];

export const OCCASION_OPTIONS = [
  'casual',
  'office',
  'party',
  'wedding',
  'travel',
  'workout',
  'date',
  'festival',
  'formal',
  'daily-wear',
];

export const OCCASION_ALIASES = {
  'daily wear': 'daily-wear',
  dailywear: 'daily-wear',
  everyday: 'daily-wear',
};

export const WEATHER_OPTIONS = ['hot', 'warm', 'mild', 'cool', 'cold', 'rainy'];

export const FIT_OPTIONS = ['slim', 'regular', 'relaxed', 'oversized', 'not-set'];

export const FIT_ALIASES = {
  'not set': 'not-set',
  notset: 'not-set',
  loose: 'relaxed',
};

export const COLOR_OPTIONS = [
  'black',
  'white',
  'red',
  'blue',
  'green',
  'yellow',
  'pink',
  'purple',
  'orange',
  'brown',
  'grey',
  'beige',
  'multi-color',
  'other',
];

export const SIZE_OPTIONS = ['xs', 's', 'm', 'l', 'xl', 'xxl', 'custom', 'not-set'];

export const LAUNDRY_STATUS_OPTIONS = [
  'clean',
  'dirty',
  'washing',
  'drying',
  'ironing',
  'ready',
  'in-use',
  'repair',
];

/**
 * Case/whitespace-insensitive lookup against an options list, using an
 * optional alias map for common synonyms. Returns null when nothing matches
 * instead of guessing, so callers can decide the appropriate fallback.
 */
export const normalizeEnumValue = (value, options, aliases = {}) => {
  if (typeof value !== 'string') return null;
  const key = value.trim().toLowerCase();
  if (!key) return null;
  if (options.includes(key)) return key;
  if (aliases[key]) return aliases[key];
  return null;
};

/**
 * Normalizes a list of loose strings against an options list, dropping
 * anything unrecognized and de-duplicating. Never throws.
 */
export const normalizeEnumList = (values, options, aliases = {}) => {
  if (!Array.isArray(values)) return [];
  const normalized = values
    .map((value) => normalizeEnumValue(value, options, aliases))
    .filter((value) => Boolean(value));
  return [...new Set(normalized)];
};
