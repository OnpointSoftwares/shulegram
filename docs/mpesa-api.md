# M-Pesa Payment API Documentation

## Overview
This API handles M-Pesa payments through Paystack integration for the ShulePearl platform. All endpoints are protected with API key authentication except the webhook endpoint.

## Base URL
```
https://your-domain.com/api/payments
```

## Authentication
All endpoints (except webhook) require an API key in the headers:
```
Authorization: Bearer YOUR_API_KEY
```

## Endpoints

### 1. Initialize Payment
**POST** `/initialize`

Initialize a payment transaction (supports both card and M-Pesa).

**Request Body:**
```json
{
  "email": "user@example.com",
  "amount": 1000,
  "bookingId": "booking_123",
  "metadata": {
    "payment_type": "booking_fee",
    "user_id": "user_456"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment initialized successfully",
  "data": {
    "reference": "booking_abc123",
    "access_code": "xyz789",
    "authorization_url": "https://checkout.paystack.com/xyz789"
  }
}
```

### 2. Process M-Pesa Payment (Full STK Push)
**POST** `/mpesa`

Process M-Pesa payment with STK push prompt.

**Request Body:**
```json
{
  "phone": "0712345678",
  "amount": 1000,
  "email": "user@example.com",
  "bookingId": "booking_123",
  "metadata": {
    "payment_type": "escrow"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "MPesa STK push sent. Please check your phone to complete payment.",
  "data": {
    "reference": "mpesa_abc123",
    "status": "pending",
    "display_text": "Check your phone for payment prompt"
  }
}
```

### 3. Direct M-Pesa Payment
**POST** `/mpesa/direct`

Direct M-Pesa charge without initialization step.

**Request Body:**
```json
{
  "phone": "254712345678",
  "amount": 1000,
  "email": "user@example.com",
  "bookingId": "booking_123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "MPesa payment initiated. Check your phone for the prompt.",
  "data": {
    "reference": "mpesa_direct_123",
    "status": "pending",
    "display_text": "Enter your MPesa PIN to complete"
  }
}
```

### 4. Verify Payment
**GET** `/verify/:reference`

Verify the status of a payment transaction.

**Response:**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "data": {
    "status": "success",
    "amount": 1000,
    "reference": "booking_abc123",
    "paid_at": "2025-01-20T10:30:00Z",
    "channel": "mobile_money"
  }
}
```

### 5. Get Payment Status
**GET** `/status/:reference`

Get detailed status of a transaction from Firebase.

**Response:**
```json
{
  "success": true,
  "data": {
    "reference": "mpesa_abc123",
    "bookingId": "booking_123",
    "email": "user@example.com",
    "phone": "254712345678",
    "amount": 1000,
    "status": "success",
    "paymentMethod": "mpesa",
    "createdAt": 1642678200000,
    "completedAt": 1642678800000
  }
}
```

### 6. Retry Failed Payment
**POST** `/retry/:reference`

Retry a failed payment transaction.

**Request Body:**
```json
{
  "phone": "0712345678",
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment retry initiated",
  "data": {
    "originalReference": "mpesa_failed_123",
    "newReference": "retry_mpesa_456",
    "retryCount": 1
  }
}
```

### 7. Cancel Payment
**POST** `/cancel/:reference`

Cancel a pending payment transaction.

**Request Body:**
```json
{
  "reason": "User requested cancellation"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment cancelled successfully",
  "data": {
    "reference": "mpesa_abc123",
    "cancelledAt": 1642678200000
  }
}
```

### 8. Get Transaction History
**GET** `/history/:userId`

Get payment transaction history for a user.

**Query Parameters:**
- `limit` (optional): Number of transactions to return (default: 50)
- `offset` (optional): Number of transactions to skip (default: 0)
- `status` (optional): Filter by transaction status

**Response:**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "reference": "mpesa_abc123",
        "amount": 1000,
        "status": "success",
        "createdAt": 1642678200000
      }
    ],
    "total": 25,
    "limit": 50,
    "offset": 0
  }
}
```

### 9. Validate Phone Number
**POST** `/validate-phone`

Validate and format M-Pesa phone number.

**Request Body:**
```json
{
  "phone": "0712345678"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Phone number is valid",
  "data": {
    "originalPhone": "0712345678",
    "formattedPhone": "254712345678",
    "country": "Kenya",
    "provider": "Safaricom MPesa"
  }
}
```

### 10. Release Escrow
**POST** `/release-escrow`

Release escrow payment to teacher after service completion.

**Request Body:**
```json
{
  "bookingId": "booking_123",
  "teacherPhone": "254712345678",
  "amount": 5000
}
```

**Response:**
```json
{
  "success": true,
  "message": "Escrow payment released successfully",
  "data": {
    "bookingId": "booking_123",
    "amount": 5000,
    "teacherPhone": "254712345678",
    "releasedAt": 1642678200000
  }
}
```

### 11. Webhook Handler
**POST** `/webhook`

Handle Paystack webhook events (no authentication required).

**Headers:**
```
x-paystack-signature: [webhook_signature]
```

**Webhook Events:**
- `charge.success` - Payment completed successfully
- `charge.failed` - Payment failed
- `transfer.success` - Transfer to teacher successful
- `transfer.failed` - Transfer to teacher failed

## Phone Number Formats

Supported phone number formats:
- `0712345678` → `254712345678`
- `+254712345678` → `254712345678`
- `254712345678` → `254712345678`
- `712345678` → `254712345678`

## Payment Flow

### Test Mode
When using Paystack test keys:
- Phone number is automatically set to `254708374176`
- Email is automatically set to `test@example.com`
- Amount must be one of: 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000 KES

### Production Mode
1. Validate phone number using `/validate-phone`
2. Initiate payment using `/mpesa` or `/mpesa/direct`
3. User receives STK push on their phone
4. User enters MPesa PIN to complete payment
5. Paystack sends webhook to update transaction status
6. Verify payment status using `/verify/:reference`

## Error Responses

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

### Common Error Codes
- `400` - Bad Request (missing/invalid parameters)
- `401` - Unauthorized (invalid API key)
- `404` - Not Found (transaction not found)
- `500` - Internal Server Error

## Environment Variables

Required environment variables:
```
PAYSTACK_SECRET_KEY=sk_test_xxx or sk_live_xxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxx
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
```

## Testing

### Test Credentials
- **Phone**: Any number (will be converted to test number)
- **Email**: test@example.com
- **Amount**: 100-1000 KES (increments of 100)

### Test Webhooks
Use Paystack's webhook testing tool or ngrok for local testing:
```bash
ngrok http 3000
```

## Security Considerations

1. Always validate phone numbers before processing payments
2. Use HTTPS in production
3. Verify webhook signatures
4. Implement rate limiting
5. Log all transactions for audit trails
6. Never store sensitive payment details
7. Use environment variables for API keys
