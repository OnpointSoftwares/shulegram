# M-Pesa Payment API - cURL Commands

## Setup
Replace `YOUR_API_KEY` with your actual API key and adjust the base URL as needed.

```bash
# Variables
API_KEY="YOUR_API_KEY"
BASE_URL="http://localhost:3000/api/payments"
```

---

## 1. Phone Number Validation

```bash
curl -X POST "${BASE_URL}/validate-phone" \
  -H "x-api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0712345678"
  }'
```

**Expected Response:**
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

---

## 2. Initialize Payment

```bash
curl -X POST "${BASE_URL}/initialize" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "amount": 500,
    "bookingId": "booking_123456",
    "metadata": {
      "payment_type": "booking_fee",
      "user_id": "user_789"
    }
  }'
```

**Expected Response:**
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

---

## 3. Process M-Pesa Payment (Full STK Push)

```bash
curl -X POST "${BASE_URL}/mpesa" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0712345678",
    "amount": 500,
    "email": "test@example.com",
    "bookingId": "booking_123456",
    "metadata": {
      "payment_type": "escrow",
      "service_type": "tutoring"
    }
  }'
```

**Expected Response:**
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

---

## 4. Direct M-Pesa Payment

```bash
curl -X POST "${BASE_URL}/mpesa/direct" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "254712345678",
    "amount": 500,
    "email": "test@example.com",
    "bookingId": "booking_123456",
    "metadata": {
      "payment_type": "booking_fee",
      "urgent": true
    }
  }'
```

---

## 5. Verify Payment

```bash
curl -X GET "${BASE_URL}/verify/mpesa_abc123" \
  -H "Authorization: Bearer ${API_KEY}"
```

---

## 6. Get Payment Status

```bash
curl -X GET "${BASE_URL}/status/mpesa_abc123" \
  -H "Authorization: Bearer ${API_KEY}"
```

---

## 7. Retry Failed Payment

```bash
curl -X POST "${BASE_URL}/retry/failed_payment_ref" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0712345678",
    "email": "test@example.com"
  }'
```

---

## 8. Cancel Payment

```bash
curl -X POST "${BASE_URL}/cancel/pending_payment_ref" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "User requested cancellation"
  }'
```

---

## 9. Get Transaction History

```bash
# Basic history
curl -X GET "${BASE_URL}/history/test@example.com?limit=10&offset=0" \
  -H "Authorization: Bearer ${API_KEY}"

# Filtered by status
curl -X GET "${BASE_URL}/history/test@example.com?status=success&limit=20" \
  -H "Authorization: Bearer ${API_KEY}"
```

---

## 10. Release Escrow

```bash
curl -X POST "${BASE_URL}/release-escrow" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "booking_123456",
    "teacherPhone": "254712345678",
    "amount": 5000
  }'
```

---

## 11. Webhook (No Authentication Required)

```bash
curl -X POST "${BASE_URL}/webhook" \
  -H "Content-Type: application/json" \
  -H "x-paystack-signature: webhook-signature-here" \
  -d '{
    "event": "charge.success",
    "data": {
      "reference": "mpesa_test_123",
      "amount": 50000,
      "status": "success",
      "gateway_response": "Successful",
      "metadata": {
        "booking_id": "booking_123456",
        "payment_type": "escrow"
      }
    }
  }'
```

---

## Complete Payment Flow Example

```bash
#!/bin/bash

# Configuration
API_KEY="YOUR_API_KEY"
BASE_URL="http://localhost:3000/api/payments"
PHONE="0712345678"
EMAIL="test@example.com"
AMOUNT=500
BOOKING_ID="booking_$(date +%s)"

echo "🚀 Starting M-Pesa Payment Flow Test"
echo "=================================="

# Step 1: Validate Phone
echo "1. Validating phone number..."
PHONE_RESPONSE=$(curl -s -X POST "${BASE_URL}/validate-phone" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"phone\": \"${PHONE}\"}")

echo "Phone validation response:"
echo "$PHONE_RESPONSE" | jq .

# Step 2: Initialize Payment
echo "2. Initializing payment..."
INIT_RESPONSE=$(curl -s -X POST "${BASE_URL}/initialize" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${EMAIL}\", \"amount\": ${AMOUNT}, \"bookingId\": \"${BOOKING_ID}\", \"metadata\": {\"payment_type\": \"booking_fee\"}}")

echo "Payment initialization response:"
echo "$INIT_RESPONSE" | jq .

# Step 3: Process M-Pesa Payment
echo "3. Processing M-Pesa payment..."
MPESA_RESPONSE=$(curl -s -X POST "${BASE_URL}/mpesa" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"phone\": \"${PHONE}\", \"amount\": ${AMOUNT}, \"email\": \"${EMAIL}\", \"bookingId\": \"${BOOKING_ID}\", \"metadata\": {\"payment_type\": \"escrow\"}}")

echo "M-Pesa payment response:"
echo "$MPESA_RESPONSE" | jq .

# Extract reference for next steps
REFERENCE=$(echo "$MPESA_RESPONSE" | jq -r '.data.reference // empty')

if [ -n "$REFERENCE" ] && [ "$REFERENCE" != "null" ]; then
  echo "4. Checking payment status..."
  STATUS_RESPONSE=$(curl -s -X GET "${BASE_URL}/status/${REFERENCE}" \
    -H "Authorization: Bearer ${API_KEY}")
  
  echo "Payment status response:"
  echo "$STATUS_RESPONSE" | jq .
  
  echo "5. Verifying payment..."
  VERIFY_RESPONSE=$(curl -s -X GET "${BASE_URL}/verify/${REFERENCE}" \
    -H "Authorization: Bearer ${API_KEY}")
  
  echo "Payment verification response:"
  echo "$VERIFY_RESPONSE" | jq .
else
  echo "❌ Could not extract reference from M-Pesa response"
fi

echo "✅ Payment flow test completed!"
```

---

## Error Testing Examples

### Invalid Phone Number
```bash
curl -X POST "${BASE_URL}/validate-phone" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "invalid-phone"
  }'
```

### Missing Required Fields
```bash
curl -X POST "${BASE_URL}/mpesa" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0712345678"
  }'
```

### Non-existent Transaction
```bash
curl -X GET "${BASE_URL}/status/non-existent-reference" \
  -H "Authorization: Bearer ${API_KEY}"
```

### Invalid API Key
```bash
curl -X GET "${BASE_URL}/status/some-reference" \
  -H "Authorization: Bearer invalid-api-key"
```

---

## Testing Tips

1. **Use jq for pretty JSON output:**
   ```bash
   curl ... | jq .
   ```

2. **Save responses to files:**
   ```bash
   curl ... > response.json
   ```

3. **Use verbose mode for debugging:**
   ```bash
   curl -v -X POST "${BASE_URL}/mpesa" ...
   ```

4. **Test with different phone formats:**
   ```bash
   # Test various phone number formats
   curl -X POST "${BASE_URL}/validate-phone" -d '{"phone": "0712345678"}'
   curl -X POST "${BASE_URL}/validate-phone" -d '{"phone": "+254712345678"}'
   curl -X POST "${BASE_URL}/validate-phone" -d '{"phone": "254712345678"}'
   curl -X POST "${BASE_URL}/validate-phone" -d '{"phone": "712345678"}'
   ```

5. **Monitor webhooks locally:**
   ```bash
   # Use ngrok to expose localhost for webhook testing
   ngrok http 3000
   ```

---

## Environment Setup

For testing, set these environment variables:

```bash
export API_KEY="your-test-api-key"
export BASE_URL="http://localhost:3000/api/payments"

# Test mode (if using Paystack test keys)
export PAYSTACK_SECRET_KEY="sk_test_xxx"
```

Then use the variables in curl commands:

```bash
curl -X POST "${BASE_URL}/mpesa" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0712345678",
    "amount": 500,
    "email": "test@example.com",
    "bookingId": "booking_test"
  }'
```
