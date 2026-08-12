const isPlainObject = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

const sanitizeValue = (value) => {
  if (Array.isArray(value)) {
    return value.map(sanitizeValue);
  }

  if (isPlainObject(value)) {
    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => !key.startsWith('$') && !key.includes('.'))
        .map(([key, val]) => [key, sanitizeValue(val)])
    );
  }

  return value;
};

/**
 * Strips MongoDB operator keys ($gt, $where, ...) and dotted keys from
 * req.body/query/params to prevent NoSQL query injection. Written by hand
 * instead of using express-mongo-sanitize/hpp because both packages mutate
 * req.query in place, which Express 5's getter-based req.query recomputes
 * from the raw URL on every access — their mutations are silently discarded.
 */
export const sanitizeRequest = (req, res, next) => {
  if (req.body) {
    req.body = sanitizeValue(req.body);
  }

  if (req.params) {
    req.params = sanitizeValue(req.params);
  }

  Object.defineProperty(req, 'query', {
    configurable: true,
    enumerable: true,
    writable: true,
    value: sanitizeValue(req.query),
  });

  next();
};
