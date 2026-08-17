# Deployment Configurations

This directory contains deployment and infrastructure configurations.

## nginx/

Reverse proxy configuration for production deployments. See [nginx.conf.template](nginx/nginx.conf.template) for:
- Bearer token authentication
- HTTPS/TLS configuration
- Security headers
- Rate limiting
- Streaming support for MCP

### Security Requirements

**CRITICAL**: The nginx proxy requires `PURPLEMCP_AUTH_TOKEN` to be set to a cryptographically random value. This token protects the MCP backend from unauthorized access.

**Generate a secure token:**
```bash
openssl rand -base64 32
```

**Set in your .env file:**
```bash
PURPLEMCP_AUTH_TOKEN=<your-generated-token>
```

**Security validations:**
- The proxy container will refuse to start if `PURPLEMCP_AUTH_TOKEN` is not set
- The proxy will refuse to start if the token is set to a known default/placeholder value
- The proxy will refuse to start if the token is shorter than 16 characters
- Warnings are issued for tokens that appear weak (all lowercase, all digits, etc.)

These validations are enforced by [docker-entrypoint.sh](nginx/docker-entrypoint.sh), which runs automatically during container startup.

### Files

- **nginx.conf.template**: Nginx configuration template with environment variable substitution
- **docker-entrypoint.sh**: Startup validation script that enforces secure token requirements

Used by the `purple-mcp-proxy` service in [docker-compose.yml](../docker-compose.yml).

For production setup instructions, see [PRODUCTION_SETUP.md](../PRODUCTION_SETUP.md).

