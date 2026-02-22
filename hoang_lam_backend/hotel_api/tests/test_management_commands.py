"""
Unit tests for Django management commands.

Covers:
  - apply_retention_policy  (wraps hotel_api.retention.apply_retention_policy)
  - encrypt_guest_data       (encrypts Guest id_number / visa_number fields)
"""

from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from hotel_api.models import Guest


# ─────────────────────────────────────────────
# apply_retention_policy command
# ─────────────────────────────────────────────


class TestApplyRetentionPolicyCommand(TestCase):
    """Tests for the apply_retention_policy management command wrapper."""

    def _call(self, *args, **kwargs):
        out = StringIO()
        err = StringIO()
        call_command("apply_retention_policy", *args, stdout=out, stderr=err, **kwargs)
        return out.getvalue(), err.getvalue()

    def test_dry_run_flag_adds_prefix(self):
        """--dry-run prints [DRY RUN] prefix without deleting records."""
        out, _ = self._call("--dry-run")
        self.assertIn("[DRY RUN]", out)
        self.assertIn("Done", out)

    def test_normal_run_prints_done(self):
        """Normal run (no flags) completes and prints 'Done.'"""
        out, err = self._call()
        self.assertIn("Done", out)
        self.assertEqual(err, "")

    def test_unknown_model_writes_to_stderr(self):
        """Passing an unknown --model value prints an error to stderr."""
        _, err = self._call("--model", "nonexistent_model")
        self.assertIn("Unknown model", err)

    def test_known_model_filter_runs_cleanly(self):
        """Passing a valid --model runs without error."""
        out, err = self._call("--model", "notification")
        self.assertIn("Done", out)
        self.assertEqual(err, "")

    def test_dry_run_with_model_filter(self):
        """--dry-run combined with --model works correctly."""
        out, _ = self._call("--dry-run", "--model", "notification")
        self.assertIn("[DRY RUN]", out)


# ─────────────────────────────────────────────
# encrypt_guest_data command
# ─────────────────────────────────────────────


class TestEncryptGuestDataCommand(TestCase):
    """Tests for the encrypt_guest_data management command."""

    def _call(self, *args):
        out = StringIO()
        err = StringIO()
        call_command("encrypt_guest_data", *args, stdout=out, stderr=err)
        return out.getvalue(), err.getvalue()

    def test_dry_run_prints_would_encrypt(self):
        """--dry-run reports what would be encrypted without changing data."""
        guest = Guest.objects.create(
            full_name="Dry Run Guest",
            phone="0900000001",
            nationality="Vietnam",
            id_number="001234567890",
        )

        out, _ = self._call("--dry-run")

        self.assertIn("[DRY RUN]", out)
        self.assertIn("Would encrypt", out)
        # Data must be unchanged
        guest.refresh_from_db()
        self.assertEqual(guest.id_number, "001234567890")

    def test_dry_run_no_guests_with_id_number(self):
        """--dry-run with no id_number fields reports 'Done' with 0 changes."""
        Guest.objects.create(
            full_name="No ID Guest",
            phone="0900000002",
            nationality="Vietnam",
        )

        out, _ = self._call("--dry-run")

        self.assertIn("[DRY RUN]", out)
        self.assertIn("Done", out)

    def test_encrypts_unencrypted_id_number(self):
        """Command sets id_number_hash for a guest with plaintext id_number."""
        guest = Guest.objects.create(
            full_name="Encrypt Guest",
            phone="0900000003",
            nationality="Vietnam",
            id_number="123456789012",
        )

        out, _ = self._call()

        self.assertIn("Done", out)
        # hash should now be populated (hash_value doesn't need encryption key)
        guest.refresh_from_db()
        self.assertNotEqual(guest.id_number_hash or "", "")

    def test_no_guests_prints_done(self):
        """With no guests in DB the command finishes without error."""
        out, err = self._call()
        self.assertIn("Done", out)
        self.assertEqual(err, "")

    def test_guest_without_id_number_is_skipped(self):
        """Guests with no id_number are not counted as encrypted or skipped."""
        Guest.objects.create(
            full_name="No ID Guest",
            phone="0900000004",
            nationality="Vietnam",
        )

        out, _ = self._call()

        self.assertIn("Done", out)
        # encrypted count and skipped count should both be 0
        self.assertIn("Encrypted: 0", out)
