# Webhook Monitoring & Debugging Guide

## Overview
This guide helps you monitor, debug, and troubleshoot Paystack webhooks in the ShulePearl payment backend.

---

## 1. Real-Time Webhook Monitoring

### View Server Logs

```bash
# Watch webhook logs in real-time
tail -f logs/webhook.log

# Filter for specific event types
tail -f logs/webhook.log | grep "charge.success"

# Count webhook events
grep "charge.success" logs/webhook.log | wc -l
```

### Expected Log Output

```
=== Incoming Webhook ===
Headers: {
  "x-paystack-signature": "abc123def456...",
  "content-type": "application/json"
}
Body: {
  "event": "charge.success",
  "data": { ... }
}
✅ Webhook signature verified
✅ Payment successful: mpesa_abc123
Booking booking_123456 updated for escrow payment
```

---

## 2. Paystack Dashboard Monitoring

### Check Webhook Delivery Status

1. Go to **Paystack Dashboard**
2. Navigate to **Settings** → **Webhooks**
3. Click on your webhook URL
4. View **Recent Deliveries** tab

### Webhook Status Indicators

| Status | Meaning | Action |
|--------|---------|--------|
| ✅ Success | Webhook delivered and processed | No action needed |
| ⏳ Pending | Webhook queued for delivery | Wait for delivery |
| ❌ Failed | Webhook delivery failed | Check server logs |
| 🔄 Retrying | Paystack retrying delivery | Monitor retry status |

### View Webhook Details

1. Click on a webhook entry
2. View:
   - **Event Type**: charge.success, charge.failed, etc.
   - **Timestamp**: When event occurred
   - **Reference**: Transaction reference
   - **Status Code**: HTTP response code
   - **Response Body**: Server response
   - **Retry Count**: Number of retry attempts

---

## 3. Database Verification

### Check Transaction Updates

```bash
# Using Firebase Console
1. Go to Firebase Console
2. Select your project
3. Go to Realtime Database
4. Navigate to payment-transactions
5. Find transaction by reference
6. Verify status is updated to "success"
```

### Verify Transaction Record

```json
{
  "reference": "mpesa_abc123",
  "bookingId": "booking_123456",
  "email": "user@example.com",
  "amount": 500,
  "status": "success",
  "paymentMethod": "mpesa",
  "createdAt": 1701619200000,
  "completedAt": 1701619260000,
  "webhookReceived": true,
  "lastWebhookEvent": "charge.success",
  "lastWebhookReceived": "2025-12-03T16:30:05Z",
  "metadata": {
    "booking_id": "booking_123456",
    "payment_type": "escrow"
  }
}
```

### Check Booking Updates

```bash
# Navigate to bookings in Firebase
1. Go to Realtime Database
2. Navigate to bookings
3. Find booking by ID
4. Verify payment fields are updated:
   - escrowPaid: true
   - escrowAmount: 500
   - escrowReference: "mpesa_abc123"
   - escrowPaidAt: timestamp
   - escrowStatus: "held"
```

---

## 4. Common Webhook Issues & Solutions

### Issue 1: Webhook Not Being Received

**Symptoms**:
- No webhook entries in Paystack dashboard
- Transaction status not updating
- Server logs show no webhook activity

**Debugging Steps**:

```bash
# 1. Check server is running
curl http://localhost:3000/health

# 2. Verify webhook URL is correct
# Go to Paystack Dashboard → Settings → Webhooks
# Confirm URL matches your server

# 3. Check firewall/network
# Ensure port 3000 is accessible (or your production port)

# 4. Verify webhook secret is set
grep PAYSTACK_WEBHOOK_SECRET .env

# 5. Check server logs for errors
tail -f logs/error.log
```

**Solutions**:
- Restart server: `npm restart`
- Verify webhook URL in Paystack dashboard
- Check firewall rules allow incoming requests
- Ensure HTTPS is enabled in production
- Verify `.env` has correct webhook secret

---

### Issue 2: "Invalid Webhook Signature"

**Symptoms**:
- Webhook received but rejected
- Log shows: "Webhook signature verification failed"
- HTTP 401 response to Paystack

**Debugging Steps**:

```bash
# 1. Verify webhook secret
echo $PAYSTACK_WEBHOOK_SECRET

# 2. Check it matches Paystack dashboard
# Go to Settings → Webhooks → View Secret

# 3. Test signature verification locally
./scripts/test-webhook.sh invalid-sig

# 4. Check for special characters in secret
# Some characters may need escaping
```

**Solutions**:
- Copy webhook secret exactly from Paystack dashboard
- Ensure no extra spaces or newlines
- Regenerate webhook secret if needed
- Restart server after updating `.env`

---

### Issue 3: Transaction Not Updating in Firebase

**Symptoms**:
- Webhook received and verified
- But transaction status not changing
- Booking not updating

**Debugging Steps**:

```bash
# 1. Check Firebase credentials
grep FIREBASE .env

# 2. Verify Firebase connection
# Check server logs for Firebase errors

# 3. Check transaction reference format
# Should match format: mpesa_abc123

# 4. Verify booking exists
# Go to Firebase → bookings → check booking ID

# 5. Check Firebase permissions
# Ensure service account has write access
```

**Solutions**:
- Verify Firebase credentials in `.env`
- Ensure booking ID in metadata matches database
- Check Firebase Realtime Database rules allow writes
- Regenerate Firebase service account key if needed

---

### Issue 4: Duplicate Webhook Processing

**Symptoms**:
- Same transaction processed multiple times
- Duplicate entries in database
- Multiple booking updates

**Debugging Steps**:

```bash
# 1. Check webhook logs for duplicates
grep "mpesa_abc123" logs/webhook.log

# 2. Check transaction record
# Look for multiple webhookReceived timestamps

# 3. Review Paystack retry logs
# Go to Paystack Dashboard → Webhooks → Recent Deliveries
```

**Solutions**:
- Implement idempotent webhook handling
- Use transaction reference as unique key
- Check if transaction already processed before updating
- Add duplicate detection logic

---

### Issue 5: Webhook Timeout

**Symptoms**:
- Webhook marked as failed in Paystack
- Server logs show timeout errors
- HTTP 504 or timeout response

**Debugging Steps**:

```bash
# 1. Check server performance
top -b -n 1 | head -20

# 2. Check database response time
# Monitor Firebase operations

# 3. Check network latency
ping api.paystack.co

# 4. Review server logs for slow operations
tail -f logs/performance.log
```

**Solutions**:
- Optimize database queries
- Add caching for frequently accessed data
- Increase server resources
- Process webhooks asynchronously
- Implement request timeouts

---

## 5. Testing Webhooks

### Test with Local Server

```bash
# Terminal 1: Start server
npm run dev

# Terminal 2: Run webhook tests
./scripts/test-webhook.sh all
```

### Test with ngrok (Remote Testing)

```bash
# Terminal 1: Start ngrok tunnel
ngrok http 3000

# Terminal 2: Update webhook URL in Paystack
# Go to Settings → Webhooks
# Update URL to: https://abc123.ngrok.io/api/payments/webhook

# Terminal 3: Run webhook tests
WEBHOOK_URL=https://abc123.ngrok.io/api/payments/webhook \
WEBHOOK_SECRET=whsec_xxx \
./scripts/test-webhook.sh all
```

### Test with Postman

1. Import webhook test collection
2. Set variables:
   - `webhook_url`: Your webhook URL
   - `webhook_secret`: Your webhook secret
3. Run webhook tests
4. Check responses

---

## 6. Webhook Event Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Completes M-Pesa Payment                            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Paystack Receives Payment Confirmation                   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Paystack Generates Webhook Event                         │
│    - Event Type: charge.success                             │
│    - Signature: HMAC-SHA512                                 │
│    - Payload: Transaction details + metadata                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Paystack Sends HTTP POST to Your Server                  │
│    POST /api/payments/webhook                               │
│    Headers:                                                 │
│    - x-paystack-signature: [signature]                      │
│    - Content-Type: application/json                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Your Server Receives Webhook                             │
│    - Log incoming request                                   │
│    - Extract signature from headers                         │
│    - Extract payload from body                              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Verify Webhook Signature                                 │
│    - Recreate signature using webhook secret                │
│    - Compare with received signature                        │
│    - If mismatch: Reject (HTTP 401)                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Process Webhook Event                                    │
│    - Parse event type (charge.success, charge.failed, etc.) │
│    - Extract transaction details                            │
│    - Extract metadata (booking_id, payment_type)            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Update Transaction in Firebase                           │
│    - Set status: "success" or "failed"                      │
│    - Set completedAt: timestamp                             │
│    - Set webhookReceived: true                              │
│    - Store webhook event details                            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. Update Booking (if applicable)                           │
│    - If payment_type: "booking_fee"                         │
│      → Set bookingFeePaid: true                             │
│      → Set status: "negotiating"                            │
│    - If payment_type: "escrow"                              │
│      → Set escrowPaid: true                                 │
│      → Set escrowStatus: "held"                             │
│      → Set status: "confirmed"                              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 10. Send Response to Paystack                               │
│     HTTP 200 OK                                             │
│     { "success": true }                                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 11. Paystack Marks Webhook as Delivered                     │
│     - Visible in Dashboard → Webhooks → Recent Deliveries   │
│     - Status: ✅ Success                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Performance Monitoring

### Monitor Webhook Processing Time

```bash
# Add timing logs to webhook handler
console.time('webhook_processing');
// ... webhook processing code ...
console.timeEnd('webhook_processing');

# Output: webhook_processing: 234ms
```

### Set Performance Targets

- Webhook processing: < 500ms
- Database update: < 200ms
- Response time: < 1000ms

### Monitor with APM Tools

```bash
# Using New Relic, DataDog, or similar
# Track:
# - Webhook response time
# - Database query time
# - Error rate
# - Throughput
```

---

## 8. Alerting & Notifications

### Set Up Alerts

```bash
# Alert when:
# - Webhook fails (HTTP != 200)
# - Signature verification fails
# - Database update fails
# - Processing time > 1000ms
# - Error rate > 5%
```

### Example Alert Configuration

```javascript
// In your monitoring tool
if (webhookProcessingTime > 1000) {
  sendAlert('Slow webhook processing', {
    reference: transaction.reference,
    processingTime: webhookProcessingTime,
    severity: 'warning'
  });
}

if (signatureVerificationFailed) {
  sendAlert('Invalid webhook signature', {
    timestamp: new Date(),
    severity: 'critical'
  });
}
```

---

## 9. Webhook Logs Analysis

### Parse and Analyze Logs

```bash
# Count successful webhooks
grep "✅ Payment successful" logs/webhook.log | wc -l

# Count failed webhooks
grep "❌ Payment failed" logs/webhook.log | wc -l

# Find slowest webhooks
grep "webhook_processing:" logs/webhook.log | sort -t: -k2 -rn | head -10

# Find errors
grep "ERROR" logs/webhook.log

# Get webhook statistics
echo "=== Webhook Statistics ==="
echo "Total: $(grep 'Incoming Webhook' logs/webhook.log | wc -l)"
echo "Success: $(grep 'Payment successful' logs/webhook.log | wc -l)"
echo "Failed: $(grep 'Payment failed' logs/webhook.log | wc -l)"
```

---

## 10. Webhook Debugging Checklist

- [ ] Webhook URL is correct in Paystack dashboard
- [ ] Webhook secret matches in `.env`
- [ ] Server is running and accessible
- [ ] HTTPS is enabled (production)
- [ ] Firewall allows incoming requests
- [ ] Firebase credentials are valid
- [ ] Database has write permissions
- [ ] Webhook signature verification is working
- [ ] Transaction records are being created
- [ ] Booking records are being updated
- [ ] Logs show webhook events
- [ ] Paystack dashboard shows successful deliveries

---

## Support & Resources

- [Paystack Webhook Docs](https://paystack.com/docs/payments/webhooks/)
- [Paystack Status Page](https://status.paystack.com/)
- [Firebase Realtime Database Docs](https://firebase.google.com/docs/database)
- [ngrok Documentation](https://ngrok.com/docs)
