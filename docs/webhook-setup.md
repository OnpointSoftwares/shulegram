# Paystack Webhook Setup Guide

## Overview
This guide explains how to set up and configure Paystack webhooks for the ShulePearl payment backend to handle real-time payment events.

## What are Webhooks?
Webhooks are HTTP callbacks that Paystack sends to your server when payment events occur. They allow your backend to automatically update payment statuses without polling.

---

## Step 1: Configure Paystack Dashboard

### 1.1 Access Webhook Settings
1. Log in to [Paystack Dashboard](https://dashboard.paystack.co/)
2. Navigate to **Settings** → **API Keys & Webhooks**
3. Scroll down to **Webhooks** section

### 1.2 Add Webhook URL
1. Click **Add Webhook**
2. Enter your webhook URL:
   ```
   https://backend.shulegram.co.ke/api/payments/webhook
   ```
3. Select events to receive (see Event Types below)
4. Click **Save**

### 1.3 Get Webhook Secret
1. In the Webhooks section, you'll see your **Webhook Secret**
2. Copy this secret
3. Add it to your `.env` file:
   ```
   PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxx
   ```

---

## Step 2: Environment Configuration

Update your `.env` file:

```bash
# Paystack Configuration
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxx

# Server Configuration
NODE_ENV=production
FRONTEND_URL=https://shulegram.co.ke
```

---

## Step 3: Webhook Events

### Supported Events

| Event | Description | Action |
|-------|-------------|--------|
| `charge.success` | Payment completed successfully | Update transaction & booking to success |
| `charge.failed` | Payment failed | Update transaction to failed |
| `charge.dispute.create` | Dispute initiated | Log dispute |
| `transfer.success` | Money transferred to recipient | Update transfer status |
| `transfer.failed` | Transfer failed | Log transfer failure |
| `subscription.create` | Subscription created | Log subscription |
| `subscription.disable` | Subscription disabled | Log subscription disable |
| `subscription.not_renew` | Subscription won't renew | Log subscription status |

### Enable Specific Events in Paystack Dashboard

1. Go to **Settings** → **Webhooks**
2. Click on your webhook URL
3. Select the events you want to receive:
   - ✅ `charge.success`
   - ✅ `charge.failed`
   - ✅ `transfer.success`
   - ✅ `transfer.failed`
4. Click **Save**

---

## Step 4: Webhook Payload Structure

### Charge Success Event Example

```json
{
  "event": "charge.success",
  "data": {
    "id": 123456789,
    "reference": "mpesa_abc123def456",
    "amount": 50000,
    "currency": "KES",
    "status": "success",
    "paid_at": "2025-12-03T16:30:00.000Z",
    "created_at": "2025-12-03T16:25:00.000Z",
    "channel": "mobile_money",
    "customer": {
      "id": 987654,
      "email": "user@example.com",
      "customer_code": "CUS_xxxxx"
    },
    "metadata": {
      "booking_id": "booking_123456",
      "payment_type": "escrow",
      "user_id": "user_789"
    },
    "gateway_response": "Successful",
    "authorization": {
      "authorization_code": "AUTH_xxxxx",
      "bin": "408408",
      "last4": "4081",
      "exp_month": "12",
      "exp_year": "2025",
      "channel": "mobile_money",
      "card_type": "debit",
      "bank": "Test Bank",
      "country_code": "KE",
      "brand": "VISA"
    }
  }
}
```

### Charge Failed Event Example

```json
{
  "event": "charge.failed",
  "data": {
    "id": 123456790,
    "reference": "mpesa_failed123",
    "amount": 50000,
    "currency": "KES",
    "status": "failed",
    "paid_at": null,
    "created_at": "2025-12-03T16:25:00.000Z",
    "channel": "mobile_money",
    "customer": {
      "email": "user@example.com"
    },
    "metadata": {
      "booking_id": "booking_123456",
      "payment_type": "escrow"
    },
    "gateway_response": "Insufficient funds",
    "failures": {
      "code": "insufficient_funds",
      "message": "Insufficient funds in account"
    }
  }
}
```

---

## Step 5: Webhook Handler Implementation

### Location
**File**: `/controllers/paymentController.js`

### Key Functions

#### 1. Verify Webhook Signature
```javascript
const verifyWebhookSignature = (req) => {
  const crypto = require('crypto');
  const signature = req.headers['x-paystack-signature'];
  
  const hash = crypto
    .createHmac('sha512', process.env.PAYSTACK_WEBHOOK_SECRET)
    .update(JSON.stringify(req.body))
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(hash),
    Buffer.from(signature)
  );
};
```

#### 2. Handle Webhook Events
```javascript
const handleWebhook = async (req, res) => {
  // Verify signature
  if (!verifyWebhookSignature(req)) {
    return res.status(401).json({ 
      success: false, 
      message: 'Invalid webhook signature' 
    });
  }

  const { event, data } = req.body;
  const db = getDatabase();

  switch (event) {
    case 'charge.success':
      // Update transaction and booking
      await transactionRef.update({
        status: 'success',
        completedAt: new Date().toISOString(),
        webhookReceived: true
      });
      break;

    case 'charge.failed':
      // Update transaction with failure info
      await transactionRef.update({
        status: 'failed',
        failedAt: new Date().toISOString(),
        failureReason: data.gateway_response
      });
      break;

    // ... other events
  }

  res.status(200).json({ success: true });
};
```

---

## Step 6: Testing Webhooks Locally

### Option 1: Using ngrok (Recommended)

1. **Install ngrok**:
   ```bash
   # macOS
   brew install ngrok

   # Ubuntu/Debian
   sudo apt-get install ngrok
   ```

2. **Start ngrok tunnel**:
   ```bash
   ngrok http 3000
   ```

3. **Get your public URL**:
   ```
   Forwarding: https://abc123def456.ngrok.io -> http://localhost:3000
   ```

4. **Add to Paystack Webhooks**:
   ```
   https://abc123def456.ngrok.io/api/payments/webhook
   ```

5. **Test webhook**:
   ```bash
   curl -X POST "https://abc123def456.ngrok.io/api/payments/webhook" \
     -H "x-paystack-signature: test-signature" \
     -H "Content-Type: application/json" \
     -d '{
       "event": "charge.success",
       "data": {
         "reference": "test_ref_123",
         "amount": 50000,
         "status": "success",
         "metadata": {
           "booking_id": "booking_test"
         }
       }
     }'
   ```

### Option 2: Using Paystack Test Mode

1. Go to Paystack Dashboard → **Settings** → **Test/Live**
2. Switch to **Test Mode**
3. Use test credentials to trigger test payments
4. Paystack will send webhook events to your configured URL

### Option 3: Manual Testing

Use the provided test script:

```bash
./scripts/test-webhook.sh
```

---

## Step 7: Webhook Signature Verification

### Why Verify Signatures?
- Ensures webhook comes from Paystack
- Prevents unauthorized requests
- Protects against tampering

### How It Works

1. Paystack signs the webhook payload using your webhook secret
2. Signature is sent in `x-paystack-signature` header
3. Your server recreates the signature
4. Compare signatures - if they match, webhook is authentic

### Implementation

```bash
# Signature is created using:
signature = HMAC-SHA512(webhook_secret, request_body)

# Sent in header:
x-paystack-signature: [signature_value]
```

---

## Step 8: Database Updates

### Transaction Record Update

When webhook is received, the transaction record is updated:

```javascript
{
  reference: "mpesa_abc123",
  status: "success",           // Updated by webhook
  completedAt: "2025-12-03T16:30:00Z",
  webhookReceived: true,
  lastWebhookEvent: "charge.success",
  lastWebhookReceived: "2025-12-03T16:30:05Z",
  metadata: { ... }
}
```

### Booking Record Update

If booking exists, it's updated based on payment type:

```javascript
// For booking_fee payment
{
  status: "negotiating",
  bookingFeePaid: true,
  bookingFeeReference: "mpesa_abc123",
  bookingFeePaidAt: "2025-12-03T16:30:00Z"
}

// For escrow payment
{
  status: "confirmed",
  escrowPaid: true,
  escrowAmount: 500,
  escrowReference: "mpesa_abc123",
  escrowPaidAt: "2025-12-03T16:30:00Z",
  escrowStatus: "held"
}
```

---

## Step 9: Monitoring Webhooks

### View Webhook Logs

1. Go to Paystack Dashboard → **Settings** → **Webhooks**
2. Click on your webhook URL
3. View **Recent Deliveries** tab
4. Check status and response for each webhook

### Server Logs

Check your server logs for webhook processing:

```bash
# View logs
tail -f logs/webhook.log

# Look for:
# - "=== Incoming Webhook ===" - Webhook received
# - "✅ Webhook signature verified" - Signature valid
# - "✅ Payment successful" - Payment processed
# - "❌ Webhook signature verification failed" - Invalid signature
```

---

## Step 10: Troubleshooting

### Issue: "Invalid webhook signature"

**Solution**:
1. Verify `PAYSTACK_WEBHOOK_SECRET` is correct in `.env`
2. Ensure webhook secret matches Paystack dashboard
3. Check that `x-paystack-signature` header is present

### Issue: Webhook not being received

**Solution**:
1. Verify webhook URL is correct in Paystack dashboard
2. Check server is running and accessible
3. Verify firewall allows incoming requests
4. Check server logs for errors

### Issue: Transaction not updating

**Solution**:
1. Check Firebase credentials in `.env`
2. Verify booking ID in metadata matches database
3. Check transaction reference format
4. Review server logs for database errors

### Issue: ngrok tunnel keeps disconnecting

**Solution**:
```bash
# Use paid ngrok account for persistent tunnels
# Or restart ngrok:
ngrok http 3000 --region us
```

---

## Step 11: Production Checklist

Before going live:

- [ ] Update `PAYSTACK_SECRET_KEY` to production key (sk_live_...)
- [ ] Update `PAYSTACK_WEBHOOK_SECRET` to production secret
- [ ] Set `NODE_ENV=production` in `.env`
- [ ] Update webhook URL to production domain
- [ ] Enable HTTPS (required for production)
- [ ] Set up proper error logging and monitoring
- [ ] Test with real M-Pesa transactions
- [ ] Monitor webhook delivery in Paystack dashboard
- [ ] Set up alerts for failed webhooks
- [ ] Document webhook events in your system

---

## Step 12: Webhook Retry Policy

Paystack automatically retries failed webhooks:

- **Retry Schedule**: 
  - 1st retry: 5 minutes
  - 2nd retry: 30 minutes
  - 3rd retry: 2 hours
  - 4th retry: 5 hours
  - 5th retry: 10 hours

- **Max Attempts**: 5 times
- **Timeout**: 30 seconds per request

---

## Step 13: Security Best Practices

1. **Always verify signatures** - Never skip signature verification
2. **Use HTTPS only** - Webhooks must use HTTPS in production
3. **Rotate secrets regularly** - Change webhook secret periodically
4. **Log all events** - Keep audit trail of all webhook events
5. **Handle duplicates** - Paystack may send duplicate webhooks
6. **Idempotent operations** - Ensure operations can be safely retried
7. **Timeout handling** - Set appropriate timeouts for webhook processing

---

## Example Webhook Flow

```
1. User completes M-Pesa payment
   ↓
2. Paystack receives payment confirmation
   ↓
3. Paystack sends webhook to your server
   ↓
4. Your server verifies webhook signature
   ↓
5. Your server processes the event
   ↓
6. Transaction status updated in Firebase
   ↓
7. Booking status updated
   ↓
8. Your server responds with 200 OK
   ↓
9. Paystack marks webhook as delivered
```

---

## Additional Resources

- [Paystack Webhook Documentation](https://paystack.com/docs/payments/webhooks/)
- [Paystack API Reference](https://paystack.com/docs/api/)
- [ngrok Documentation](https://ngrok.com/docs)
- [HMAC-SHA512 Verification](https://en.wikipedia.org/wiki/HMAC)

---

## Support

For issues or questions:
1. Check Paystack Dashboard → Webhooks → Recent Deliveries
2. Review server logs
3. Contact Paystack support: support@paystack.com
4. Check ShulePearl documentation
