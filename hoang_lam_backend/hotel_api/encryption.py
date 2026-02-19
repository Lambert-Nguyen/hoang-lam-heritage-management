"""
Field-level encryption utilities for sensitive guest data.

Uses Fernet symmetric encryption (AES-128-CBC + HMAC-SHA256)
from the `cryptography` library.

Encryption is controlled by the FIELD_ENCRYPTION_KEY setting:
- If set: fields are encrypted/decrypted transparently
- If empty: encryption is disabled (dev/test mode)
"""

import hashlib
import logging

from cryptography.fernet import Fernet, InvalidToken
from django.conf import settings

logger = logging.getLogger("hotel_api")


def _get_fernet():
    """Get Fernet instance from settings key. Returns None if no key configured."""
    key = getattr(settings, "FIELD_ENCRYPTION_KEY", "")
    if not key:
        return None
    return Fernet(key.encode() if isinstance(key, str) else key)


def encrypt(plaintext):
    """
    Encrypt a plaintext string. Returns base64-encoded ciphertext.

    If encryption is disabled (no key), returns plaintext unchanged.
    If plaintext is empty/None, returns it unchanged.
    """
    if not plaintext:
        return plaintext

    fernet = _get_fernet()
    if fernet is None:
        return plaintext

    return fernet.encrypt(plaintext.encode()).decode()


def decrypt(ciphertext):
    """
    Decrypt a ciphertext string. Returns plaintext.

    If encryption is disabled (no key), returns ciphertext unchanged.
    If ciphertext is empty/None, returns it unchanged.
    Gracefully handles already-plaintext values (migration period).
    """
    if not ciphertext:
        return ciphertext

    fernet = _get_fernet()
    if fernet is None:
        return ciphertext

    try:
        return fernet.decrypt(ciphertext.encode()).decode()
    except (InvalidToken, ValueError, UnicodeDecodeError):
        # Value is likely still plaintext (pre-encryption migration)
        return ciphertext


def hash_value(plaintext):
    """
    Compute peppered SHA-256 hash of a plaintext value for lookup/uniqueness.

    Uses HASH_PEPPER from settings to prevent precomputation attacks
    on low-entropy values (e.g., 12-digit CCCD numbers).

    Returns hex digest string (64 chars).
    Returns empty string if plaintext is empty/None.
    """
    if not plaintext:
        return ""
    pepper = getattr(settings, "HASH_PEPPER", "")
    return hashlib.sha256((pepper + plaintext.strip()).encode()).hexdigest()


def is_encrypted(value):
    """Check if a value appears to be Fernet-encrypted."""
    if not value:
        return False
    try:
        fernet = _get_fernet()
        if fernet is None:
            return False
        fernet.decrypt(value.encode())
        return True
    except (InvalidToken, ValueError, UnicodeDecodeError):
        return False
