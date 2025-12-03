/**
 * M-Pesa API Usage Examples
 * 
 * This file contains examples of how to use the M-Pesa payment endpoints
 * for the ShulePearl payment backend.
 */

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3000/api/payments';
const API_KEY = process.env.API_KEY || 'your-api-key-here';

// Create axios instance with authentication
const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  }
});

/**
 * Example 1: Validate Phone Number
 */
async function validatePhoneNumber(phone) {
  try {
    console.log(`\n=== Validating Phone Number: ${phone} ===`);
    
    const response = await api.post('/validate-phone', { phone });
    
    console.log('✅ Phone number validated:', response.data);
    return response.data.data.formattedPhone;
  } catch (error) {
    console.error('❌ Phone validation failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 2: Initialize Payment (General)
 */
async function initializePayment(email, amount, bookingId) {
  try {
    console.log(`\n=== Initializing Payment: KES ${amount} ===`);
    
    const response = await api.post('/initialize', {
      email,
      amount,
      bookingId,
      metadata: {
        payment_type: 'booking_fee',
        user_id: 'user_12345'
      }
    });
    
    console.log('✅ Payment initialized:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Payment initialization failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 3: Process M-Pesa Payment (Full STK Push)
 */
async function processMpesaPayment(phone, amount, email, bookingId) {
  try {
    console.log(`\n=== Processing M-Pesa Payment: KES ${amount} ===`);
    console.log(`Phone: ${phone}, Email: ${email}`);
    
    const response = await api.post('/mpesa', {
      phone,
      amount,
      email,
      bookingId,
      metadata: {
        payment_type: 'escrow',
        service_type: 'tutoring'
      }
    });
    
    console.log('✅ M-Pesa payment initiated:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ M-Pesa payment failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 4: Direct M-Pesa Payment
 */
async function processDirectMpesa(phone, amount, email, bookingId) {
  try {
    console.log(`\n=== Processing Direct M-Pesa Payment: KES ${amount} ===`);
    
    const response = await api.post('/mpesa/direct', {
      phone,
      amount,
      email,
      bookingId,
      metadata: {
        payment_type: 'booking_fee',
        urgent: true
      }
    });
    
    console.log('✅ Direct M-Pesa payment initiated:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Direct M-Pesa payment failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 5: Verify Payment
 */
async function verifyPayment(reference) {
  try {
    console.log(`\n=== Verifying Payment: ${reference} ===`);
    
    const response = await api.get(`/verify/${reference}`);
    
    console.log('✅ Payment verified:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Payment verification failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 6: Get Payment Status
 */
async function getPaymentStatus(reference) {
  try {
    console.log(`\n=== Getting Payment Status: ${reference} ===`);
    
    const response = await api.get(`/status/${reference}`);
    
    console.log('✅ Payment status:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Get payment status failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 7: Retry Failed Payment
 */
async function retryPayment(reference, newPhone, newEmail) {
  try {
    console.log(`\n=== Retrying Payment: ${reference} ===`);
    
    const response = await api.post(`/retry/${reference}`, {
      phone: newPhone,
      email: newEmail
    });
    
    console.log('✅ Payment retry initiated:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Payment retry failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 8: Cancel Payment
 */
async function cancelPayment(reference, reason) {
  try {
    console.log(`\n=== Canceling Payment: ${reference} ===`);
    
    const response = await api.post(`/cancel/${reference}`, {
      reason
    });
    
    console.log('✅ Payment cancelled:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Payment cancellation failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 9: Get Transaction History
 */
async function getTransactionHistory(userId, limit = 10, status = null) {
  try {
    console.log(`\n=== Getting Transaction History for: ${userId} ===`);
    
    const params = { limit };
    if (status) params.status = status;
    
    const response = await api.get(`/history/${userId}`, { params });
    
    console.log('✅ Transaction history:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Get transaction history failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Example 10: Release Escrow
 */
async function releaseEscrow(bookingId, teacherPhone, amount) {
  try {
    console.log(`\n=== Releasing Escrow: KES ${amount} ===`);
    
    const response = await api.post('/release-escrow', {
      bookingId,
      teacherPhone,
      amount
    });
    
    console.log('✅ Escrow released:', response.data);
    return response.data.data;
  } catch (error) {
    console.error('❌ Escrow release failed:', error.response?.data || error.message);
    throw error;
  }
}

/**
 * Complete Payment Flow Example
 */
async function completePaymentFlow() {
  try {
    console.log('🚀 Starting Complete M-Pesa Payment Flow Example\n');
    
    // Test data
    const testData = {
      phone: '0712345678',
      email: 'test@example.com',
      amount: 500,
      bookingId: `booking_${Date.now()}`,
      userId: 'user_test_123'
    };
    
    // Step 1: Validate phone number
    const formattedPhone = await validatePhoneNumber(testData.phone);
    
    // Step 2: Initialize payment
    const initResult = await initializePayment(
      testData.email, 
      testData.amount, 
      testData.bookingId
    );
    
    // Step 3: Process M-Pesa payment
    const mpesaResult = await processMpesaPayment(
      formattedPhone,
      testData.amount,
      testData.email,
      testData.bookingId
    );
    
    // Step 4: Check payment status
    const status = await getPaymentStatus(mpesaResult.reference);
    
    // Step 5: Get transaction history
    const history = await getTransactionHistory(testData.userId);
    
    console.log('\n✅ Complete payment flow finished successfully!');
    console.log(`Payment Reference: ${mpesaResult.reference}`);
    console.log(`Status: ${status.status}`);
    console.log(`Total Transactions: ${history.total}`);
    
  } catch (error) {
    console.error('\n❌ Payment flow failed:', error.message);
  }
}

/**
 * Error Handling Example
 */
async function errorHandlingExamples() {
  try {
    console.log('\n🔧 Testing Error Handling\n');
    
    // Test invalid phone number
    try {
      await validatePhoneNumber('invalid-phone');
    } catch (error) {
      console.log('✅ Caught invalid phone error:', error.response?.data?.message);
    }
    
    // Test missing required fields
    try {
      await api.post('/mpesa', { phone: '0712345678' }); // Missing amount, email, bookingId
    } catch (error) {
      console.log('✅ Caught missing fields error:', error.response?.data?.message);
    }
    
    // Test non-existent transaction
    try {
      await getPaymentStatus('non-existent-reference');
    } catch (error) {
      console.log('✅ Caught not found error:', error.response?.data?.message);
    }
    
  } catch (error) {
    console.error('Error in error handling examples:', error.message);
  }
}

// Export functions for use in other files
module.exports = {
  validatePhoneNumber,
  initializePayment,
  processMpesaPayment,
  processDirectMpesa,
  verifyPayment,
  getPaymentStatus,
  retryPayment,
  cancelPayment,
  getTransactionHistory,
  releaseEscrow,
  completePaymentFlow,
  errorHandlingExamples
};

// Run examples if this file is executed directly
if (require.main === module) {
  console.log('🧪 Running M-Pesa API Examples\n');
  
  // Uncomment to run specific examples
  // completePaymentFlow();
  // errorHandlingExamples();
  
  console.log('\n📝 Uncomment the desired example functions at the bottom of this file to run them');
}
