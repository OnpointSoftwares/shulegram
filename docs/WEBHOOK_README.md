# Paystack Webhook Integration - Quick Start Guide

## 📚 Documentation Files

This directory contains comprehensive webhook documentation:

1. **webhook-setup.md** - Complete setup and configuration guide
2. **webhook-monitoring.md** - Monitoring, debugging, and troubleshooting
3. **WEBHOOK_README.md** - This file (quick reference)

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Get Webhook Secret
1. Go to [Paystack Dashboard](https://dashboard.paystack.co/)
2. Settings → API Keys & Webhooks → Webhooks
3. Copy your **Webhook Secret**

### Step 2: Update .env
```bash
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxx
```

### Step 3: Configure Webhook URL
1. In Paystack Dashboard → Webhooks
2. Add webhook URL:
   ```
   https://backend.shulegram.co.ke/api/payments/webhook
   ```

### Step 4: Test Webhook
```bash
# Make sure server is running
npm run dev

# In another terminal, run tests
./scripts/test-webhook.sh all
```

---

## 📋 Webhook Endpoint

**URL**: `POST /api/payments/webhook`

**Full URL**: `https://backend.shulegram.co.ke/api/payments/webhook`

**Authentication**: None (Paystack uses signature verification)

**Headers Required**:
```
x-paystack-signature: [HMAC-SHA512 signature]
Content-Type: application/json
```

---

## 🔄 Supported Events

| Event | Triggers When | Action |
|-------|---------------|--------|
| `charge.success` | Payment completed | Update transaction & booking to success |
| `charge.failed` | Payment failed | Update transaction to failed |
| `transfer.success` | Money transferred | Update transfer status |
| `transfer.failed` | Transfer failed | Log failure |
| `subscription.*` | Subscription events | Log subscription changes |

---

## 📊 Event Payload Example

```json
{
  "event": "charge.success",
  "data": {
    "reference": "mpesa_abc123",
    "amount": 50000,
    "status": "success",
    "paid_at": "2025-12-03T16:30:00Z",
    "channel": "mobile_money",
    "metadata": {
      "booking_id": "booking_123456",
      "payment_type": "escrow"
    }
  }
}
```

---

## 🧪 Testing

### Local Testing
```bash
# Start server
npm run dev

# Run webhook tests
./scripts/test-webhook.sh all
```

### Remote Testing with ngrok
```bash
# Terminal 1: Start ngrok
ngrok http 3000

# Terminal 2: Update Paystack webhook URL to ngrok URL
# https://abc123.ngrok.io/api/payments/webhook

# Terminal 3: Run tests
WEBHOOK_URL=https://abc123.ngrok.io/api/payments/webhook \
WEBHOOK_SECRET=whsec_xxx \
./scripts/test-webhook.sh all
```

### Manual cURL Test
```bash
# Generate signature (requires openssl)
PAYLOAD='{"event":"charge.success","data":{"reference":"test_123","amount":50000,"status":"success"}}'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha512 -hmac "whsec_xxx" -hex | sed 's/^.* //')

# Send webhook
curl -X POST "http://localhost:3000/api/payments/webhook" \
  -H "x-paystack-signature: $SIGNATURE" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

---

## 🔍 Monitoring

### View Webhook Logs
```bash
tail -f logs/webhook.log
```

### Check Paystack Dashboard
1. Settings → Webhooks
2. Click your webhook URL
3. View "Recent Deliveries" tab
4. Check status and response

### Verify Database Updates
1. Firebase Console → Realtime Database
2. Check `payment-transactions` for updated status
3. Check `bookings` for payment fields

---

## ⚠️ Common Issues

### Issue: "Invalid webhook signature"
**Solution**: Verify webhook secret in `.env` matches Paystack dashboard

### Issue: Webhook not received
**Solution**: 
- Check webhook URL is correct in Paystack
- Verify server is running and accessible
- Check firewall allows incoming requests

### Issue: Transaction not updating
**Solution**:
- Verify Firebase credentials
- Check booking ID in metadata exists
- Review server logs for errors

---

## 📝 Database Updates

### Transaction Record
```javascript
{
  reference: "mpesa_abc123",
  status: "success",              // Updated by webhook
  completedAt: "2025-12-03T16:30:00Z",
  webhookReceived: true,
  lastWebhookEvent: "charge.success",
  lastWebhookReceived: "2025-12-03T16:30:05Z"
}
```

### Booking Record
```javascript
// For escrow payment
{
  escrowPaid: true,
  escrowAmount: 500,
  escrowReference: "mpesa_abc123",
  escrowPaidAt: "2025-12-03T16:30:00Z",
  escrowStatus: "held",
  status: "confirmed"
}
```

---

## 🔐 Security

✅ **Webhook signature verification** - Ensures authenticity
✅ **HTTPS only** - Required in production
✅ **No API key needed** - Paystack uses signature
✅ **Idempotent operations** - Safe to retry
✅ **Audit logging** - All events logged

---

## 📞 Webhook Retry Policy

Paystack automatically retries failed webhooks:

- **1st retry**: 5 minutes
- **2nd retry**: 30 minutes
- **3rd retry**: 2 hours
- **4th retry**: 5 hours
- **5th retry**: 10 hours

**Max attempts**: 5 times

---

## 🚨 Production Checklist

- [ ] Use production Paystack keys (sk_live_...)
- [ ] Use production webhook secret
- [ ] Set NODE_ENV=production
- [ ] Enable HTTPS
- [ ] Update webhook URL to production domain
- [ ] Test with real M-Pesa transactions
- [ ] Monitor webhook deliveries
- [ ] Set up alerts for failures
- [ ] Review logs regularly
- [ ] Document webhook events

---

## 📚 Full Documentation

For detailed information, see:
- **Setup**: `webhook-setup.md`
- **Monitoring**: `webhook-monitoring.md`
- **API Reference**: `mpesa-api.md`

---

## 🔗 Useful Links

- [Paystack Webhooks Docs](https://paystack.com/docs/payments/webhooks/)
- [Paystack API Reference](https://paystack.com/docs/api/)
- [Firebase Realtime Database](https://firebase.google.com/docs/database)
- [ngrok Documentation](https://ngrok.com/docs)

---

## 💡 Tips

1. **Test locally first** - Use ngrok for remote testing
2. **Monitor logs** - Watch logs while testing
3. **Check Paystack dashboard** - Verify webhook delivery
4. **Verify database** - Confirm records are updated
5. **Set up alerts** - Get notified of failures

---

## ❓ FAQ

**Q: How often are webhooks sent?**
A: Immediately when event occurs, with retries if failed.

**Q: What if webhook fails?**
A: Paystack retries up to 5 times over 24 hours.

**Q: Can I test webhooks locally?**
A: Yes, use ngrok to expose localhost to internet.

**Q: What if I miss a webhook?**
A: You can verify payment status using `/verify/:reference` endpoint.

**Q: How do I know webhook was received?**
A: Check `webhookReceived: true` in transaction record.

---

## 🆘 Support

For issues:
1. Check webhook logs: `tail -f logs/webhook.log`
2. Review Paystack dashboard → Webhooks → Recent Deliveries
3. Verify Firebase database updates
4. Check `.env` configuration
5. Review full documentation in `webhook-setup.md`

---

**Last Updated**: December 3, 2025
**Version**: 1.0.0
