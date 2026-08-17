#!/bin/sh
# Nginx proxy authentication token validation
# This script runs during nginx container startup (via /docker-entrypoint.d/)
# to ensure PURPLEMCP_AUTH_TOKEN is set to a secure value.

set -eu

# List of forbidden default/placeholder tokens
FORBIDDEN_TOKENS="your-secure-token-here test-token-123 changeme password admin"

if [ -z "${PURPLEMCP_AUTH_TOKEN:-}" ]; then
    echo "ERROR: PURPLEMCP_AUTH_TOKEN environment variable is not set!" >&2
    echo "" >&2
    echo "The nginx proxy requires a secure authentication token to protect the MCP backend." >&2
    echo "" >&2
    echo "Please generate a strong random token:" >&2
    echo "  openssl rand -base64 32" >&2
    echo "" >&2
    echo "And set it in your environment or .env file:" >&2
    echo "  PURPLEMCP_AUTH_TOKEN=<your-generated-token>" >&2
    echo "" >&2
    echo "Then restart the proxy container:" >&2
    echo "  docker compose restart purple-mcp-proxy" >&2
    exit 1
fi

# Check if token is in the forbidden list
for forbidden in $FORBIDDEN_TOKENS; do
    if [ "${PURPLEMCP_AUTH_TOKEN}" = "$forbidden" ]; then
        echo "ERROR: PURPLEMCP_AUTH_TOKEN is set to a forbidden default value: '$forbidden'" >&2
        echo "" >&2
        echo "This is a well-known placeholder token that must not be used in any deployment." >&2
        echo "Using default tokens allows authentication bypass by anyone who knows the repository." >&2
        echo "" >&2
        echo "Please generate a strong random token:" >&2
        echo "  openssl rand -base64 32" >&2
        echo "" >&2
        echo "And set it in your environment or .env file:" >&2
        echo "  PURPLEMCP_AUTH_TOKEN=<your-generated-token>" >&2
        exit 1
    fi
done

# Validate token length (minimum 16 characters for reasonable security)
token_length=${#PURPLEMCP_AUTH_TOKEN}
if [ "$token_length" -lt 16 ]; then
    echo "ERROR: PURPLEMCP_AUTH_TOKEN is too short (${token_length} characters)" >&2
    echo "" >&2
    echo "For security, the authentication token must be at least 16 characters long." >&2
    echo "Recommended: Use a cryptographically random token of 32+ characters." >&2
    echo "" >&2
    echo "Generate a secure token:" >&2
    echo "  openssl rand -base64 32" >&2
    echo "" >&2
    echo "And set it in your environment or .env file:" >&2
    echo "  PURPLEMCP_AUTH_TOKEN=<your-generated-token>" >&2
    exit 1
fi

# Warn if token appears to be weak (all lowercase, all digits, etc.)
if echo "${PURPLEMCP_AUTH_TOKEN}" | grep -qE '^[a-z]+$'; then
    echo "WARNING: PURPLEMCP_AUTH_TOKEN appears to contain only lowercase letters" >&2
    echo "This may indicate a weak token. Consider using a cryptographically random token:" >&2
    echo "  openssl rand -base64 32" >&2
    echo "" >&2
fi

if echo "${PURPLEMCP_AUTH_TOKEN}" | grep -qE '^[0-9]+$'; then
    echo "WARNING: PURPLEMCP_AUTH_TOKEN appears to contain only digits" >&2
    echo "This may indicate a weak token. Consider using a cryptographically random token:" >&2
    echo "  openssl rand -base64 32" >&2
    echo "" >&2
fi

echo "✓ PURPLEMCP_AUTH_TOKEN validation passed (length: ${token_length} characters)"
