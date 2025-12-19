#!/bin/bash

# CORS Testing Script
# Usage: ./test-cors.sh [api-url]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_URL="${1:-https://smap-api.tantai.dev}"
ORIGIN="https://smap.tantai.dev"

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }

echo "=================================="
echo "CORS Testing for SMAP Web"
echo "=================================="
echo ""
info "API URL: $API_URL"
info "Origin: $ORIGIN"
echo ""

# Test 1: OPTIONS Preflight
echo "Test 1: OPTIONS Preflight Request"
echo "----------------------------------"
RESPONSE=$(curl -s -X OPTIONS "$API_URL/identity/api/v1/auth/login" \
  -H "Origin: $ORIGIN" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -i -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
HEADERS=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
    success "OPTIONS request successful (HTTP $HTTP_CODE)"
else
    error "OPTIONS request failed (HTTP $HTTP_CODE)"
fi

# Check CORS headers
ALLOW_ORIGIN=$(echo "$HEADERS" | grep -i "Access-Control-Allow-Origin" | cut -d' ' -f2- | tr -d '\r')
ALLOW_CREDS=$(echo "$HEADERS" | grep -i "Access-Control-Allow-Credentials" | cut -d' ' -f2- | tr -d '\r')
ALLOW_METHODS=$(echo "$HEADERS" | grep -i "Access-Control-Allow-Methods" | cut -d' ' -f2- | tr -d '\r')

echo ""
echo "Response Headers:"
if [ -n "$ALLOW_ORIGIN" ]; then
    if [ "$ALLOW_ORIGIN" = "$ORIGIN" ]; then
        success "Access-Control-Allow-Origin: $ALLOW_ORIGIN"
    else
        warning "Access-Control-Allow-Origin: $ALLOW_ORIGIN (expected: $ORIGIN)"
    fi
else
    error "Access-Control-Allow-Origin: NOT FOUND"
fi

if [ -n "$ALLOW_CREDS" ]; then
    if [ "$ALLOW_CREDS" = "true" ]; then
        success "Access-Control-Allow-Credentials: $ALLOW_CREDS"
    else
        error "Access-Control-Allow-Credentials: $ALLOW_CREDS (expected: true)"
    fi
else
    error "Access-Control-Allow-Credentials: NOT FOUND"
fi

if [ -n "$ALLOW_METHODS" ]; then
    success "Access-Control-Allow-Methods: $ALLOW_METHODS"
else
    warning "Access-Control-Allow-Methods: NOT FOUND"
fi

echo ""
echo ""

# Test 2: Actual POST Request
echo "Test 2: POST Request with Origin"
echo "----------------------------------"
RESPONSE=$(curl -s -X POST "$API_URL/identity/api/v1/auth/login" \
  -H "Origin: $ORIGIN" \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}' \
  -i -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
HEADERS=$(echo "$RESPONSE" | sed '$d')

info "HTTP Status: $HTTP_CODE"

ALLOW_ORIGIN=$(echo "$HEADERS" | grep -i "Access-Control-Allow-Origin" | cut -d' ' -f2- | tr -d '\r')
ALLOW_CREDS=$(echo "$HEADERS" | grep -i "Access-Control-Allow-Credentials" | cut -d' ' -f2- | tr -d '\r')

echo ""
echo "Response Headers:"
if [ -n "$ALLOW_ORIGIN" ]; then
    if [ "$ALLOW_ORIGIN" = "$ORIGIN" ]; then
        success "Access-Control-Allow-Origin: $ALLOW_ORIGIN"
    else
        warning "Access-Control-Allow-Origin: $ALLOW_ORIGIN (expected: $ORIGIN)"
    fi
else
    error "Access-Control-Allow-Origin: NOT FOUND"
fi

if [ -n "$ALLOW_CREDS" ]; then
    if [ "$ALLOW_CREDS" = "true" ]; then
        success "Access-Control-Allow-Credentials: $ALLOW_CREDS"
    else
        error "Access-Control-Allow-Credentials: $ALLOW_CREDS (expected: true)"
    fi
else
    error "Access-Control-Allow-Credentials: NOT FOUND"
fi

echo ""
echo ""

# Summary
echo "=================================="
echo "Summary"
echo "=================================="
echo ""

ISSUES=0

if [ -z "$ALLOW_ORIGIN" ]; then
    error "Missing Access-Control-Allow-Origin header"
    ISSUES=$((ISSUES + 1))
elif [ "$ALLOW_ORIGIN" != "$ORIGIN" ]; then
    warning "Access-Control-Allow-Origin doesn't match origin"
    ISSUES=$((ISSUES + 1))
fi

if [ -z "$ALLOW_CREDS" ] || [ "$ALLOW_CREDS" != "true" ]; then
    error "Missing or incorrect Access-Control-Allow-Credentials header"
    ISSUES=$((ISSUES + 1))
fi

echo ""
if [ $ISSUES -eq 0 ]; then
    success "CORS configuration looks good!"
    echo ""
    info "Frontend should be able to make API calls with credentials."
else
    error "Found $ISSUES CORS issue(s)"
    echo ""
    warning "Backend needs to:"
    echo "  1. Add '$ORIGIN' to allowed origins"
    echo "  2. Set AllowCredentials: true"
    echo "  3. Handle OPTIONS requests"
    echo ""
    info "See k8s/CORS_DEBUG.md for detailed fix instructions"
fi

echo ""
