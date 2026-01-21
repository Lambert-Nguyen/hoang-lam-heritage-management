"""
Settings module for Hoang Lam Heritage Management backend.

Environment-specific settings:
- base.py: Common settings for all environments
- development.py: Development environment
- staging.py: Staging environment
- production.py: Production environment

Usage:
    Set DJANGO_SETTINGS_MODULE environment variable:
    - export DJANGO_SETTINGS_MODULE=backend.settings.development
    - export DJANGO_SETTINGS_MODULE=backend.settings.production
"""

import os

# Default to development settings if not specified
ENVIRONMENT = os.getenv("DJANGO_ENVIRONMENT", "development")

if ENVIRONMENT == "production":
    from .production import *
elif ENVIRONMENT == "staging":
    from .staging import *
else:
    from .development import *
