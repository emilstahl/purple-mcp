"""Remote access security validation for MCP tools.

This module provides security controls for MCP tool invocations when the server
is exposed remotely. It enforces that production deployments with remote access
must explicitly acknowledge the security risks and implement proper authentication
at the reverse proxy layer.

The validation follows the principle of secure-by-default: remote tool invocations
in production environments are blocked unless explicitly enabled with proper
acknowledgment of security responsibilities.
"""

import logging
import os
from typing import Final

logger = logging.getLogger(__name__)

# Environment variable for remote access mode
REMOTE_ACCESS_MODE_ENV: Final[str] = "PURPLEMCP_REMOTE_ACCESS_MODE"

# Valid remote access modes
REMOTE_ACCESS_MODE_DISABLED: Final[str] = "disabled"
REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY: Final[str] = "authenticated_proxy"

# Security messages
REMOTE_ACCESS_BLOCKED_ERROR: Final[str] = (
    "SECURITY ERROR: Remote tool invocation blocked in production environment. "
    "Purple MCP has no built-in authentication. When exposing the MCP server remotely, "
    "you MUST place it behind a reverse proxy with strong authentication (SAML/OIDC SSO, "
    "mutual TLS, or signed API tokens). "
    "To acknowledge this requirement and enable remote access, set: "
    f"{REMOTE_ACCESS_MODE_ENV}={REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY}"
)

REMOTE_ACCESS_PRODUCTION_WARNING: Final[str] = (
    "WARNING: Remote MCP tool invocations enabled in production. "
    "Ensure this service is behind an authenticated reverse proxy. "
    "All tool invocations are fully trusted and can access sensitive data."
)

REMOTE_ACCESS_DEVELOPMENT_WARNING: Final[str] = (
    "WARNING: Remote MCP tool invocations enabled in development mode. "
    "This should only be used in trusted development environments."
)


def is_remote_transport(transport_mode: str) -> bool:
    """Check if the transport mode allows remote access.

    Args:
        transport_mode: The MCP transport mode (stdio, http, streamable-http, sse)

    Returns:
        True if the transport mode allows remote network access
    """
    return transport_mode.lower() in ("http", "streamable-http", "sse")


def is_production_environment(environment: str) -> bool:
    """Check if the environment is production.

    Args:
        environment: Environment string to check

    Returns:
        True if the environment is considered production
    """
    return environment.lower() in ("production", "prod")


def get_remote_access_mode() -> str:
    """Get the configured remote access mode.

    Returns:
        The remote access mode from environment variable, or 'disabled' if not set
    """
    return os.getenv(REMOTE_ACCESS_MODE_ENV, REMOTE_ACCESS_MODE_DISABLED).lower()


def validate_remote_tool_invocation(
    transport_mode: str,
    environment: str,
    tool_name: str,
) -> None:
    """Validate that remote tool invocation is allowed in the current configuration.

    This function enforces security controls for remote MCP tool invocations:
    - In production with remote transport: Requires explicit acknowledgment via
      PURPLEMCP_REMOTE_ACCESS_MODE=authenticated_proxy
    - In development with remote transport: Issues warning but allows invocation
    - In stdio mode: Always allows invocation (local use)

    Args:
        transport_mode: The MCP transport mode (stdio, http, streamable-http, sse)
        environment: The environment name (production, development, etc.)
        tool_name: The name of the tool being invoked (for logging)

    Raises:
        RuntimeError: If remote tool invocation is not allowed in the current configuration
    """
    # stdio mode is always safe (local process communication)
    if not is_remote_transport(transport_mode):
        return

    # Check if we're in production
    if is_production_environment(environment):
        remote_access_mode = get_remote_access_mode()

        # In production with remote transport, require explicit acknowledgment
        if remote_access_mode != REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY:
            logger.critical(
                "Remote tool invocation blocked in production without authentication acknowledgment",
                extra={
                    "tool_name": tool_name,
                    "transport_mode": transport_mode,
                    "environment": environment,
                    "remote_access_mode": remote_access_mode,
                },
            )
            raise RuntimeError(REMOTE_ACCESS_BLOCKED_ERROR)

        # Log warning that remote access is enabled in production
        logger.warning(
            REMOTE_ACCESS_PRODUCTION_WARNING,
            extra={
                "tool_name": tool_name,
                "transport_mode": transport_mode,
                "environment": environment,
            },
        )
    else:
        # In non-production environments, issue warning but allow
        logger.warning(
            REMOTE_ACCESS_DEVELOPMENT_WARNING,
            extra={
                "tool_name": tool_name,
                "transport_mode": transport_mode,
                "environment": environment,
            },
        )


def log_tool_invocation_security_context(
    tool_name: str,
    transport_mode: str,
    environment: str,
) -> None:
    """Log security context for tool invocation.

    Args:
        tool_name: The name of the tool being invoked
        transport_mode: The MCP transport mode
        environment: The environment name
    """
    is_remote = is_remote_transport(transport_mode)
    is_prod = is_production_environment(environment)
    remote_mode = get_remote_access_mode() if is_remote else "n/a"

    logger.debug(
        "Tool invocation security context",
        extra={
            "tool_name": tool_name,
            "transport_mode": transport_mode,
            "environment": environment,
            "is_remote_transport": is_remote,
            "is_production": is_prod,
            "remote_access_mode": remote_mode,
        },
    )
