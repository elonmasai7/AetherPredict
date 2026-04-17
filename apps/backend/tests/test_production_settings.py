import pytest

from app.core.config import Settings


def test_production_requires_strong_jwt_secret():
    with pytest.raises(ValueError, match="JWT_SECRET"):
        Settings(
            app_env="production",
            jwt_secret="change-me",
            cors_allowed_origins=["https://app.example.com"],
            api_docs_enabled=False,
        )


def test_production_rejects_wildcard_cors():
    with pytest.raises(ValueError, match="wildcard CORS"):
        Settings(
            app_env="production",
            jwt_secret="x" * 32,
            cors_allowed_origins=["*"],
            api_docs_enabled=False,
        )


def test_production_disables_docs_by_default():
    settings = Settings(
        app_env="production",
        jwt_secret="x" * 32,
        cors_allowed_origins=["https://app.example.com"],
    )
    assert settings.docs_enabled is False
