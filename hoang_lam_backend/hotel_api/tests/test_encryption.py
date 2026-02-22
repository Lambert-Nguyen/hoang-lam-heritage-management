"""Tests for field-level encryption utilities and Guest model encryption."""

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings

from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.encryption import decrypt, encrypt, hash_value, is_encrypted
from hotel_api.models import Guest, HotelUser

User = get_user_model()

FERNET_TEST_KEY = "ZmDfcTF7_60GrrY167zsiPd67pEvs0aGOv2oasOM1Pg="


class TestEncryptionUtility(TestCase):
    """Unit tests for encryption.py functions (no key = disabled)."""

    def test_encrypt_returns_plaintext_when_no_key(self):
        """Encryption is disabled without FIELD_ENCRYPTION_KEY."""
        result = encrypt("001234567890")
        self.assertEqual(result, "001234567890")

    def test_decrypt_returns_plaintext_when_no_key(self):
        """Decryption is disabled without FIELD_ENCRYPTION_KEY."""
        result = decrypt("001234567890")
        self.assertEqual(result, "001234567890")

    def test_encrypt_empty_string(self):
        """Empty string is returned unchanged."""
        self.assertEqual(encrypt(""), "")
        self.assertEqual(encrypt(None), None)

    def test_decrypt_empty_string(self):
        """Empty string is returned unchanged."""
        self.assertEqual(decrypt(""), "")
        self.assertEqual(decrypt(None), None)

    def test_hash_value_consistent(self):
        """Same input always produces same hash."""
        h1 = hash_value("001234567890")
        h2 = hash_value("001234567890")
        self.assertEqual(h1, h2)
        self.assertEqual(len(h1), 64)  # SHA-256 hex

    def test_hash_value_different_inputs(self):
        """Different inputs produce different hashes."""
        h1 = hash_value("001234567890")
        h2 = hash_value("US123456789")
        self.assertNotEqual(h1, h2)

    def test_hash_value_empty(self):
        """Empty/None input returns empty string."""
        self.assertEqual(hash_value(""), "")
        self.assertEqual(hash_value(None), "")

    def test_is_encrypted_returns_false_without_key(self):
        """is_encrypted returns False when no key is configured."""
        self.assertFalse(is_encrypted("001234567890"))
        self.assertFalse(is_encrypted(""))
        self.assertFalse(is_encrypted(None))


@override_settings(FIELD_ENCRYPTION_KEY=FERNET_TEST_KEY)
class TestEncryptionWithKey(TestCase):
    """Tests for encryption when FIELD_ENCRYPTION_KEY is configured."""

    def test_encrypt_decrypt_roundtrip(self):
        """Encrypt then decrypt returns original value."""
        original = "001234567890"
        encrypted = encrypt(original)
        self.assertNotEqual(encrypted, original)
        decrypted = decrypt(encrypted)
        self.assertEqual(decrypted, original)

    def test_encrypted_value_is_different(self):
        """Encrypted value differs from plaintext."""
        original = "US123456789"
        encrypted = encrypt(original)
        self.assertNotEqual(encrypted, original)
        self.assertTrue(len(encrypted) > len(original))

    def test_is_encrypted_detects_encrypted_value(self):
        """is_encrypted correctly identifies encrypted values."""
        encrypted = encrypt("001234567890")
        self.assertTrue(is_encrypted(encrypted))
        self.assertFalse(is_encrypted("001234567890"))

    def test_decrypt_plaintext_gracefully(self):
        """Decrypting plaintext returns it unchanged (migration safety)."""
        result = decrypt("001234567890")
        self.assertEqual(result, "001234567890")


@override_settings(FIELD_ENCRYPTION_KEY=FERNET_TEST_KEY)
class TestGuestModelEncryption(TestCase):
    """Tests for Guest model save() encryption behavior."""

    def test_guest_save_encrypts_id_number(self):
        """Guest.save() encrypts id_number when key is set."""
        guest = Guest.objects.create(
            full_name="Test User", phone="0900000001", id_number="001234567890"
        )
        guest.refresh_from_db()
        # Stored value should be encrypted
        self.assertNotEqual(guest.id_number, "001234567890")
        self.assertTrue(is_encrypted(guest.id_number))
        # Hash should be computed
        self.assertEqual(guest.id_number_hash, hash_value("001234567890"))

    def test_guest_save_encrypts_visa_number(self):
        """Guest.save() encrypts visa_number when key is set."""
        guest = Guest.objects.create(
            full_name="Foreign Guest",
            phone="0900000002",
            visa_number="V123456",
        )
        guest.refresh_from_db()
        self.assertNotEqual(guest.visa_number, "V123456")
        self.assertTrue(is_encrypted(guest.visa_number))
        self.assertEqual(guest.visa_number_hash, hash_value("V123456"))

    def test_guest_save_no_double_encryption(self):
        """Saving a guest twice doesn't double-encrypt."""
        guest = Guest.objects.create(
            full_name="Test User", phone="0900000003", id_number="001234567890"
        )
        first_hash = guest.id_number_hash
        guest.full_name = "Updated Name"
        guest.save()
        guest.refresh_from_db()
        # Hash should be unchanged
        self.assertEqual(guest.id_number_hash, first_hash)
        # Should still decrypt correctly
        self.assertEqual(decrypt(guest.id_number), "001234567890")

    def test_guest_null_id_number(self):
        """Guest with null id_number has null hash."""
        guest = Guest.objects.create(
            full_name="No ID",
            phone="0900000004",
            id_number=None,
        )
        self.assertIsNone(guest.id_number_hash)


class TestGuestModelWithoutEncryption(TestCase):
    """Tests for Guest model save() without encryption key."""

    def test_guest_save_stores_plaintext(self):
        """Without key, id_number is stored as plaintext."""
        guest = Guest.objects.create(
            full_name="Test User", phone="0900000005", id_number="001234567890"
        )
        guest.refresh_from_db()
        self.assertEqual(guest.id_number, "001234567890")

    def test_guest_save_computes_hash_without_key(self):
        """Hash is computed even without encryption key."""
        guest = Guest.objects.create(
            full_name="Test User", phone="0900000006", id_number="001234567890"
        )
        self.assertEqual(guest.id_number_hash, hash_value("001234567890"))


@override_settings(FIELD_ENCRYPTION_KEY=FERNET_TEST_KEY)
class TestSerializerDecryption(TestCase):
    """Tests for serializer transparent decryption."""

    def setUp(self):
        self.user = User.objects.create_user(username="staff", password="testpass123")
        HotelUser.objects.create(user=self.user, role=HotelUser.Role.STAFF)
        self.guest = Guest.objects.create(
            full_name="Encrypted Guest",
            phone="0900000007",
            id_number="001234567890",
            visa_number="V999999",
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_serializer_decrypts_on_read(self):
        """API returns decrypted id_number."""
        response = self.client.get(f"/api/v1/guests/{self.guest.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["id_number"], "001234567890")
        self.assertEqual(response.data["visa_number"], "V999999")

    def test_list_serializer_decrypts_on_read(self):
        """API list returns decrypted id_number."""
        response = self.client.get("/api/v1/guests/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data["results"]
        self.assertTrue(len(results) >= 1)
        guest_data = next(r for r in results if r["id"] == self.guest.id)
        self.assertEqual(guest_data["id_number"], "001234567890")

    def test_uniqueness_via_hash(self):
        """Duplicate id_number rejected via hash comparison."""
        manager = User.objects.create_user(username="manager", password="testpass123")
        HotelUser.objects.create(user=manager, role=HotelUser.Role.MANAGER)
        self.client.force_authenticate(user=manager)

        response = self.client.post(
            "/api/v1/guests/",
            {
                "full_name": "Another Guest",
                "phone": "0900000008",
                "id_number": "001234567890",  # Same as existing
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("id_number", response.data)

    def test_search_by_exact_id_number(self):
        """Search by exact id_number works with encryption."""
        response = self.client.get("/api/v1/guests/?search=001234567890")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data["results"]
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["id_number"], "001234567890")
