import { AppError } from '../utils/appError.js';
import { getWeather } from '../services/weather.service.js';

export const getWeatherHandler = async (req, res, next) => {
  try {
    const { city, country, startDate, endDate } = req.query;
    if (!city || !startDate || !endDate) {
      throw new AppError('city, startDate and endDate are required', 400);
    }

    const weather = await getWeather({
      city: city.toString(),
      country: country?.toString(),
      startDate: new Date(startDate.toString()),
      endDate: new Date(endDate.toString()),
    });

    res.status(200).json({ success: true, data: weather });
  } catch (error) {
    next(error);
  }
};
