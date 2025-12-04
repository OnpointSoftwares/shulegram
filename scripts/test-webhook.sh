#!/bin/bash

# Paystack Webhook Testing Script
# Tests webhook functionality locally or with ngrok

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WEBHOOK_URL="${WEBHOOK_URL:-http://localhost:3000/api/payments/webhook}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-your-webhook-secret}"

print_header() {
    echo -e "${BLUE}==================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Generate HMAC-SHA512 signature
generate_signature() {
    local payload=$1
    echo -n "$payload" | openssl dgst -sha512 -hmac "$WEBHOOK_SECRET" -hex | sed 's/^.* //'
}

# Test charge.success event
test_charge_success() {
    print_header "Testing charge.success Event"
    
    local reference="mpesa_success_$(date +%s)"
    local payload=$(cat <<EOF
{
  "event": "charge.success",
  "data": {
    "id": 123456789,
    "reference": "$reference",
    "amount": 50000,
    "currency": "KES",
    "status": "success",
    "paid_at": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "channel": "mobile_money",
    "customer": {
      "email": "test@example.com"
    },
    "metadata": {
      "booking_id": "booking_test_$(date +%s)",
      "payment_type": "escrow",
      "user_id": "user_test"
    },
    "gateway_response": "Successful"
  }
}
EOF
)
    
    local signature=$(generate_signature "$payload")
    
    print_info "Sending charge.success webhook..."
    print_info "Reference: $reference"
    print_info "Signature: ${signature:0:20}..."
    
    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "x-paystack-signature: $signature" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        -w "\nHTTP_CODE:%{http_code}")
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    if [ "$http_code" -eq 200 ]; then
        print_success "Webhook processed (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    else
        print_error "Webhook failed (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    
    echo ""
}

# Test charge.failed event
test_charge_failed() {
    print_header "Testing charge.failed Event"
    
    local reference="mpesa_failed_$(date +%s)"
    local payload=$(cat <<EOF
{
  "event": "charge.failed",
  "data": {
    "id": 123456790,
    "reference": "$reference",
    "amount": 50000,
    "currency": "KES",
    "status": "failed",
    "paid_at": null,
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "channel": "mobile_money",
    "customer": {
      "email": "test@example.com"
    },
    "metadata": {
      "booking_id": "booking_test_$(date +%s)",
      "payment_type": "escrow"
    },
    "gateway_response": "Insufficient funds"
  }
}
EOF
)
    
    local signature=$(generate_signature "$payload")
    
    print_info "Sending charge.failed webhook..."
    print_info "Reference: $reference"
    
    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "x-paystack-signature: $signature" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        -w "\nHTTP_CODE:%{http_code}")
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    if [ "$http_code" -eq 200 ]; then
        print_success "Webhook processed (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    else
        print_error "Webhook failed (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    
    echo ""
}

# Test transfer.success event
test_transfer_success() {
    print_header "Testing transfer.success Event"
    
    local reference="transfer_success_$(date +%s)"
    local payload=$(cat <<EOF
{
  "event": "transfer.success",
  "data": {
    "reference": "$reference",
    "amount": 100000,
    "currency": "KES",
    "status": "success",
    "recipient": {
      "type": "mobile_money",
      "name": "Teacher Name"
    },
    "reason": "Escrow release for booking"
  }
}
EOF
)
    
    local signature=$(generate_signature "$payload")
    
    print_info "Sending transfer.success webhook..."
    
    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "x-paystack-signature: $signature" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        -w "\nHTTP_CODE:%{http_code}")
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    if [ "$http_code" -eq 200 ]; then
        print_success "Webhook processed (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    else
        print_error "Webhook failed (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    
    echo ""
}

# Test invalid signature
test_invalid_signature() {
    print_header "Testing Invalid Signature (Should Fail)"
    
    local payload=$(cat <<EOF
{
  "event": "charge.success",
  "data": {
    "reference": "test_invalid_sig",
    "amount": 50000,
    "status": "success"
  }
}
EOF
)
    
    print_info "Sending webhook with invalid signature..."
    
    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "x-paystack-signature: invalid_signature_12345" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        -w "\nHTTP_CODE:%{http_code}")
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    if [ "$http_code" -eq 401 ]; then
        print_success "Correctly rejected invalid signature (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    else
        print_error "Should have rejected invalid signature (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    
    echo ""
}

# Test missing signature
test_missing_signature() {
    print_header "Testing Missing Signature (Should Fail)"
    
    local payload=$(cat <<EOF
{
  "event": "charge.success",
  "data": {
    "reference": "test_no_sig",
    "amount": 50000,
    "status": "success"
  }
}
EOF
)
    
    print_info "Sending webhook without signature..."
    
    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        -w "\nHTTP_CODE:%{http_code}")
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    if [ "$http_code" -eq 401 ]; then
        print_success "Correctly rejected missing signature (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    else
        print_error "Should have rejected missing signature (HTTP $http_code)"
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    fi
    
    echo ""
}

# Show help
show_help() {
    echo "Paystack Webhook Testing Script"
    echo ""
    echo "Usage: $0 [test_name]"
    echo ""
    echo "Available tests:"
    echo "  success         - Test charge.success event"
    echo "  failed          - Test charge.failed event"
    echo "  transfer        - Test transfer.success event"
    echo "  invalid-sig     - Test invalid signature rejection"
    echo "  missing-sig     - Test missing signature rejection"
    echo "  all             - Run all tests"
    echo "  help            - Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  WEBHOOK_URL     - Webhook URL (default: http://localhost:3000/api/payments/webhook)"
    echo "  WEBHOOK_SECRET  - Webhook secret (default: your-webhook-secret)"
    echo ""
    echo "Examples:"
    echo "  $0 success"
    echo "  WEBHOOK_SECRET=whsec_xxx $0 all"
    echo "  WEBHOOK_URL=https://abc123.ngrok.io/api/payments/webhook $0 success"
}

# Run all tests
run_all_tests() {
    print_header "Running All Webhook Tests"
    
    echo "Configuration:"
    echo "  Webhook URL: $WEBHOOK_URL"
    echo "  Webhook Secret: ${WEBHOOK_SECRET:0:20}..."
    echo ""
    
    test_charge_success
    test_charge_failed
    test_transfer_success
    test_invalid_signature
    test_missing_signature
    
    print_success "All tests completed!"
}

# Main execution
main() {
    case "${1:-help}" in
        "success")
            test_charge_success
            ;;
        "failed")
            test_charge_failed
            ;;
        "transfer")
            test_transfer_success
            ;;
        "invalid-sig")
            test_invalid_signature
            ;;
        "missing-sig")
            test_missing_signature
            ;;
        "all")
            run_all_tests
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown test: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
