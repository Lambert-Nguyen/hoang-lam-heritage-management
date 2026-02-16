"""
Audit logging utilities for sensitive data access.

Provides:
- log_sensitive_access(): Log access to sensitive guest data
- AuditLogMixin: ViewSet mixin for automatic audit logging
"""

import logging

from hotel_api.models import SensitiveDataAccessLog

logger = logging.getLogger("hotel_api.security")

SENSITIVE_GUEST_FIELDS = ["id_number", "visa_number", "id_image"]


def get_client_ip(request):
    """Extract client IP from request, handling proxies."""
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


def log_sensitive_access(request, action, resource_type="guest", resource_id=None,
                         fields=None, details=None):
    """
    Create an audit log entry for sensitive data access.

    Also logs to the `hotel_api.security` Python logger for file/SIEM.
    """
    if fields is None:
        fields = SENSITIVE_GUEST_FIELDS

    user = request.user if request.user.is_authenticated else None
    ip = get_client_ip(request)
    user_agent = request.META.get("HTTP_USER_AGENT", "")[:500]

    # Database log
    SensitiveDataAccessLog.objects.create(
        user=user,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        fields_accessed=fields,
        ip_address=ip,
        user_agent=user_agent,
        details=details or {},
    )

    # File log (for SIEM integration)
    username = user.username if user else "anonymous"
    logger.info(
        "SENSITIVE_DATA_ACCESS: user=%s action=%s resource=%s:%s ip=%s fields=%s",
        username, action, resource_type, resource_id, ip, fields,
    )
