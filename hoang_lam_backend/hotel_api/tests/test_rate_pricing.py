"""
Unit tests for RatePricingService (hotel_api/services.py).

Covers the previously-uncovered branches:
  L250  — nights <= 0  (early return)
  L268  — rate_plan provided but is_active=False  (falls back to DB lookup)
  L278  — active_plan.valid_from is in the future  (plan treated as invalid)
  L282  — active_plan.valid_to is in the past      (plan treated as invalid)
  L294  — DateRateOverride matched for specific date
"""

from datetime import timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone

from hotel_api.models import DateRateOverride, RatePlan, RoomType
from hotel_api.services import RatePricingService

# Use the same date source as the service (UTC-aware) to avoid midnight edge cases.
_today = timezone.now().date


class TestRatePricingServiceBase(TestCase):
    """Shared fixture: a RoomType with a known base_rate."""

    BASE_RATE = Decimal("500000")

    def setUp(self):
        self.room_type = RoomType.objects.create(
            name="Standard Test",
            base_rate=self.BASE_RATE,
        )

    def _calc(self, check_in, check_out, rate_plan=None):
        return RatePricingService.calculate_nightly_rates(
            room_type=self.room_type,
            check_in_date=check_in,
            check_out_date=check_out,
            rate_plan=rate_plan,
        )


# ─────────────────────────────────────────────
# nights <= 0  (L250)
# ─────────────────────────────────────────────

class TestZeroNights(TestRatePricingServiceBase):
    """calculate_nightly_rates returns zeros when the stay is 0 or negative."""

    def test_same_day_check_in_and_out(self):
        """check_in == check_out → 0 nights, all zeros."""
        today = _today()
        result = self._calc(today, today)

        self.assertEqual(result["nights"], 0)
        self.assertEqual(result["total_amount"], Decimal("0"))
        self.assertEqual(result["nightly_rate"], Decimal("0"))
        self.assertEqual(result["nightly_breakdown"], [])

    def test_check_out_before_check_in(self):
        """check_out < check_in → 0 nights, all zeros."""
        today = _today()
        result = self._calc(today + timedelta(days=3), today)

        self.assertEqual(result["nights"], 0)
        self.assertEqual(result["total_amount"], Decimal("0"))


# ─────────────────────────────────────────────
# No rate_plan provided — fallback chain
# ─────────────────────────────────────────────

class TestNoRatePlanFallback(TestRatePricingServiceBase):
    """When no rate_plan is passed, falls back through DB lookup then room_type."""

    def test_uses_room_type_rate_when_no_plan_exists(self):
        """No RatePlan in DB → each night is billed at room_type.base_rate."""
        today = _today()
        result = self._calc(today, today + timedelta(days=3))

        self.assertEqual(result["nights"], 3)
        self.assertEqual(result["total_amount"], self.BASE_RATE * 3)
        for entry in result["nightly_breakdown"]:
            self.assertEqual(entry["source"], "room_type")
            self.assertEqual(entry["rate"], self.BASE_RATE)

    def test_uses_active_db_plan_when_valid(self):
        """Active RatePlan from DB (no valid_from/valid_to) is used as base_rate."""
        plan_rate = Decimal("700000")
        RatePlan.objects.create(
            name="DB Active Plan",
            room_type=self.room_type,
            base_rate=plan_rate,
            is_active=True,
        )

        today = _today()
        result = self._calc(today, today + timedelta(days=2))

        self.assertEqual(result["total_amount"], plan_rate * 2)


# ─────────────────────────────────────────────
# rate_plan provided but is_active=False  (L268)
# ─────────────────────────────────────────────

class TestInactiveRatePlanArg(TestRatePricingServiceBase):
    """Passing an inactive rate_plan falls back to the DB lookup chain."""

    def test_inactive_plan_arg_falls_back_to_room_type(self):
        """rate_plan.is_active=False → no active plan in DB → room_type rate."""
        inactive_plan = RatePlan.objects.create(
            name="Inactive Plan",
            room_type=self.room_type,
            base_rate=Decimal("999000"),
            is_active=False,
        )

        today = _today()
        result = self._calc(today, today + timedelta(days=1), rate_plan=inactive_plan)

        # The inactive plan's rate must NOT be used
        self.assertEqual(result["nightly_rate"], self.BASE_RATE)

    def test_inactive_plan_arg_uses_other_active_db_plan(self):
        """Inactive arg plan → DB lookup finds another active plan → that rate is used."""
        RatePlan.objects.create(
            name="Inactive Plan",
            room_type=self.room_type,
            base_rate=Decimal("999000"),
            is_active=False,
        )
        active_db_plan = RatePlan.objects.create(
            name="Active DB Plan",
            room_type=self.room_type,
            base_rate=Decimal("650000"),
            is_active=True,
        )

        today = _today()
        # Pass the inactive plan; should find the active one from DB
        inactive_plan = RatePlan.objects.get(name="Inactive Plan")
        result = self._calc(today, today + timedelta(days=1), rate_plan=inactive_plan)

        self.assertEqual(result["nightly_rate"], active_db_plan.base_rate)


# ─────────────────────────────────────────────
# valid_from / valid_to validity checks  (L278-284)
# ─────────────────────────────────────────────

class TestRatePlanValidityDates(TestRatePricingServiceBase):
    """Active RatePlans outside their validity window fall back to room_type rate."""

    def test_valid_from_in_future_uses_room_type_rate(self):
        """Plan not yet valid (valid_from > today) → room_type.base_rate used."""
        today = _today()
        RatePlan.objects.create(
            name="Future Plan",
            room_type=self.room_type,
            base_rate=Decimal("900000"),
            is_active=True,
            valid_from=today + timedelta(days=10),
        )

        result = self._calc(today, today + timedelta(days=1))

        self.assertEqual(result["nightly_rate"], self.BASE_RATE)

    def test_valid_to_in_past_uses_room_type_rate(self):
        """Expired plan (valid_to < today) → room_type.base_rate used."""
        today = _today()
        RatePlan.objects.create(
            name="Expired Plan",
            room_type=self.room_type,
            base_rate=Decimal("900000"),
            is_active=True,
            valid_to=today - timedelta(days=1),
        )

        result = self._calc(today, today + timedelta(days=1))

        self.assertEqual(result["nightly_rate"], self.BASE_RATE)

    def test_plan_within_validity_window_is_used(self):
        """Plan where today falls within valid_from..valid_to is applied."""
        today = _today()
        plan_rate = Decimal("800000")
        RatePlan.objects.create(
            name="Valid Window Plan",
            room_type=self.room_type,
            base_rate=plan_rate,
            is_active=True,
            valid_from=today - timedelta(days=5),
            valid_to=today + timedelta(days=5),
        )

        result = self._calc(today, today + timedelta(days=2))

        self.assertEqual(result["nightly_rate"], plan_rate)


# ─────────────────────────────────────────────
# DateRateOverride  (L294-295)
# ─────────────────────────────────────────────

class TestDateRateOverride(TestRatePricingServiceBase):
    """DateRateOverride takes priority over RatePlan and RoomType rates."""

    def test_override_used_for_specific_date(self):
        """An override for a date sets that night's rate to the override value."""
        today = _today()
        override_rate = Decimal("1200000")
        DateRateOverride.objects.create(
            room_type=self.room_type,
            date=today,
            rate=override_rate,
        )

        result = self._calc(today, today + timedelta(days=1))

        self.assertEqual(result["nightly_rate"], override_rate)
        self.assertEqual(result["nightly_breakdown"][0]["source"], "date_override")

    def test_override_only_on_specific_night(self):
        """Override applies to its date only; other nights use base rate."""
        today = _today()
        override_rate = Decimal("1200000")
        DateRateOverride.objects.create(
            room_type=self.room_type,
            date=today,
            rate=override_rate,
        )

        result = self._calc(today, today + timedelta(days=2))
        breakdown = result["nightly_breakdown"]

        self.assertEqual(breakdown[0]["source"], "date_override")
        self.assertEqual(breakdown[0]["rate"], override_rate)
        self.assertEqual(breakdown[1]["source"], "room_type")
        self.assertEqual(breakdown[1]["rate"], self.BASE_RATE)

        expected_total = override_rate + self.BASE_RATE
        self.assertEqual(result["total_amount"], expected_total)

    def test_override_takes_priority_over_rate_plan(self):
        """Even when an active rate_plan is provided, override takes priority."""
        today = _today()
        plan = RatePlan.objects.create(
            name="Active Plan",
            room_type=self.room_type,
            base_rate=Decimal("750000"),
            is_active=True,
        )
        override_rate = Decimal("1100000")
        DateRateOverride.objects.create(
            room_type=self.room_type,
            date=today,
            rate=override_rate,
        )

        result = self._calc(today, today + timedelta(days=1), rate_plan=plan)

        self.assertEqual(result["nightly_breakdown"][0]["source"], "date_override")
        self.assertEqual(result["nightly_rate"], override_rate)

    def test_no_override_uses_provided_rate_plan(self):
        """Without an override, an active rate_plan is used as the base."""
        today = _today()
        plan_rate = Decimal("750000")
        plan = RatePlan.objects.create(
            name="Active Plan",
            room_type=self.room_type,
            base_rate=plan_rate,
            is_active=True,
        )

        result = self._calc(today, today + timedelta(days=1), rate_plan=plan)

        self.assertEqual(result["nightly_rate"], plan_rate)
        self.assertEqual(result["nightly_breakdown"][0]["source"], "rate_plan")
