# M-Pesa Payment API - Quick Reference Card

## 🔗 Webhook URL
```
https://backend.shulegram.co.ke/api/payments/webhook
```

## 🔑 Authentication
```
Header: x-api-key: YOUR_API_KEY
Webhook: x-paystack-signature: HMAC-SHA512
```

---

## 📋 All Endpoints

### Phone Validation
```
POST /validate-phone
Body: {"phone": "0712345678"}
```

### Payment Initialization
```
POST /initialize
Body: {
  "email": "user@example.com",
  "amount": 500,
  "bookingId": "booking_123"
}
```

### M-Pesa Payment
```
POST /mpesa
Body: {
  "phone": "0712345678",
  "amount": 500,
  "email": "user@example.com",
  "bookingId": "booking_123"
}
```

### Direct M-Pesa
```
POST /mpesa/direct
Body: {
  "phone": "0712345678",
  "amount": 500,
  "email": "user@example.com",
  "bookingId": "booking_123"
}
```

### Verify Payment
```
GET /verify/mpesa_abc123
```

### Payment Status
```
GET /status/mpesa_abc123
```

### Retry Payment
```
POST /retry/failed_ref
Body: {"phone": "0712345678", "email": "user@example.com"}
```

### Cancel Payment
```
POST /cancel/pending_ref
Body: {"reason": "User cancelled"}
```

### Transaction History
```
GET /history/user@example.com?limit=10&status=success
```

### Release Escrow
```
POST /release-escrow
Body: {
  "bookingId": "booking_123",
  "teacherPhone": "0712345678",
  "amount": 5000
}
```

### Webhook
```
POST /webhook
Headers: x-paystack-signature: signature
Body: Paystack webhook payload
```

---

## 🧪 Quick Test Commands

### Test Phone Validation
```bash
curl -X POST "http://localhost:3000/api/payments/validate-phone" \
  -H "x-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"phone": "0712345678"}'
```

### Test M-Pesa Payment
```bash
curl -X POST "http://localhost:3000/api/payments/mpesa" \
  -H "x-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0712345678",
    "amount": 500,
    "email": "test@example.com",
    "bookingId": "booking_test"
  }'
```

### Run All Tests
```bash
API_KEY=your-secret ./scripts/test-mpesa.sh all
WEBHOOK_SECRET=whsec_xxx ./scripts/test-webhook.sh all
```

---

## 📊 Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    "reference": "mpesa_abc123",
    "status": "pending",
    "amount": 500
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

---

## 🔄 Webhook Events

| Event | When | Action |
|-------|------|--------|
| `charge.success` | Payment OK | Update to success |
| `charge.failed` | Payment failed | Update to failed |
| `transfer.success` | Transfer OK | Update transfer |
| `transfer.failed` | Transfer failed | Log failure |

---

## 💾 Environment Variables

```bash
# API
API_SECRET=your-secret-key

# Paystack
PAYSTACK_SECRET_KEY=sk_test_xxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxx

# Firebase
FIREBASE_PROJECT_ID=project-id
FIREBASE_PRIVATE_KEY="-----BEGIN..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@project.iam.gserviceaccount.com

# Server
PORT=3000
NODE_ENV=production
FRONTEND_URL=https://shulegram.co.ke
```

---

## 📱 Phone Number Formats

All these convert to `254712345678`:
- `0712345678`
- `+254712345678`
- `254712345678`
- `712345678`

---

## 🔐 Webhook Signature

```bash
# Generate signature
PAYLOAD='{"event":"charge.success","data":{...}}'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha512 -hmac "whsec_xxx" -hex | sed 's/^.* //')

# Send webhook
curl -X POST "http://localhost:3000/api/payments/webhook" \
  -H "x-paystack-signature: $SIGNATURE" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

---

## 📈 Status Values

- `pending` - Waiting for payment
- `success` - Payment completed
- `failed` - Payment failed
- `cancelled` - User cancelled
- `retrying` - Retry in progress

---

## 🚀 Setup Steps

1. **Get Paystack Keys**
   - Go to paystack.co/dashboard
   - Settings → API Keys
   - Copy Secret Key

2. **Get Webhook Secret**
   - Settings → Webhooks
   - Copy Webhook Secret

3. **Update .env**
   ```bash
   PAYSTACK_SECRET_KEY=sk_test_xxx
   PAYSTACK_WEBHOOK_SECRET=whsec_xxx
   ```

4. **Configure Webhook**
   - Paystack Dashboard → Webhooks
   - URL: `https://backend.shulegram.co.ke/api/payments/webhook`
   - Save

5. **Test**
   ```bash
   ./scripts/test-mpesa.sh all
   ./scripts/test-webhook.sh all
   ```

---

## 🆘 Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Invalid API key` | Wrong x-api-key | Check API_SECRET in .env |
| `Invalid webhook signature` | Wrong secret | Verify PAYSTACK_WEBHOOK_SECRET |
| `Invalid phone number` | Bad format | Use 254XXXXXXXXX format |
| `Missing required fields` | Incomplete request | Check request body |
| `Transaction not found` | Wrong reference | Verify reference exists |

---

## 📚 Documentation

- **Full API**: `docs/mpesa-api.md`
- **Webhook Setup**: `docs/webhook-setup.md`
- **Monitoring**: `docs/webhook-monitoring.md`
- **cURL Commands**: `docs/mpesa-curl-commands.md`
- **Quick Start**: `docs/WEBHOOK_README.md`

---

## 🔗 Useful Links

- [Paystack Docs](https://paystack.com/docs/)
- [Firebase Docs](https://firebase.google.com/docs/)
- [ngrok Docs](https://ngrok.com/docs/)
- [Project Repo](https://github.com/shulegram/payment-backend)

---

## ⚡ Pro Tips

1. **Use ngrok for local testing**
   ```bash
   ngrok http 3000
   ```

2. **Monitor logs in real-time**
   ```bash
   tail -f logs/webhook.log
   ```

3. **Test webhook events**
   ```bash
   ./scripts/test-webhook.sh success
   ```

4. **Validate phone before payment**
   ```bash
   curl ... /validate-phone
   ```

5. **Check payment status anytime**
   ```bash
   curl ... /status/reference
   ```

---

## 🎯 Workflow

```
User → Phone Validation
    ↓
Payment Initialization
    ↓
M-Pesa STK Push
    ↓
User Enters PIN
    ↓
Paystack Processes
    ↓
Webhook Sent
    ↓
Signature Verified
    ↓
Database Updated
    ↓
Booking Updated
    ↓
Complete ✅
```

---

## 📞 Support

For issues:
1. Check logs: `tail -f logs/webhook.log`
2. Review docs in `docs/` folder
3. Test with scripts: `./scripts/test-*.sh`
4. Check Paystack dashboard

---

**Last Updated**: December 3, 2025
**Version**: 1.0.0
