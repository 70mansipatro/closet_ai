import crypto from 'crypto';

export const generateOutfitSuggestions = async ({ season, occasion, wardrobeSummary, userStyle }) => {
  const apiKey = process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY;

  if (!apiKey) {
    return [
      {
        name: 'Fallback Smart Outfit',
        description: `A polished ${occasion || 'daily'} outfit for ${season || 'any season'} tailored to ${userStyle || 'your style'}.`,
        items: [],
        aiGenerated: true,
      },
    ];
  }

  const prompt = `Create 3 outfit suggestions for ${occasion || 'a casual event'} in ${season || 'any season'}. Use wardrobe summary: ${wardrobeSummary || 'mixed wardrobe'}. Style preference: ${userStyle || 'versatile'}. Return a JSON array with name, description, and items array of clothing names.`;

  try {
    if (process.env.GEMINI_API_KEY) {
      const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=' + process.env.GEMINI_API_KEY, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
        }),
      });

      const data = await response.json();
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '[]';
      const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());
      return parsed.map((item) => ({ ...item, aiGenerated: true }));
    }

    if (process.env.OPENAI_API_KEY) {
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [{ role: 'system', content: 'You are a stylist.' }, { role: 'user', content: prompt }],
          temperature: 0.7,
        }),
      });

      const data = await response.json();
      const text = data?.choices?.[0]?.message?.content || '[]';
      const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());
      return parsed.map((item) => ({ ...item, aiGenerated: true }));
    }
  } catch (error) {
    console.error('AI generation failed:', error);
  }

  return [
    {
      name: 'Fallback Smart Outfit',
      description: `A polished ${occasion || 'daily'} outfit for ${season || 'any season'}.`,
      items: [],
      aiGenerated: true,
    },
  ];
};

export const createOtp = () => {
  return crypto.randomInt(100000, 999999).toString();
};
