#!/bin/sh
set -eu

# Validate PURPLEMCP_AUTH_TOKEN is set and not the default placeholder
if [ -z "${PURPLEMCP_AUTH_TOKEN:-}" ]; then
    echo "ERROR: PURPLEMCP_AUTH_TOKEN environment variable is not set!" >&2
    echo "The nginx proxy requires a bearer token for authentication." >&2
    echo "" >&2
    echo "Please generate a strong random token:" >&2
    echo "  openssl rand -base64 32" >&2
    echo "" >&2
    echo "And set it in your environment or .env file:" >&2
    echo "  PURPLEMCP_AUTH_TOKEN=<your-generated-token>" >&2
    echo "" >&2
    echo "Then restart the proxy service:" >&2
    echo "  docker compose restart purple-mcp-proxy" >&2
    exit 1
fi

if [ "${PURPLEMCP_AUTH_TOKEN}" = "your-secure-token-here" ]; then
    echo "ERROR: Default placeholder token detected!" >&2
    echo "The PURPLEMCP_AUTH_TOKEN environment variable is set to 'your-secure-token-here'," >&2
    echo "which is the default placeholder value and must not be used." >&2
    echo "" >&2
    echo "Please generate a strong random token:" >&2
    echo "  openssl rand -base64 32" >&2
    echo "" >&2
    echo "And set it in your environment or .env file:" >&2
    echo "  PURPLEMCP_AUTH_TOKEN=<your-generated-token>" >&2
    echo "" >&2
    echo "Then restart the proxy service:" >&2
    echo "  docker compose restart purple-mcp-proxy" >&2
    exit 1
fi

# Validate token meets minimum security requirements
TOKEN_LENGTH=${#PURPLEMCP_AUTH_TOKEN}
if [ "$TOKEN_LENGTH" -lt 32 ]; then
    echo "WARNING: PURPLEMCP_AUTH_TOKEN is shorter than recommended (${TOKEN_LENGTH} characters)." >&2
    echo "For production deployments, use at least 32 characters:" >&2
    echo "  openssl rand -base64 32" >&2
    echo "" >&2
fi

echo "PURPLEMCP_AUTH_TOKEN validation passed. Starting nginx..."

# Execute the original nginx entrypoint
exec /docker-entrypoint.sh "$@"
