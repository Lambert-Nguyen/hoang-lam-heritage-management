"""
Celery configuration for Hoang Lam Heritage Management backend.

Usage:
    # Start worker:
    celery -A backend worker -l info

    # Start beat (scheduler):
    celery -A backend beat -l info

    # Start both (development only):
    celery -A backend worker -B -l info
"""

import os

from celery import Celery

# Use the same environment-aware settings package used by Django itself.
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")

app = Celery("backend")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
