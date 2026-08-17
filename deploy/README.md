# Deployment Configurations

This directory contains deployment and infrastructure configurations.

## nginx/

Reverse proxy configuration for production deployments. See [nginx.conf.template](nginx/nginx.conf.template) for:
- Bearer token authentication
- HTTPS/TLS configuration
- Security headers
- Rate limiting
- Streaming support for MCP

### Security Validation

The nginx proxy includes startup validation ([docker-entrypoint.sh](nginx/docker-entrypoint.sh)) that:
- Ensures `PURPLEMCP_AUTH_TOKEN` is set (no default fallback)
- Rejects the placeholder value `your-secure-token-here`
- Warns if token is shorter than 32 characters
- Prevents deployment with predictable authentication credentials

This validation runs before nginx starts, ensuring secure-by-default deployments.

Used by the `purple-mcp-proxy` service in [docker-compose.yml](../docker-compose.yml).

For production setup instructions, see [PRODUCTION_SETUP.md](../PRODUCTION_SETUP.md).
