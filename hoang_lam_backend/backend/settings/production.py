"""
Production settings for Hoang Lam Heritage Management backend.
"""

from .base import *

import os

# Production-specific settings
DEBUG = False

# Security settings
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
X_FRAME_OPTIONS = "DENY"

# CORS settings - must specify allowed origins
CORS_ALLOW_ALL_ORIGINS = False
# CORS_ALLOWED_ORIGINS configured in base.py from environment variable

# Allowed hosts - must be set in environment
if not ALLOWED_HOSTS or ALLOWED_HOSTS == ["*"]:
    raise ValueError("ALLOWED_HOSTS must be explicitly set in production")

# Logging — console-only (Heroku and other PaaS have ephemeral filesystems)
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "[{levelname}] {asctime} {name} {module} {funcName} {process:d} {thread:d} {message}",
            "style": "{",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
        "json": {
            "class": "pythonjsonlogger.jsonlogger.JsonFormatter",
            "format": "%(asctime)s %(name)s %(levelname)s %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
        "console_json": {
            "class": "logging.StreamHandler",
            "formatter": "json",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "WARNING",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "django.request": {
            "handlers": ["console"],
            "level": "ERROR",
            "propagate": False,
        },
        "django.security": {
            "handlers": ["console"],
            "level": "ERROR",
            "propagate": False,
        },
        "hotel_api": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "hotel_api.security": {
            "handlers": ["console_json"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

# Email backend for production
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.getenv("EMAIL_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", "587"))
EMAIL_USE_TLS = os.getenv("EMAIL_USE_TLS", "True").lower() == "true"
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER", "")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD", "")
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL", "noreply@hoanglam.com")

# Ensure SECRET_KEY is properly set
if SECRET_KEY == "django-insecure-change-me-in-production":
    raise ValueError("SECRET_KEY must be set to a secure value in production")

# Admin notifications
ADMINS = [
    ("Admin", os.getenv("ADMIN_EMAIL", "admin@hoanglam.com")),
]
MANAGERS = ADMINS

# FCM configuration for push notifications
FCM_ENABLED = os.getenv("FCM_ENABLED", "True").lower() == "true"
if FCM_ENABLED and not FCM_CREDENTIALS_FILE and not FCM_CREDENTIALS_JSON:
    import warnings

    warnings.warn(
        "FCM_ENABLED is True but no credentials configured. Push notifications will not work."
    )

# Cache configuration (optional - requires Redis)
if os.getenv("REDIS_URL"):
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.redis.RedisCache",
            "LOCATION": os.getenv("REDIS_URL"),
        }
    }
