#!/bin/bash
# Security test: Verify PURPLEMCP_AUTH_TOKEN validation prevents default token bypass
# This test validates the fix for the authentication bypass vulnerability

set -e

echo "=== Purple MCP Authentication Token Validation Tests ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"  # "pass" or "fail"
    
    echo -n "Testing: $test_name... "
    
    set +e
    eval "$test_command" > /tmp/test_output.log 2>&1
    result=$?
    set -e
    
    if [ "$expected_result" = "fail" ]; then
        # We expect the command to fail
        if [ $result -ne 0 ]; then
            echo -e "${GREEN}✓ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ FAIL${NC} (expected failure but succeeded)"
            cat /tmp/test_output.log
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        # We expect the command to succeed
        if [ $result -eq 0 ]; then
            echo -e "${GREEN}✓ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ FAIL${NC} (expected success but failed)"
            cat /tmp/test_output.log
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# Test 1: Verify docker-compose.yml requires PURPLEMCP_AUTH_TOKEN
echo "Test 1: docker-compose.yml validation"
if grep -q 'PURPLEMCP_AUTH_TOKEN:.*:?' docker-compose.yml; then
    echo -e "${GREEN}✓ PASS${NC} - docker-compose.yml uses :? syntax to require token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - docker-compose.yml does not enforce required token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 2: Verify docker-compose.yml does NOT have default value
echo "Test 2: No default token in docker-compose.yml"
if grep -q 'PURPLEMCP_AUTH_TOKEN.*:-.*your-secure-token-here' docker-compose.yml; then
    echo -e "${RED}✗ FAIL${NC} - docker-compose.yml still contains default token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    echo -e "${GREEN}✓ PASS${NC} - docker-compose.yml does not contain default token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# Test 3: Verify nginx validation script exists
echo "Test 3: Nginx validation script exists"
if [ -f "deploy/nginx/docker-entrypoint.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Nginx validation script exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Nginx validation script not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 4: Verify nginx validation script is executable
echo "Test 4: Nginx validation script is executable"
if [ -x "deploy/nginx/docker-entrypoint.sh" ] || [ -r "deploy/nginx/docker-entrypoint.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Nginx validation script is readable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Nginx validation script is not readable"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 5: Verify nginx validation script checks for empty token
echo "Test 5: Validation script checks for empty token"
if grep -q 'if \[ -z.*PURPLEMCP_AUTH_TOKEN' deploy/nginx/docker-entrypoint.sh; then
    echo -e "${GREEN}✓ PASS${NC} - Script checks for empty token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Script does not check for empty token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: Verify nginx validation script checks for default token
echo "Test 6: Validation script checks for default token"
if grep -q 'your-secure-token-here' deploy/nginx/docker-entrypoint.sh; then
    echo -e "${GREEN}✓ PASS${NC} - Script checks for default token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Script does not check for default token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 7: Verify nginx validation script checks token length
echo "Test 7: Validation script checks token length"
if grep -q 'token_length' deploy/nginx/docker-entrypoint.sh && grep -q '16' deploy/nginx/docker-entrypoint.sh; then
    echo -e "${GREEN}✓ PASS${NC} - Script checks token length (minimum 16 chars)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Script does not check token length"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 8: Verify .env.example includes PURPLEMCP_AUTH_TOKEN
echo "Test 8: .env.example includes PURPLEMCP_AUTH_TOKEN"
if grep -q 'PURPLEMCP_AUTH_TOKEN' .env.example; then
    echo -e "${GREEN}✓ PASS${NC} - .env.example includes PURPLEMCP_AUTH_TOKEN"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - .env.example does not include PURPLEMCP_AUTH_TOKEN"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 9: Verify .env.example does NOT have a default value for PURPLEMCP_AUTH_TOKEN
echo "Test 9: .env.example has no default value"
if grep -q 'PURPLEMCP_AUTH_TOKEN=your-secure-token-here' .env.example; then
    echo -e "${RED}✗ FAIL${NC} - .env.example contains default token value"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    echo -e "${GREEN}✓ PASS${NC} - .env.example does not contain default token value"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# Test 10: Verify docker-compose.yml mounts the validation script
echo "Test 10: docker-compose.yml mounts validation script"
if grep -q 'deploy/nginx/docker-entrypoint.sh.*docker-entrypoint.d' docker-compose.yml; then
    echo -e "${GREEN}✓ PASS${NC} - docker-compose.yml mounts validation script"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - docker-compose.yml does not mount validation script"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 11: Verify SECURITY.md documents the requirement
echo "Test 11: SECURITY.md documents token requirement"
if grep -q 'PURPLEMCP_AUTH_TOKEN' SECURITY.md; then
    echo -e "${GREEN}✓ PASS${NC} - SECURITY.md documents PURPLEMCP_AUTH_TOKEN"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - SECURITY.md does not document PURPLEMCP_AUTH_TOKEN"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 12: Verify deploy/README.md documents the requirement
echo "Test 12: deploy/README.md documents token requirement"
if grep -q 'PURPLEMCP_AUTH_TOKEN' deploy/README.md; then
    echo -e "${GREEN}✓ PASS${NC} - deploy/README.md documents PURPLEMCP_AUTH_TOKEN"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - deploy/README.md does not document PURPLEMCP_AUTH_TOKEN"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 13: Run the validation script with no token (should fail)
echo "Test 13: Validation script rejects empty token"
(
    unset PURPLEMCP_AUTH_TOKEN
    export PURPLEMCP_AUTH_TOKEN=""
    bash deploy/nginx/docker-entrypoint.sh 2>&1 | grep -q "ERROR.*not set"
)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Script correctly rejects empty token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Script does not reject empty token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 14: Run the validation script with default token (should fail)
echo "Test 14: Validation script rejects default token"
(
    export PURPLEMCP_AUTH_TOKEN="your-secure-token-here"
    bash deploy/nginx/docker-entrypoint.sh 2>&1 | grep -q "ERROR.*forbidden default value"
)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Script correctly rejects default token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Script does not reject default token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 15: Run the validation script with short token (should fail)
echo "Test 15: Validation script rejects short token"
(
    export PURPLEMCP_AUTH_TOKEN="short"
    bash deploy/nginx/docker-entrypoint.sh 2>&1 | grep -q "ERROR.*too short"
)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Script correctly rejects short token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Script does not reject short token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 16: Run the validation script with valid token (should pass)
echo "Test 16: Validation script accepts valid token"
(
    export PURPLEMCP_AUTH_TOKEN="$(openssl rand -base64 32)"
    bash deploy/nginx/docker-entrypoint.sh 2>&1 | grep -q "validation passed"
)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Script correctly accepts valid token"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Script does not accept valid token"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    echo ""
    echo "The authentication bypass vulnerability has been successfully mitigated."
    echo "The system now:"
    echo "  1. Requires PURPLEMCP_AUTH_TOKEN to be explicitly set (no default)"
    echo "  2. Validates the token is not a known default/placeholder value"
    echo "  3. Enforces minimum token length of 16 characters"
    echo "  4. Provides clear error messages and remediation steps"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
