# Security Tests

This directory contains security-focused tests that validate the security posture of Purple MCP.

## Authentication Token Validation Tests

**File**: `test_auth_token_validation.sh`

This test suite validates the fix for the authentication bypass vulnerability (CVE-TBD) where the default `PURPLEMCP_AUTH_TOKEN` value allowed unauthorized access to the nginx proxy.

### What it tests:

1. **docker-compose.yml validation**:
   - Verifies the compose file requires `PURPLEMCP_AUTH_TOKEN` (uses `:?` syntax)
   - Confirms no default value is present (no `:-your-secure-token-here`)

2. **Nginx validation script**:
   - Confirms the validation script exists and is readable
   - Verifies it checks for empty tokens
   - Verifies it checks for known default/placeholder tokens
   - Verifies it enforces minimum token length (16 characters)

3. **Documentation**:
   - Confirms `.env.example` includes `PURPLEMCP_AUTH_TOKEN`
   - Confirms `.env.example` does not contain a default value
   - Confirms `SECURITY.md` documents the requirement
   - Confirms `deploy/README.md` documents the requirement

4. **Runtime validation**:
   - Tests that the validation script rejects empty tokens
   - Tests that the validation script rejects default tokens
   - Tests that the validation script rejects short tokens
   - Tests that the validation script accepts valid tokens

### Running the tests:

```bash
# From the repository root
bash tests/security/test_auth_token_validation.sh
```

### Expected output:

```
=== Purple MCP Authentication Token Validation Tests ===

Test 1: docker-compose.yml validation
✓ PASS - docker-compose.yml uses :? syntax to require token
Test 2: No default token in docker-compose.yml
✓ PASS - docker-compose.yml does not contain default token
...
Test 16: Validation script accepts valid token
✓ PASS - Script correctly accepts valid token

=== Test Summary ===
Tests passed: 16
Tests failed: 0

All tests passed! ✓

The authentication bypass vulnerability has been successfully mitigated.
```

## Integration with CI/CD

These tests are also integrated into the GitHub Actions workflow (`.github/workflows/docker-startup-tests.yml`) and run automatically on every pull request and push to main.

The CI tests include:
- Verification that the proxy refuses to start without `PURPLEMCP_AUTH_TOKEN`
- Verification that the proxy refuses to start with default tokens
- Verification that the proxy refuses to start with short tokens
- End-to-end authentication tests with valid tokens
