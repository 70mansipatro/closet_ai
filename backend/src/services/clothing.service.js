import { AppError } from '../utils/appError.js';

const allowedCategories = [
  'top',
  'bottom',
  'dress',
  'outerwear',
  'shoes',
  'accessory',
  'other',
];

const allowedSeasons = ['spring', 'summer', 'autumn', 'winter', 'all-season'];
const allowedLaundryStatuses = ['clean', 'in-use', 'dirty', 'washing', 'repair'];

const normalizePayload = (payload = {}) => {
  const normalized = { ...payload };

  if (normalized.purchasePrice !== undefined && normalized.purchasePrice !== '') {
    normalized.purchasePrice = Number(normalized.purchasePrice);
  }

  if (normalized.wearCount !== undefined && normalized.wearCount !== '') {
    normalized.wearCount = Number(normalized.wearCount);
  }

  if (normalized.favorite !== undefined) {
    normalized.favorite = normalized.favorite === true || normalized.favorite === 'true';
  }

  if (normalized.purchaseDate) {
    normalized.purchaseDate = new Date(normalized.purchaseDate);
  }

  if (normalized.lastWorn) {
    normalized.lastWorn = new Date(normalized.lastWorn);
  }

  if (normalized.category) {
    normalized.category = normalized.category.toString().trim().toLowerCase();
    if (!allowedCategories.includes(normalized.category)) {
      throw new AppError('Invalid category', 400);
    }
  }

  if (normalized.season) {
    normalized.season = normalized.season.toString().trim().toLowerCase();
    if (!allowedSeasons.includes(normalized.season)) {
      throw new AppError('Invalid season', 400);
    }
  }

  if (normalized.laundryStatus) {
    normalized.laundryStatus = normalized.laundryStatus.toString().trim().toLowerCase();
    if (!allowedLaundryStatuses.includes(normalized.laundryStatus)) {
      throw new AppError('Invalid laundry status', 400);
    }
  }

  return normalized;
};

export const parseJsonFromText = (text = '') => {
  const raw = typeof text === 'string' ? text : '';
  let cleaned = raw.replace(/```(?:json)?/gi, '').trim();
  const fencedMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fencedMatch?.[1]) {
    cleaned = fencedMatch[1].trim();
  }

  try {
    return JSON.parse(cleaned);
  } catch (error) {
    const match = cleaned.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        return JSON.parse(match[0]);
      } catch (nestedError) {
        throw new AppError(`Failed to parse AI response JSON: ${nestedError.message}`, 502, {
          rawText: cleaned,
          parseError: nestedError.message,
        });
      }
    }

    throw new AppError(`Failed to parse AI response JSON: ${error.message}`, 502, {
      rawText: cleaned,
      parseError: error.message,
    });
  }
};

export const normalizeAnalysis = (analysis = {}) => ({
  category: typeof analysis.category === 'string' && analysis.category.trim() ? analysis.category.trim() : 'other',
  subCategory: typeof analysis.subCategory === 'string' ? analysis.subCategory.trim() : '',
  color: typeof analysis.color === 'string' && analysis.color.trim() ? analysis.color.trim() : 'neutral',
  secondaryColor: typeof analysis.secondaryColor === 'string' ? analysis.secondaryColor.trim() : '',
  pattern: typeof analysis.pattern === 'string' && analysis.pattern.trim() ? analysis.pattern.trim() : 'solid',
  fabric: typeof analysis.fabric === 'string' && analysis.fabric.trim() ? analysis.fabric.trim() : 'unknown',
  brand: typeof analysis.brand === 'string' ? analysis.brand.trim() : '',
  season: typeof analysis.season === 'string' && analysis.season.trim() ? analysis.season.trim() : 'all-season',
  occasion: typeof analysis.occasion === 'string' && analysis.occasion.trim() ? analysis.occasion.trim() : 'casual',
});

const buildGeminiRequestBody = (prompt, buffer) => ({
  contents: [
    {
      parts: [
        { text: prompt },
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: buffer.toString('base64'),
          },
        },
      ],
    },
  ],
});

const validateGeminiModel = (model) => {
  if (typeof model !== 'string' || model.trim().length === 0) {
    throw new AppError('Gemini model is not configured', 500, { model });
  }
  if (!/^gemini-[A-Za-z0-9._-]+$/.test(model)) {
    throw new AppError(`Invalid Gemini model configured: ${model}`, 500, { model });
  }
};

export const validateAnalysisConfig = (env = process.env) => {
  const requiredKeys = [
    'GEMINI_API_KEY',
    'CLOUDINARY_CLOUD_NAME',
    'CLOUDINARY_API_KEY',
    'CLOUDINARY_API_SECRET',
    'JWT_SECRET',
  ];

  const missing = requiredKeys.filter((key) => !String(env[key] ?? '').trim());

  return {
    isValid: missing.length === 0,
    missing,
  };
};

const extractGeminiText = (responseData) => {
  const candidates = Array.isArray(responseData?.candidates) ? responseData.candidates : [];
  for (const candidate of candidates) {
    const parts = Array.isArray(candidate?.content?.parts) ? candidate.content.parts : [];
    for (const part of parts) {
      if (typeof part?.text === 'string' && part.text.trim()) {
        return part.text;
      }
    }

    const combinedText = parts.map((part) => part?.text ?? '').join('').trim();
    if (combinedText) {
      return combinedText;
    }
  }

  return null;
};

export const analyzeClothingImage = async (buffer) => {
  const config = validateAnalysisConfig(process.env);
  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash';

  console.log('[AI ANALYZE] Starting clothing analysis', {
    config,
    apiKeyLoaded: !!apiKey,
    model,
    bufferSize: buffer?.length ?? 0,
  });

  if (!config.isValid) {
    throw new AppError('Missing required configuration for AI analysis', 500, { missing: config.missing });
  }

  if (!apiKey) {
    throw new AppError('Gemini API key is not configured. Set GEMINI_API_KEY in .env', 500);
  }

  validateGeminiModel(model);

  const prompt = [
    'Analyze the clothing image and return strict JSON only.',
    'Required fields: category, subCategory, color, secondaryColor, pattern, fabric, brand, season, occasion.',
    'Use short values and no markdown.',
  ].join(' ');

  const requestBody = buildGeminiRequestBody(prompt, buffer);
  const requestUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  console.log('[AI GEMINI REQUEST] Built request', {
    url: requestUrl,
    model,
    apiKeyLoaded: !!apiKey,
    bodySize: Buffer.byteLength(JSON.stringify(requestBody)),
    requestPreview: {
      prompt: prompt.slice(0, 256),
      imageInlineDataPrefix: requestBody.contents[0].parts[1].inlineData.data.slice(0, 128),
      imageInlineDataLength: requestBody.contents[0].parts[1].inlineData.data.length,
    },
  });

  const response = await fetch(requestUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  const rawResponseText = await response.text();
  console.log('[AI GEMINI RESPONSE] Raw response', {
    url: requestUrl,
    status: response.status,
    statusText: response.statusText,
    rawResponseText: rawResponseText.slice(0, 2000),
    rawResponseLength: rawResponseText.length,
  });
  let data;

  try {
    data = JSON.parse(rawResponseText);
  } catch (parseError) {
    console.error('[AI GEMINI RESPONSE] Invalid JSON response', {
      status: response.status,
      statusText: response.statusText,
      rawResponseText,
      parseError: parseError.message,
    });
    throw new AppError(`Gemini response was not valid JSON: ${parseError.message}`, 502, {
      rawResponseText,
    });
  }

  console.log('[AI GEMINI RESPONSE] Received response', {
    status: response.status,
    statusText: response.statusText,
    rawResponseData: data,
  });

  if (!response.ok) {
    const errorMessage = data?.error?.message || data?.message || `Gemini request failed with status ${response.status}`;
    const errorDetails = {
      status: response.status,
      statusText: response.statusText,
      rawResponseData: data,
      requestUrl,
      model,
    };
    console.error('[AI GEMINI RESPONSE] Non-OK status', errorDetails);
    throw new AppError(errorMessage, 502, errorDetails);
  }

  const text = extractGeminiText(data);
  if (!text || typeof text !== 'string') {
    throw new AppError('Gemini response missing text content', 502, { rawResponseData: data });
  }

  console.log('[AI GEMINI RESPONSE TEXT] Output text preview', { textPreview: text.slice(0, 1024) });

  const parsedAnalysis = parseJsonFromText(text);
  const normalizedAnalysis = normalizeAnalysis(parsedAnalysis);

  console.log('[AI ANALYSIS] Parsed and normalized analysis', normalizedAnalysis);

  return normalizedAnalysis;
};

export const buildClothingPayload = async ({ payload, imageUrl = '', publicId = '', userId, aiAnalysis = {} }) => {
  const normalized = normalizePayload(payload);

  return {
    userId,
    imageUrl,
    publicId,
    category: normalized.category || aiAnalysis.category || 'other',
    subCategory: normalized.subCategory || aiAnalysis.subCategory || '',
    color: normalized.color || aiAnalysis.color || '',
    secondaryColor: normalized.secondaryColor || aiAnalysis.secondaryColor || '',
    pattern: normalized.pattern || aiAnalysis.pattern || 'solid',
    fabric: normalized.fabric || aiAnalysis.fabric || 'unknown',
    brand: normalized.brand || aiAnalysis.brand || '',
    size: normalized.size || '',
    season: normalized.season || aiAnalysis.season || 'all-season',
    occasion: normalized.occasion || aiAnalysis.occasion || 'casual',
    purchaseDate: normalized.purchaseDate || undefined,
    purchasePrice: normalized.purchasePrice || 0,
    favorite: normalized.favorite ?? false,
    laundryStatus: normalized.laundryStatus || 'clean',
    wearCount: normalized.wearCount || 0,
    lastWorn: normalized.lastWorn || undefined,
    notes: normalized.notes || '',
  };
};
