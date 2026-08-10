import { AppError } from '../utils/appError.js';

const WEATHER_CACHE = new Map();
const CACHE_TTL_MS = 1000 * 60 * 30;
const normalizeCity = (value) => (value ?? '').toString().trim();

const buildCacheKey = ({ city, country, startDate, endDate }) =>
  `${normalizeCity(city).toLowerCase()}|${(country ?? '').toString().trim().toLowerCase()}|${startDate?.toISOString() || ''}|${endDate?.toISOString() || ''}`;

const fetchWeatherFromProvider = async ({ city, country, startDate, endDate }) => {
  const apiKey = process.env.WEATHER_API_KEY;
  if (!apiKey) {
    throw new AppError('Weather API key is not configured', 500);
  }

  const queryParts = [city || '', country || ''].filter(Boolean).join(',');
  const url = `https://api.openweathermap.org/data/2.5/forecast?q=${encodeURIComponent(queryParts)}&units=metric&appid=${apiKey}`;
  const response = await fetch(url, { timeout: 10000 });
  if (!response.ok) {
    const body = await response.text();
    throw new AppError(`Weather provider returned ${response.status}: ${body}`, 502);
  }

  const data = await response.json();
  if (!data || !Array.isArray(data.list)) {
    throw new AppError('Invalid weather response from provider', 502);
  }

  const weatherByDate = new Map();
  const dates = [];
  const from = new Date(startDate);
  const to = new Date(endDate);

  for (let d = new Date(from); d <= to; d.setDate(d.getDate() + 1)) {
    dates.push(new Date(d));
  }

  for (const entry of data.list) {
    const entryDate = new Date(entry.dt * 1000);
    const dateKey = entryDate.toISOString().slice(0, 10);
    if (!weatherByDate.has(dateKey)) {
      weatherByDate.set(dateKey, []);
    }
    weatherByDate.get(dateKey).push(entry);
  }

  const forecast = [];
  for (const date of dates) {
    const key = date.toISOString().slice(0, 10);
    const dayEntries = weatherByDate.get(key) || [];
    const estimated = dayEntries.length === 0;

    if (dayEntries.length === 0) {
      forecast.push({
        date: date.toISOString(),
        estimated: true,
        condition: 'Unknown',
        temperature: null,
        feelsLike: null,
        humidity: null,
        windSpeed: null,
        rainProbability: null,
      });
      continue;
    }

    const temperatures = dayEntries.map((entry) => entry.main?.temp).filter((t) => typeof t === 'number');
    const feelsLikes = dayEntries.map((entry) => entry.main?.feels_like).filter((t) => typeof t === 'number');
    const humidities = dayEntries.map((entry) => entry.main?.humidity).filter((t) => typeof t === 'number');
    const windSpeeds = dayEntries.map((entry) => entry.wind?.speed).filter((t) => typeof t === 'number');
    const rainProbability = Math.round(
      (dayEntries.filter((entry) => entry.pop >= 0).reduce((sum, entry) => sum + (entry.pop || 0), 0) / dayEntries.length) * 100,
    );
    const conditions = dayEntries.map((entry) => entry.weather?.[0]?.main || 'Unknown');

    forecast.push({
      date: date.toISOString(),
      estimated,
      condition: conditions[0] || 'Unknown',
      temperature: temperatures.length ? Math.round(temperatures.reduce((sum, value) => sum + value, 0) / temperatures.length) : null,
      feelsLike: feelsLikes.length ? Math.round(feelsLikes.reduce((sum, value) => sum + value, 0) / feelsLikes.length) : null,
      humidity: humidities.length ? Math.round(humidities.reduce((sum, value) => sum + value, 0) / humidities.length) : null,
      windSpeed: windSpeeds.length ? Math.round(windSpeeds.reduce((sum, value) => sum + value, 0) / windSpeeds.length) : null,
      rainProbability: Number.isFinite(rainProbability) ? rainProbability : null,
    });
  }

  return {
    city,
    country,
    startDate: from.toISOString(),
    endDate: to.toISOString(),
    forecast,
  };
};

export const getWeather = async ({ city, country, startDate, endDate }) => {
  if (!city || !startDate || !endDate) {
    throw new AppError('city, startDate and endDate are required', 400);
  }

  const from = new Date(startDate);
  const to = new Date(endDate);
  if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
    throw new AppError('Invalid date format', 400);
  }

  const cacheKey = buildCacheKey({ city, country, startDate: from, endDate: to });
  const cached = WEATHER_CACHE.get(cacheKey);
  if (cached && Date.now() - cached.createdAt < CACHE_TTL_MS) {
    return cached.data;
  }

  const weather = await fetchWeatherFromProvider({ city, country, startDate: from, endDate: to });
  WEATHER_CACHE.set(cacheKey, { createdAt: Date.now(), data: weather });
  return weather;
};
