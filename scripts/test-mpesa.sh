#!/bin/bash

# M-Pesa Payment API Test Script
# Usage: ./test-mpesa.sh [endpoint_name]

# Configuration
API_KEY="${API_KEY:-YOUR_API_KEY}"
BASE_URL="${BASE_URL:-http://localhost:3000/api/payments}"
PHONE="${PHONE:-0712345678}"
EMAIL="${EMAIL:-test@example.com}"
AMOUNT="${AMOUNT:-500}"
BOOKING_ID="${BOOKING_ID:-booking_$(date +%s)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Install it for pretty JSON output:"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        echo "  macOS: brew install jq"
        echo "  Or download from: https://stedolan.github.io/jq/download/"
        exit 1
    fi
}

# Make API request and display response
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local headers=$4
    
    print_info "Request: $method $endpoint"
    if [ -n "$data" ]; then
        print_info "Data: $data"
    fi
    
    echo ""
    
    if [ -n "$data" ]; then
        response=$(curl -s -X "$method" "${BASE_URL}${endpoint}" \
            -H "x-api-key: ${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data" \
            -w "\nHTTP_CODE:%{http_code}")
    else
        response=$(curl -s -X "$method" "${BASE_URL}${endpoint}" \
            -H "x-api-key: ${API_KEY}" \
            -w "\nHTTP_CODE:%{http_code}")
    fi
    
    # Extract HTTP code
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    # Display response
    if [ "$http_code" -eq 200 ]; then
        echo "$response_body" | jq .
        print_success "Request successful (HTTP $http_code)"
    else
        echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
        print_error "Request failed (HTTP $http_code)"
    fi
    
    echo ""
    return $http_code
}

# Test functions
test_phone_validation() {
    print_header "Testing Phone Number Validation"
    
    make_request "POST" "/validate-phone" "{\"phone\": \"${PHONE}\"}"
}

test_initialize_payment() {
    print_header "Testing Payment Initialization"
    
    make_request "POST" "/initialize" "{
        \"email\": \"${EMAIL}\",
        \"amount\": ${AMOUNT},
        \"bookingId\": \"${BOOKING_ID}\",
        \"metadata\": {
            \"payment_type\": \"booking_fee\",
            \"user_id\": \"user_12345\"
        }
    }"
}

test_mpesa_payment() {
    print_header "Testing M-Pesa Payment (STK Push)"
    
    make_request "POST" "/mpesa" "{
        \"phone\": \"${PHONE}\",
        \"amount\": ${AMOUNT},
        \"email\": \"${EMAIL}\",
        \"bookingId\": \"${BOOKING_ID}\",
        \"metadata\": {
            \"payment_type\": \"escrow\",
            \"service_type\": \"tutoring\"
        }
    }"
}

test_direct_mpesa() {
    print_header "Testing Direct M-Pesa Payment"
    
    make_request "POST" "/mpesa/direct" "{
        \"phone\": \"${PHONE}\",
        \"amount\": ${AMOUNT},
        \"email\": \"${EMAIL}\",
        \"bookingId\": \"${BOOKING_ID}\",
        \"metadata\": {
            \"payment_type\": \"booking_fee\",
            \"urgent\": true
        }
    }"
}

test_payment_verification() {
    print_header "Testing Payment Verification"
    
    # Use a test reference (you can modify this)
    local test_ref="mpesa_test_$(date +%s)"
    make_request "GET" "/verify/${test_ref}"
}

test_payment_status() {
    print_header "Testing Get Payment Status"
    
    local test_ref="mpesa_test_$(date +%s)"
    make_request "GET" "/status/${test_ref}"
}

test_transaction_history() {
    print_header "Testing Transaction History"
    
    make_request "GET" "/history/${EMAIL}?limit=5&offset=0"
}

test_release_escrow() {
    print_header "Testing Escrow Release"
    
    make_request "POST" "/release-escrow" "{
        \"bookingId\": \"${BOOKING_ID}\",
        \"teacherPhone\": \"${PHONE}\",
        \"amount\": 5000
    }"
}

test_error_scenarios() {
    print_header "Testing Error Scenarios"
    
    print_info "Testing invalid phone number..."
    make_request "POST" "/validate-phone" "{\"phone\": \"invalid-phone\"}"
    
    print_info "Testing missing required fields..."
    make_request "POST" "/mpesa" "{\"phone\": \"${PHONE}\"}"
    
    print_info "Testing non-existent transaction..."
    make_request "GET" "/status/non-existent-reference"
    
    print_info "Testing invalid API key..."
    response=$(curl -s -X GET "${BASE_URL}/status/test" \
        -H "x-api-key: invalid-key" \
        -w "\nHTTP_CODE:%{http_code}")
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    if [ "$http_code" -eq 401 ]; then
        print_success "Authentication working correctly (HTTP $http_code)"
    else
        print_error "Authentication issue (HTTP $http_code)"
    fi
}

complete_flow_test() {
    print_header "Complete Payment Flow Test"
    
    print_info "Configuration:"
    echo "  API Key: ${API_KEY:0:10}..."
    echo "  Base URL: $BASE_URL"
    echo "  Phone: $PHONE"
    echo "  Email: $EMAIL"
    echo "  Amount: KES $AMOUNT"
    echo "  Booking ID: $BOOKING_ID"
    echo ""
    
    # Step 1: Validate phone
    print_info "Step 1: Validating phone number..."
    phone_response=$(curl -s -X POST "${BASE_URL}/validate-phone" \
        -H "x-api-key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"phone\": \"${PHONE}\"}")
    
    if echo "$phone_response" | jq -e '.success' > /dev/null 2>&1; then
        formatted_phone=$(echo "$phone_response" | jq -r '.data.formattedPhone')
        print_success "Phone validated: $formatted_phone"
    else
        print_error "Phone validation failed"
        return 1
    fi
    
    # Step 2: Initialize payment
    print_info "Step 2: Initializing payment..."
    init_response=$(curl -s -X POST "${BASE_URL}/initialize" \
        -H "x-api-key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"${EMAIL}\", \"amount\": ${AMOUNT}, \"bookingId\": \"${BOOKING_ID}\", \"metadata\": {\"payment_type\": \"booking_fee\"}}")
    
    if echo "$init_response" | jq -e '.success' > /dev/null 2>&1; then
        init_ref=$(echo "$init_response" | jq -r '.data.reference')
        print_success "Payment initialized: $init_ref"
    else
        print_error "Payment initialization failed"
        return 1
    fi
    
    # Step 3: Process M-Pesa payment
    print_info "Step 3: Processing M-Pesa payment..."
    mpesa_response=$(curl -s -X POST "${BASE_URL}/mpesa" \
        -H "x-api-key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"phone\": \"${PHONE}\", \"amount\": ${AMOUNT}, \"email\": \"${EMAIL}\", \"bookingId\": \"${BOOKING_ID}\", \"metadata\": {\"payment_type\": \"escrow\"}}")
    
    if echo "$mpesa_response" | jq -e '.success' > /dev/null 2>&1; then
        mpesa_ref=$(echo "$mpesa_response" | jq -r '.data.reference')
        print_success "M-Pesa payment initiated: $mpesa_ref"
        
        # Step 4: Check status
        print_info "Step 4: Checking payment status..."
        sleep 2  # Wait a bit for processing
        status_response=$(curl -s -X GET "${BASE_URL}/status/${mpesa_ref}" \
            -H "x-api-key: ${API_KEY}")
        
        echo "$status_response" | jq .
        
        # Step 5: Get transaction history
        print_info "Step 5: Getting transaction history..."
        history_response=$(curl -s -X GET "${BASE_URL}/history/${EMAIL}?limit=3" \
            -H "x-api-key: ${API_KEY}")
        
        echo "$history_response" | jq '.data.transactions | length'
        print_success "Transaction history retrieved"
        
    else
        print_error "M-Pesa payment failed"
        echo "$mpesa_response" | jq .
    fi
    
    print_success "Complete flow test finished!"
}

# Help function
show_help() {
    echo "M-Pesa Payment API Test Script"
    echo ""
    echo "Usage: $0 [endpoint_name]"
    echo ""
    echo "Available endpoints:"
    echo "  validate          - Test phone number validation"
    echo "  initialize        - Test payment initialization"
    echo "  mpesa             - Test M-Pesa STK push payment"
    echo "  direct            - Test direct M-Pesa payment"
    echo "  verify            - Test payment verification"
    echo "  status            - Test get payment status"
    echo "  history           - Test transaction history"
    echo "  escrow            - Test escrow release"
    echo "  errors            - Test error scenarios"
    echo "  flow              - Complete payment flow test"
    echo "  all               - Run all tests"
    echo ""
    echo "Environment variables:"
    echo "  API_KEY           - Your API key (required)"
    echo "  BASE_URL          - API base URL (default: http://localhost:3000/api/payments)"
    echo "  PHONE             - Test phone number (default: 0712345678)"
    echo "  EMAIL             - Test email (default: test@example.com)"
    echo "  AMOUNT            - Test amount (default: 500)"
    echo "  BOOKING_ID        - Test booking ID (auto-generated)"
    echo ""
    echo "Examples:"
    echo "  API_KEY=sk_test_xxx $0 flow"
    echo "  API_KEY=sk_test_xxx PHONE=0723456789 $0 mpesa"
    echo "  API_KEY=sk_test_xxx BASE_URL=https://api.example.com/payments $0 all"
}

# Run all tests
run_all_tests() {
    print_header "Running All Tests"
    
    test_phone_validation
    test_initialize_payment
    test_mpesa_payment
    test_direct_mpesa
    test_payment_verification
    test_payment_status
    test_transaction_history
    test_release_escrow
    test_error_scenarios
    
    print_success "All tests completed!"
}

# Main execution
main() {
    # Check dependencies
    check_dependencies
    
    # Check if API key is set
    if [ "$API_KEY" = "YOUR_API_KEY" ]; then
        print_error "Please set your API key:"
        echo "  export API_KEY=\"your-actual-api-key\""
        echo "  or run: API_KEY=\"your-key\" $0 $1"
        exit 1
    fi
    
    # Route to appropriate test based on argument
    case "${1:-help}" in
        "validate")
            test_phone_validation
            ;;
        "initialize")
            test_initialize_payment
            ;;
        "mpesa")
            test_mpesa_payment
            ;;
        "direct")
            test_direct_mpesa
            ;;
        "verify")
            test_payment_verification
            ;;
        "status")
            test_payment_status
            ;;
        "history")
            test_transaction_history
            ;;
        "escrow")
            test_release_escrow
            ;;
        "errors")
            test_error_scenarios
            ;;
        "flow")
            complete_flow_test
            ;;
        "all")
            run_all_tests
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown endpoint: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
