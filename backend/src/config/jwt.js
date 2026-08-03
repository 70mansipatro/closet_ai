export const jwtConfig = {
  accessTokenSecret: process.env.JWT_SECRET || 'dev-access-secret',
  refreshTokenSecret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret',
  accessTokenExpiry: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  refreshTokenExpiry: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
};
