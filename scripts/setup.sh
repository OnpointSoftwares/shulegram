#!/bin/bash

# ShulePearl Payment Backend Setup Script

echo "🚀 ShulePearl Payment Backend Setup"
echo "===================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Check if .env file exists
if [ -f ".env" ]; then
    print_info ".env file already exists"
    echo "Current .env file contents:"
    echo "---------------------------"
    cat .env | grep -v "FIREBASE_PRIVATE_KEY" | head -10
    echo "---------------------------"
    echo ""
    read -p "Do you want to recreate .env file? (y/N): " recreate
    if [[ ! $recreate =~ ^[Yy]$ ]]; then
        print_info "Keeping existing .env file"
        exit 0
    fi
fi

print_header "Creating .env file"

# Generate a random API secret
API_SECRET=$(openssl rand -hex 32 2>/dev/null || date +%s | sha256sum | base64 | head -c 32)

# Create .env file
cat > .env << EOF
# ShulePearl Payment Backend Environment Variables

# API Authentication (Auto-generated)
API_SECRET=${API_SECRET}

# Paystack Configuration (Get from Paystack dashboard)
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Firebase Configuration (Get from Firebase console)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_HERE
-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# Server Configuration
PORT=3000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Security
CORS_ORIGIN=*
CSP_REPORT_ONLY=false
EOF

print_success ".env file created successfully!"

print_header "API Key Information"
echo ""
echo "Your API Secret (for testing):"
echo "${API_SECRET}"
echo ""
echo "Use this as your API_KEY when testing:"
echo "export API_KEY=\"${API_SECRET}\""
echo ""

print_header "Next Steps"
echo ""
echo "1. Get Paystack API Keys:"
echo "   - Go to https://dashboard.paystack.co/"
echo "   - Sign up or log in"
echo "   - Go to Settings → API Keys"
echo "   - Copy your Test Secret Key (starts with sk_test_)"
echo "   - Update PAYSTACK_SECRET_KEY in .env file"
echo ""
echo "2. Set up Firebase:"
echo "   - Go to https://console.firebase.google.com/"
echo "   - Create a new project or use existing"
echo "   - Go to Project Settings → Service Accounts"
echo "   - Generate a new private key"
echo "   - Update FIREBASE_* variables in .env file"
echo ""
echo "3. Install dependencies:"
echo "   npm install"
echo ""
echo "4. Start the server:"
echo "   npm start"
echo "   # or for development:"
echo "   npm run dev"
echo ""
echo "5. Test the API:"
echo "   # Install jq for pretty output:"
echo "   sudo apt-get install jq  # Ubuntu/Debian"
echo "   brew install jq          # macOS"
echo ""
echo "   # Run tests:"
echo "   API_KEY=\"${API_SECRET}\" ./scripts/test-mpesa.sh all"
echo ""

print_header "Quick Test Commands"
echo ""
echo "# Test phone validation:"
echo "curl -X POST http://localhost:3000/api/payments/validate-phone \\"
echo "  -H \"x-api-key: ${API_SECRET}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"phone\": \"0712345678\"}'"
echo ""

print_success "Setup completed!"
print_info "Remember to update .env with your actual Paystack and Firebase credentials"
