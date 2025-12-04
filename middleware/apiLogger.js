const logger = require('../utils/logger');

/**
 * API Request/Response Logging Middleware
 */
const apiLogger = (req, res, next) => {
  const startTime = Date.now();
  
  // Log incoming request
  logger.api.request(
    req.method,
    req.originalUrl,
    req.ip || 'unknown',
    req.get('User-Agent') || 'unknown'
  );

  // Store original res.end to capture response
  const originalEnd = res.end;
  res.end = function(chunk, encoding) {
    const responseTime = Date.now() - startTime;
    
    // Log response
    if (res.statusCode >= 400) {
      logger.api.error(
        req.method,
        req.originalUrl,
        `HTTP ${res.statusCode}`,
        res.statusCode
      );
    } else {
      logger.api.response(
        req.method,
        req.originalUrl,
        res.statusCode,
        responseTime
      );
    }
    
    // Log performance for slow requests
    if (responseTime > 1000) {
      logger.performance.timing(
        'api_request',
        responseTime,
        {
          method: req.method,
          url: req.originalUrl,
          statusCode: res.statusCode
        }
      );
    }
    
    originalEnd.call(this, chunk, encoding);
  };

  next();
};

module.exports = apiLogger;
