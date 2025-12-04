const fs = require('fs');
const path = require('path');

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Log file paths
const logFiles = {
  payments: path.join(logsDir, 'payments.log'),
  webhooks: path.join(logsDir, 'webhooks.log'),
  errors: path.join(logsDir, 'errors.log'),
  performance: path.join(logsDir, 'performance.log'),
  api: path.join(logsDir, 'api.log'),
  firebase: path.join(logsDir, 'firebase.log')
};

// Helper function to get timestamp
const getTimestamp = () => {
  return new Date().toISOString();
};

// Helper function to write to log file
const writeLog = (logFile, message, level = 'INFO') => {
  const timestamp = getTimestamp();
  const logEntry = `[${timestamp}] [${level}] ${message}\n`;
  
  try {
    fs.appendFileSync(logFile, logEntry);
  } catch (error) {
    console.error('Failed to write to log file:', error);
  }
};

// Helper function to write to console with colors
const consoleLog = (message, level = 'INFO') => {
  const colors = {
    INFO: '\x1b[36m',    // Cyan
    SUCCESS: '\x1b[32m', // Green
    WARNING: '\x1b[33m', // Yellow
    ERROR: '\x1b[31m',   // Red
    DEBUG: '\x1b[35m',   // Magenta
    RESET: '\x1b[0m'     // Reset
  };
  
  const color = colors[level] || colors.INFO;
  const timestamp = getTimestamp();
  console.log(`${color}[${timestamp}] [${level}]${colors.RESET} ${message}`);
};

// Main logger object
const logger = {
  // Payment logging
  payment: {
    init: (reference, data) => {
      const message = `PAYMENT_INIT | Ref: ${reference} | Email: ${data.email} | Amount: KES ${data.amount} | Booking: ${data.bookingId}`;
      writeLog(logFiles.payments, message, 'INFO');
      consoleLog(message, 'INFO');
    },
    
    success: (reference, data) => {
      const message = `PAYMENT_SUCCESS | Ref: ${reference} | Amount: KES ${data.amount} | Method: ${data.paymentMethod} | CompletedAt: ${data.completedAt}`;
      writeLog(logFiles.payments, message, 'SUCCESS');
      consoleLog(message, 'SUCCESS');
    },
    
    failed: (reference, error, data) => {
      const message = `PAYMENT_FAILED | Ref: ${reference} | Error: ${error} | Amount: KES ${data.amount || 'N/A'} | Reason: ${data.gateway_response || 'N/A'}`;
      writeLog(logFiles.payments, message, 'ERROR');
      consoleLog(message, 'ERROR');
    },
    
    retry: (originalRef, newRef, retryCount) => {
      const message = `PAYMENT_RETRY | Original: ${originalRef} | New: ${newRef} | RetryCount: ${retryCount}`;
      writeLog(logFiles.payments, message, 'WARNING');
      consoleLog(message, 'WARNING');
    },
    
    cancel: (reference, reason) => {
      const message = `PAYMENT_CANCELLED | Ref: ${reference} | Reason: ${reason}`;
      writeLog(logFiles.payments, message, 'WARNING');
      consoleLog(message, 'WARNING');
    },
    
    status: (reference, status, details = {}) => {
      const message = `PAYMENT_STATUS | Ref: ${reference} | Status: ${status} | Details: ${JSON.stringify(details)}`;
      writeLog(logFiles.payments, message, 'DEBUG');
      consoleLog(message, 'DEBUG');
    }
  },

  // Webhook logging
  webhook: {
    incoming: (event, reference) => {
      const message = `WEBHOOK_INCOMING | Event: ${event} | Ref: ${reference || 'N/A'}`;
      writeLog(logFiles.webhooks, message, 'INFO');
      consoleLog(message, 'INFO');
    },
    
    verified: (event, reference) => {
      const message = `WEBHOOK_VERIFIED | Event: ${event} | Ref: ${reference}`;
      writeLog(logFiles.webhooks, message, 'SUCCESS');
      consoleLog(message, 'SUCCESS');
    },
    
    failed: (event, error) => {
      const message = `WEBHOOK_FAILED | Event: ${event} | Error: ${error}`;
      writeLog(logFiles.webhooks, message, 'ERROR');
      consoleLog(message, 'ERROR');
    },
    
    processed: (event, reference, action) => {
      const message = `WEBHOOK_PROCESSED | Event: ${event} | Ref: ${reference} | Action: ${action}`;
      writeLog(logFiles.webhooks, message, 'SUCCESS');
      consoleLog(message, 'SUCCESS');
    },
    
    signatureError: (reason) => {
      const message = `WEBHOOK_SIGNATURE_ERROR | Reason: ${reason}`;
      writeLog(logFiles.webhooks, message, 'ERROR');
      consoleLog(message, 'ERROR');
    }
  },

  // API logging
  api: {
    request: (method, endpoint, ip, userAgent) => {
      const message = `API_REQUEST | Method: ${method} | Endpoint: ${endpoint} | IP: ${ip} | UA: ${userAgent}`;
      writeLog(logFiles.api, message, 'INFO');
      consoleLog(message, 'INFO');
    },
    
    response: (method, endpoint, statusCode, responseTime) => {
      const message = `API_RESPONSE | Method: ${method} | Endpoint: ${endpoint} | Status: ${statusCode} | Time: ${responseTime}ms`;
      writeLog(logFiles.api, message, 'INFO');
      consoleLog(message, 'INFO');
    },
    
    error: (method, endpoint, error, statusCode) => {
      const message = `API_ERROR | Method: ${method} | Endpoint: ${endpoint} | Error: ${error} | Status: ${statusCode}`;
      writeLog(logFiles.api, message, 'ERROR');
      consoleLog(message, 'ERROR');
    }
  },

  // Firebase logging
  firebase: {
    write: (collection, document, operation) => {
      const message = `FIREBASE_WRITE | Collection: ${collection} | Doc: ${document} | Operation: ${operation}`;
      writeLog(logFiles.firebase, message, 'DEBUG');
      consoleLog(message, 'DEBUG');
    },
    
    read: (collection, document) => {
      const message = `FIREBASE_READ | Collection: ${collection} | Doc: ${document}`;
      writeLog(logFiles.firebase, message, 'DEBUG');
      consoleLog(message, 'DEBUG');
    },
    
    error: (operation, error) => {
      const message = `FIREBASE_ERROR | Operation: ${operation} | Error: ${error}`;
      writeLog(logFiles.firebase, message, 'ERROR');
      consoleLog(message, 'ERROR');
    }
  },

  // Performance logging
  performance: {
    timing: (operation, duration, details = {}) => {
      const message = `PERFORMANCE | Operation: ${operation} | Duration: ${duration}ms | Details: ${JSON.stringify(details)}`;
      writeLog(logFiles.performance, message, 'INFO');
      
      // Log warning if slow
      if (duration > 1000) {
        consoleLog(`SLOW_OPERATION: ${operation} took ${duration}ms`, 'WARNING');
      }
    },
    
    memory: (operation, memoryUsage) => {
      const message = `MEMORY | Operation: ${operation} | Usage: ${JSON.stringify(memoryUsage)}`;
      writeLog(logFiles.performance, message, 'DEBUG');
    }
  },

  // Error logging
  error: (error, context = {}) => {
    const message = `ERROR | Message: ${error.message} | Stack: ${error.stack} | Context: ${JSON.stringify(context)}`;
    writeLog(logFiles.errors, message, 'ERROR');
    consoleLog(message, 'ERROR');
  },

  // General logging
  info: (message) => {
    writeLog(logFiles.api, message, 'INFO');
    consoleLog(message, 'INFO');
  },

  success: (message) => {
    writeLog(logFiles.api, message, 'SUCCESS');
    consoleLog(message, 'SUCCESS');
  },

  warning: (message) => {
    writeLog(logFiles.api, message, 'WARNING');
    consoleLog(message, 'WARNING');
  },

  debug: (message) => {
    writeLog(logFiles.api, message, 'DEBUG');
    consoleLog(message, 'DEBUG');
  },

  // Log rotation helper
  rotateLogs: () => {
    const maxSize = 10 * 1024 * 1024; // 10MB
    
    Object.values(logFiles).forEach(logFile => {
      try {
        const stats = fs.statSync(logFile);
        if (stats.size > maxSize) {
          const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
          const backupFile = logFile.replace('.log', `_${timestamp}.log`);
          fs.renameSync(logFile, backupFile);
          writeLog(logFile, 'Log rotated', 'INFO');
        }
      } catch (error) {
        // File doesn't exist or can't be accessed
      }
    });
  }
};

// Log rotation every hour
setInterval(logger.rotateLogs, 60 * 60 * 1000);

module.exports = logger;
