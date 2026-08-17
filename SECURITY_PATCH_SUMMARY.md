# Remote Access Security Control - Implementation Summary

## Overview

This patch implements runtime security controls to prevent unauthenticated remote execution of MCP tools in production environments. The implementation follows the principle of secure-by-default while maintaining backward compatibility for local (stdio) usage.

## Security Issue

**Problem:** When the MCP server is exposed remotely (HTTP/SSE transport), all tools including `powerquery` can be invoked without authentication, allowing arbitrary SDL query execution and data exfiltration.

**Root Cause:** No enforcement mechanism exists to ensure production deployments implement proper authentication at the reverse proxy layer.

## Solution

### 1. New Security Module (`src/purple_mcp/remote_access_security.py`)

Created a dedicated security module that provides:
- Runtime validation of remote tool invocations
- Environment-aware security controls
- Clear error messages guiding operators to proper setup

### 2. Environment Variable: `PURPLEMCP_REMOTE_ACCESS_MODE`

**Purpose:** Explicit acknowledgment that proper authentication is implemented

**Values:**
- `disabled` (default): Remote tool invocations blocked in production
- `authenticated_proxy`: Confirms service is behind authenticated reverse proxy

**Behavior:**
- **Production + Remote Transport + Not Set**: Tool invocations are BLOCKED with clear error message
- **Production + Remote Transport + Set to `authenticated_proxy`**: Tool invocations allowed with warning
- **Development + Remote Transport**: Tool invocations allowed with warning
- **stdio Transport (any environment)**: Always allowed (local use, no network exposure)

### 3. Tool-Level Validation

Updated `powerquery` tool in `src/purple_mcp/tools/sdl.py`:
- Added validation call at the start of tool execution
- Validates before any query processing occurs
- Raises `RuntimeError` with actionable error message if blocked

### 4. Enhanced CLI Warnings

Updated `src/purple_mcp/cli.py`:
- Enhanced security warning display when binding to non-loopback addresses
- Shows current environment and remote access mode status
- Provides clear instructions for enabling remote access in production

### 5. Docker Integration

Updated `docker-entrypoint.sh`:
- Checks for `PURPLEMCP_REMOTE_ACCESS_MODE` in production
- Displays security notice if not set
- Guides operators to proper configuration

### 6. Documentation Updates

**SECURITY.md:**
- Added remote access security controls section
- Documented the new environment variable requirement
- Updated deployment checklist

**PRODUCTION_SETUP.md:**
- Added `PURPLEMCP_REMOTE_ACCESS_MODE=authenticated_proxy` to setup instructions
- Explained the security requirement

**README.md:**
- Added environment variable documentation
- Updated security warnings
- Linked to production setup guide

**docker-compose.yml:**
- Added `PURPLEMCP_REMOTE_ACCESS_MODE` to service configurations

### 7. Comprehensive Tests

Created `tests/unit/test_remote_access_security.py`:
- Tests for all transport modes (stdio, http, sse, streamable-http)
- Tests for all environments (production, development, staging)
- Tests for acknowledgment requirement
- Case-insensitivity tests
- Edge case coverage

## Security Properties

### Defense in Depth
1. **CLI Warning**: Operators see prominent warnings when binding to non-loopback
2. **Docker Notice**: Container startup shows security notice in production
3. **Runtime Enforcement**: Tool invocations are blocked at execution time
4. **Clear Guidance**: Error messages provide exact steps to resolve

### Backward Compatibility
- **stdio mode**: No changes, always works (local use)
- **Development environments**: No changes, warnings only
- **Existing production deployments**: Will be blocked until `PURPLEMCP_REMOTE_ACCESS_MODE` is set

### Fail-Safe Design
- Defaults to most secure configuration (blocked)
- Requires explicit opt-in for remote access in production
- Cannot be accidentally bypassed

## Migration Path for Existing Deployments

For production deployments with remote access:

1. Verify reverse proxy authentication is properly configured
2. Set environment variable: `PURPLEMCP_REMOTE_ACCESS_MODE=authenticated_proxy`
3. Restart service

Example:
```bash
# Add to .env file
PURPLEMCP_REMOTE_ACCESS_MODE=authenticated_proxy

# Or set in docker-compose.yml
environment:
  PURPLEMCP_REMOTE_ACCESS_MODE: authenticated_proxy
```

## Files Modified

### New Files
- `src/purple_mcp/remote_access_security.py` - Security validation module
- `tests/unit/test_remote_access_security.py` - Comprehensive test suite

### Modified Files
- `src/purple_mcp/tools/sdl.py` - Added validation to powerquery tool
- `src/purple_mcp/config.py` - Added REMOTE_ACCESS_MODE_ENV constant
- `src/purple_mcp/cli.py` - Enhanced security warnings
- `docker-entrypoint.sh` - Added production security notice
- `docker-compose.yml` - Added environment variable to services
- `SECURITY.md` - Documented security controls
- `PRODUCTION_SETUP.md` - Updated setup instructions
- `README.md` - Updated environment variables and warnings

## Testing

Run the test suite to verify:
```bash
uv run pytest tests/unit/test_remote_access_security.py -v
```

## Verification

To verify the security control is working:

1. **Test blocking in production without acknowledgment:**
```bash
export PURPLEMCP_ENV=production
export PURPLEMCP_CONSOLE_TOKEN=your_token
export PURPLEMCP_CONSOLE_BASE_URL=https://your-console.sentinelone.net
# Do NOT set PURPLEMCP_REMOTE_ACCESS_MODE

# Try to run with remote transport - should fail
uvx purple-mcp --mode sse --host 0.0.0.0 --port 8000 --allow-remote-access

# Attempt to invoke powerquery - should be blocked with clear error
```

2. **Test allowing with acknowledgment:**
```bash
export PURPLEMCP_REMOTE_ACCESS_MODE=authenticated_proxy

# Now remote access should work (with warnings)
uvx purple-mcp --mode sse --host 0.0.0.0 --port 8000 --allow-remote-access
```

3. **Test stdio always works:**
```bash
# stdio mode should always work regardless of settings
uvx purple-mcp --mode stdio
```

## Security Considerations

### What This Patch Does
- ✅ Blocks unauthenticated remote tool invocations in production by default
- ✅ Requires explicit acknowledgment of authentication responsibility
- ✅ Provides clear error messages and guidance
- ✅ Maintains backward compatibility for local usage

### What This Patch Does NOT Do
- ❌ Does not implement authentication (operator responsibility)
- ❌ Does not verify that authentication is actually configured
- ❌ Does not protect against misconfigured reverse proxies
- ❌ Does not prevent operators from setting the acknowledgment without proper auth

### Operator Responsibilities
Operators MUST:
1. Implement strong authentication at the reverse proxy layer
2. Only set `PURPLEMCP_REMOTE_ACCESS_MODE=authenticated_proxy` after authentication is verified
3. Monitor for unauthorized access attempts
4. Follow the production setup guide

## Conclusion

This patch implements a defense-in-depth approach to prevent unauthenticated remote tool invocations while maintaining usability for legitimate use cases. The secure-by-default design ensures that production deployments cannot accidentally expose tools without proper authentication acknowledgment.
