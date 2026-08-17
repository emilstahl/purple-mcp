"""Unit tests for remote access security validation."""

import os
from unittest.mock import patch

import pytest

from purple_mcp.remote_access_security import (
    REMOTE_ACCESS_BLOCKED_ERROR,
    REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY,
    REMOTE_ACCESS_MODE_DISABLED,
    REMOTE_ACCESS_MODE_ENV,
    get_remote_access_mode,
    is_production_environment,
    is_remote_transport,
    validate_remote_tool_invocation,
)


class TestIsRemoteTransport:
    """Test is_remote_transport function."""

    def test_stdio_is_not_remote(self) -> None:
        """Test that stdio transport is not considered remote."""
        assert not is_remote_transport("stdio")

    def test_http_is_remote(self) -> None:
        """Test that http transport is considered remote."""
        assert is_remote_transport("http")

    def test_streamable_http_is_remote(self) -> None:
        """Test that streamable-http transport is considered remote."""
        assert is_remote_transport("streamable-http")

    def test_sse_is_remote(self) -> None:
        """Test that sse transport is considered remote."""
        assert is_remote_transport("sse")

    def test_case_insensitive(self) -> None:
        """Test that transport mode check is case insensitive."""
        assert is_remote_transport("HTTP")
        assert is_remote_transport("SSE")
        assert is_remote_transport("STREAMABLE-HTTP")
        assert not is_remote_transport("STDIO")


class TestIsProductionEnvironment:
    """Test is_production_environment function."""

    def test_production_is_production(self) -> None:
        """Test that 'production' is recognized as production."""
        assert is_production_environment("production")

    def test_prod_is_production(self) -> None:
        """Test that 'prod' is recognized as production."""
        assert is_production_environment("prod")

    def test_development_is_not_production(self) -> None:
        """Test that 'development' is not production."""
        assert not is_production_environment("development")

    def test_staging_is_not_production(self) -> None:
        """Test that 'staging' is not production."""
        assert not is_production_environment("staging")

    def test_case_insensitive(self) -> None:
        """Test that environment check is case insensitive."""
        assert is_production_environment("PRODUCTION")
        assert is_production_environment("Prod")
        assert not is_production_environment("DEVELOPMENT")


class TestGetRemoteAccessMode:
    """Test get_remote_access_mode function."""

    def test_returns_disabled_when_not_set(self) -> None:
        """Test that disabled is returned when env var is not set."""
        with patch.dict(os.environ, {}, clear=True):
            assert get_remote_access_mode() == REMOTE_ACCESS_MODE_DISABLED

    def test_returns_authenticated_proxy_when_set(self) -> None:
        """Test that authenticated_proxy is returned when set."""
        with patch.dict(
            os.environ, {REMOTE_ACCESS_MODE_ENV: REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY}
        ):
            assert get_remote_access_mode() == REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY

    def test_case_insensitive(self) -> None:
        """Test that mode is normalized to lowercase."""
        with patch.dict(os.environ, {REMOTE_ACCESS_MODE_ENV: "AUTHENTICATED_PROXY"}):
            assert get_remote_access_mode() == REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY


class TestValidateRemoteToolInvocation:
    """Test validate_remote_tool_invocation function."""

    def test_stdio_always_allowed(self) -> None:
        """Test that stdio transport is always allowed regardless of environment."""
        # Should not raise in production with stdio
        validate_remote_tool_invocation(
            transport_mode="stdio",
            environment="production",
            tool_name="test_tool",
        )

        # Should not raise in development with stdio
        validate_remote_tool_invocation(
            transport_mode="stdio",
            environment="development",
            tool_name="test_tool",
        )

    def test_production_remote_blocked_without_acknowledgment(self) -> None:
        """Test that remote transport in production is blocked without acknowledgment."""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(RuntimeError) as exc_info:
                validate_remote_tool_invocation(
                    transport_mode="sse",
                    environment="production",
                    tool_name="powerquery",
                )

            assert REMOTE_ACCESS_BLOCKED_ERROR in str(exc_info.value)
            assert REMOTE_ACCESS_MODE_ENV in str(exc_info.value)

    def test_production_remote_allowed_with_acknowledgment(self) -> None:
        """Test that remote transport in production is allowed with acknowledgment."""
        with patch.dict(
            os.environ,
            {REMOTE_ACCESS_MODE_ENV: REMOTE_ACCESS_MODE_AUTHENTICATED_PROXY},
        ):
            # Should not raise
            validate_remote_tool_invocation(
                transport_mode="sse",
                environment="production",
                tool_name="powerquery",
            )

    def test_development_remote_allowed_without_acknowledgment(self) -> None:
        """Test that remote transport in development is allowed without acknowledgment."""
        with patch.dict(os.environ, {}, clear=True):
            # Should not raise
            validate_remote_tool_invocation(
                transport_mode="sse",
                environment="development",
                tool_name="powerquery",
            )

    def test_all_remote_transports_checked(self) -> None:
        """Test that all remote transport modes are properly validated."""
        remote_transports = ["http", "streamable-http", "sse"]

        for transport in remote_transports:
            with patch.dict(os.environ, {}, clear=True):
                with pytest.raises(RuntimeError) as exc_info:
                    validate_remote_tool_invocation(
                        transport_mode=transport,
                        environment="production",
                        tool_name="test_tool",
                    )

                assert REMOTE_ACCESS_BLOCKED_ERROR in str(exc_info.value)

    def test_prod_environment_also_blocked(self) -> None:
        """Test that 'prod' environment is also treated as production."""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(RuntimeError) as exc_info:
                validate_remote_tool_invocation(
                    transport_mode="sse",
                    environment="prod",
                    tool_name="powerquery",
                )

            assert REMOTE_ACCESS_BLOCKED_ERROR in str(exc_info.value)

    def test_staging_environment_allowed(self) -> None:
        """Test that staging environment allows remote access without acknowledgment."""
        with patch.dict(os.environ, {}, clear=True):
            # Should not raise
            validate_remote_tool_invocation(
                transport_mode="sse",
                environment="staging",
                tool_name="powerquery",
            )

    def test_case_insensitive_environment(self) -> None:
        """Test that environment check is case insensitive."""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(RuntimeError):
                validate_remote_tool_invocation(
                    transport_mode="sse",
                    environment="PRODUCTION",
                    tool_name="test_tool",
                )

            with pytest.raises(RuntimeError):
                validate_remote_tool_invocation(
                    transport_mode="sse",
                    environment="Prod",
                    tool_name="test_tool",
                )

    def test_case_insensitive_transport(self) -> None:
        """Test that transport mode check is case insensitive."""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(RuntimeError):
                validate_remote_tool_invocation(
                    transport_mode="SSE",
                    environment="production",
                    tool_name="test_tool",
                )

            # stdio should still work regardless of case
            validate_remote_tool_invocation(
                transport_mode="STDIO",
                environment="production",
                tool_name="test_tool",
            )
