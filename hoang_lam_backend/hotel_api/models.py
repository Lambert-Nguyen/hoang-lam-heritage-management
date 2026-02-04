"""
Data models for Hoang Lam Heritage Management.

Models:
- Room, RoomType: Room inventory and configuration
- Booking: Guest reservations
- FinancialEntry, FinancialCategory: Income and expense tracking
- HotelUser: User profiles with roles
- HousekeepingTask: Room cleaning tasks
- MinibarItem, MinibarSale: Minibar inventory and sales
- ExchangeRate: Currency conversion
"""

from decimal import Decimal

from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models


class RoomType(models.Model):
    """Room type configuration (Single, Double, Family, etc.)"""

    name = models.CharField(max_length=50, verbose_name="Tên loại phòng")
    name_en = models.CharField(max_length=50, blank=True, verbose_name="Name (English)")
    base_rate = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá cơ bản/đêm",
    )
    hourly_rate = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá theo giờ",
    )
    first_hour_rate = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá giờ đầu tiên",
        help_text="Giá cho 2-3 giờ đầu tiên (thường cao hơn)",
    )
    allows_hourly = models.BooleanField(
        default=True,
        verbose_name="Cho phép đặt theo giờ",
    )
    min_hours = models.PositiveIntegerField(
        default=2,
        verbose_name="Số giờ tối thiểu",
    )
    max_guests = models.PositiveIntegerField(default=2, verbose_name="Số khách tối đa")
    description = models.TextField(blank=True, verbose_name="Mô tả")
    amenities = models.JSONField(default=list, blank=True, verbose_name="Tiện nghi")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Loại phòng"
        verbose_name_plural = "Loại phòng"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Room(models.Model):
    """Individual room in the hotel"""

    class Status(models.TextChoices):
        AVAILABLE = "available", "Trống"
        OCCUPIED = "occupied", "Có khách"
        CLEANING = "cleaning", "Đang dọn"
        MAINTENANCE = "maintenance", "Bảo trì"
        BLOCKED = "blocked", "Khóa"

    number = models.CharField(max_length=10, unique=True, verbose_name="Số phòng")
    name = models.CharField(max_length=50, blank=True, verbose_name="Tên phòng")
    room_type = models.ForeignKey(
        RoomType, on_delete=models.PROTECT, related_name="rooms", verbose_name="Loại phòng"
    )
    floor = models.PositiveIntegerField(default=1, verbose_name="Tầng")
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.AVAILABLE, verbose_name="Trạng thái"
    )
    amenities = models.JSONField(default=list, blank=True, verbose_name="Tiện nghi")
    notes = models.TextField(blank=True, verbose_name="Ghi chú")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Phòng"
        verbose_name_plural = "Phòng"
        ordering = ["floor", "number"]

    def __str__(self):
        return f"{self.number} - {self.room_type.name}"


class Guest(models.Model):
    """Guest information for tracking history and preferences"""

    class IDType(models.TextChoices):
        CCCD = "cccd", "CCCD (Căn cước công dân)"
        PASSPORT = "passport", "Hộ chiếu"
        CMND = "cmnd", "CMND (Chứng minh nhân dân)"
        GPLX = "gplx", "GPLX (Giấy phép lái xe)"
        OTHER = "other", "Khác"

    # Personal information
    full_name = models.CharField(max_length=100, verbose_name="Họ và tên")
    phone = models.CharField(max_length=20, unique=True, db_index=True, verbose_name="Số điện thoại")
    email = models.EmailField(blank=True, verbose_name="Email")

    # ID information
    id_type = models.CharField(
        max_length=20, choices=IDType.choices, default=IDType.CCCD, verbose_name="Loại giấy tờ"
    )
    id_number = models.CharField(
        max_length=20, blank=True, null=True, unique=True, db_index=True, verbose_name="Số CCCD/Passport"
    )
    id_issue_date = models.DateField(null=True, blank=True, verbose_name="Ngày cấp")
    id_issue_place = models.CharField(max_length=100, blank=True, verbose_name="Nơi cấp")
    id_image = models.ImageField(
        upload_to="guest_ids/", null=True, blank=True, verbose_name="Ảnh CCCD/Passport"
    )

    # Demographics
    nationality = models.CharField(max_length=50, default="Vietnam", verbose_name="Quốc tịch")
    date_of_birth = models.DateField(null=True, blank=True, verbose_name="Ngày sinh")
    gender = models.CharField(
        max_length=10,
        choices=[("male", "Nam"), ("female", "Nữ"), ("other", "Khác")],
        blank=True,
        verbose_name="Giới tính",
    )

    # Address
    address = models.TextField(blank=True, verbose_name="Địa chỉ")
    city = models.CharField(max_length=100, blank=True, verbose_name="Thành phố")
    country = models.CharField(max_length=100, blank=True, verbose_name="Quốc gia")

    # Guest status and preferences
    is_vip = models.BooleanField(default=False, verbose_name="Khách VIP")
    total_stays = models.PositiveIntegerField(default=0, verbose_name="Số lần ở")
    preferences = models.JSONField(default=dict, blank=True, verbose_name="Sở thích")
    notes = models.TextField(blank=True, verbose_name="Ghi chú")

    # Audit
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Khách hàng"
        verbose_name_plural = "Khách hàng"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["phone", "id_number"]),
            models.Index(fields=["full_name"]),
        ]

    def __str__(self):
        return f"{self.full_name} - {self.phone}"

    @property
    def is_returning_guest(self):
        """Check if guest has stayed before"""
        return self.total_stays > 0


class Booking(models.Model):
    """Guest booking/reservation"""

    class Status(models.TextChoices):
        PENDING = "pending", "Chờ xác nhận"
        CONFIRMED = "confirmed", "Đã xác nhận"
        CHECKED_IN = "checked_in", "Đang ở"
        CHECKED_OUT = "checked_out", "Đã trả phòng"
        CANCELLED = "cancelled", "Đã hủy"
        NO_SHOW = "no_show", "Không đến"

    class Source(models.TextChoices):
        WALK_IN = "walk_in", "Khách vãng lai"
        PHONE = "phone", "Điện thoại"
        WEBSITE = "website", "Website"
        BOOKING_COM = "booking_com", "Booking.com"
        AGODA = "agoda", "Agoda"
        AIRBNB = "airbnb", "Airbnb"
        TRAVELOKA = "traveloka", "Traveloka"
        OTHER_OTA = "other_ota", "OTA khác"
        OTHER = "other", "Khác"

    class PaymentMethod(models.TextChoices):
        CASH = "cash", "Tiền mặt"
        BANK_TRANSFER = "bank_transfer", "Chuyển khoản"
        MOMO = "momo", "MoMo"
        VNPAY = "vnpay", "VNPay"
        CARD = "card", "Thẻ"
        OTA_COLLECT = "ota_collect", "OTA thu hộ"
        OTHER = "other", "Khác"

    # Room and dates
    room = models.ForeignKey(
        Room, on_delete=models.PROTECT, related_name="bookings", verbose_name="Phòng"
    )
    check_in_date = models.DateField(verbose_name="Ngày nhận phòng")
    check_out_date = models.DateField(verbose_name="Ngày trả phòng")
    actual_check_in = models.DateTimeField(null=True, blank=True, verbose_name="Giờ nhận thực tế")
    actual_check_out = models.DateTimeField(null=True, blank=True, verbose_name="Giờ trả thực tế")

    # Guest reference (foreign key to Guest model)
    guest = models.ForeignKey(
        Guest, on_delete=models.PROTECT, related_name="bookings", verbose_name="Khách hàng"
    )

    # Additional guest details for this booking
    guest_count = models.PositiveIntegerField(default=1, verbose_name="Số khách")

    # DEPRECATED FIELDS - kept for backward compatibility during migration
    # TODO: Remove these fields after migrating all existing bookings to use Guest FK
    # These will be removed in a future migration (target: Phase 2.0)
    guest_name = models.CharField(max_length=100, blank=True, verbose_name="Tên khách (deprecated)")
    guest_phone = models.CharField(
        max_length=20, blank=True, verbose_name="Số điện thoại (deprecated)"
    )
    guest_email = models.EmailField(blank=True, verbose_name="Email (deprecated)")
    guest_id_number = models.CharField(
        max_length=20, blank=True, verbose_name="Số CCCD/Passport (deprecated)"
    )
    guest_nationality = models.CharField(
        max_length=50, blank=True, default="Vietnam", verbose_name="Quốc tịch (deprecated)"
    )

    # Status and source
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.CONFIRMED, verbose_name="Trạng thái"
    )
    source = models.CharField(
        max_length=20, choices=Source.choices, default=Source.WALK_IN, verbose_name="Nguồn đặt"
    )
    ota_reference = models.CharField(max_length=50, blank=True, verbose_name="Mã OTA")

    # Booking type (hourly or overnight)
    class BookingType(models.TextChoices):
        OVERNIGHT = "overnight", "Qua đêm"
        HOURLY = "hourly", "Theo giờ"

    booking_type = models.CharField(
        max_length=20,
        choices=BookingType.choices,
        default=BookingType.OVERNIGHT,
        verbose_name="Loại đặt phòng",
    )

    # Hourly booking fields
    hours_booked = models.PositiveIntegerField(
        null=True,
        blank=True,
        verbose_name="Số giờ đặt",
        help_text="Chỉ áp dụng cho đặt phòng theo giờ",
    )
    hourly_rate = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá/giờ",
    )
    expected_check_out_time = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="Giờ trả dự kiến",
        help_text="Thời điểm trả phòng dự kiến cho đặt theo giờ",
    )

    # Early check-in / Late check-out fees
    early_check_in_fee = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        default=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Phí nhận sớm",
    )
    late_check_out_fee = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        default=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Phí trả muộn",
    )
    early_check_in_hours = models.DecimalField(
        max_digits=4,
        decimal_places=1,
        default=0,
        verbose_name="Số giờ nhận sớm",
    )
    late_check_out_hours = models.DecimalField(
        max_digits=4,
        decimal_places=1,
        default=0,
        verbose_name="Số giờ trả muộn",
    )

    # Pricing
    nightly_rate = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá/đêm",
    )
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Tổng tiền",
    )
    currency = models.CharField(max_length=3, default="VND", verbose_name="Tiền tệ")

    # Payment
    deposit_amount = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        default=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Tiền cọc",
    )
    deposit_paid = models.BooleanField(default=False, verbose_name="Đã đặt cọc")
    additional_charges = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        default=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Chi phí phát sinh",
    )
    payment_method = models.CharField(
        max_length=20,
        choices=PaymentMethod.choices,
        default=PaymentMethod.CASH,
        verbose_name="Hình thức thanh toán",
    )
    is_paid = models.BooleanField(default=False, verbose_name="Đã thanh toán đủ")

    # Notes and metadata
    notes = models.TextField(blank=True, verbose_name="Ghi chú")
    special_requests = models.TextField(blank=True, verbose_name="Yêu cầu đặc biệt")

    # Audit
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_bookings",
        verbose_name="Người tạo",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Đặt phòng"
        verbose_name_plural = "Đặt phòng"
        ordering = ["-check_in_date", "-created_at"]
        indexes = [
            models.Index(fields=["check_in_date", "check_out_date"]),
            models.Index(fields=["status", "room"]),
            models.Index(fields=["guest", "check_in_date"]),
            models.Index(fields=["-created_at"]),
        ]

    def __str__(self):
        return f"{self.room.number} - {self.guest.full_name} ({self.check_in_date})"

    @property
    def nights(self):
        """Calculate number of nights"""
        return (self.check_out_date - self.check_in_date).days

    @property
    def balance_due(self):
        """Calculate remaining balance including additional charges and fees"""
        total_fees = self.early_check_in_fee + self.late_check_out_fee
        return self.total_amount + self.additional_charges + total_fees - self.deposit_amount

    @property
    def is_hourly(self):
        """Check if this is an hourly booking"""
        return self.booking_type == self.BookingType.HOURLY


class FinancialCategory(models.Model):
    """Categories for income and expenses"""

    class CategoryType(models.TextChoices):
        INCOME = "income", "Thu"
        EXPENSE = "expense", "Chi"

    name = models.CharField(max_length=50, verbose_name="Tên danh mục")
    name_en = models.CharField(max_length=50, blank=True, verbose_name="Name (English)")
    category_type = models.CharField(
        max_length=10, choices=CategoryType.choices, verbose_name="Loại"
    )
    icon = models.CharField(max_length=50, default="category", verbose_name="Icon")
    color = models.CharField(max_length=7, default="#808080", verbose_name="Màu")
    is_default = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        verbose_name = "Danh mục tài chính"
        verbose_name_plural = "Danh mục tài chính"
        ordering = ["category_type", "sort_order", "name"]

    def __str__(self):
        return f"{self.name} ({self.get_category_type_display()})"


class FinancialEntry(models.Model):
    """Income and expense records"""

    class EntryType(models.TextChoices):
        INCOME = "income", "Thu"
        EXPENSE = "expense", "Chi"

    entry_type = models.CharField(max_length=10, choices=EntryType.choices, verbose_name="Loại")
    category = models.ForeignKey(
        FinancialCategory, on_delete=models.PROTECT, related_name="entries", verbose_name="Danh mục"
    )

    # Amount and currency
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Số tiền",
    )
    currency = models.CharField(max_length=3, default="VND", verbose_name="Tiền tệ")
    exchange_rate = models.DecimalField(
        max_digits=15, decimal_places=6, default=1, verbose_name="Tỷ giá"
    )  # To VND

    # Details
    date = models.DateField(verbose_name="Ngày")
    description = models.TextField(verbose_name="Mô tả")

    # Link to booking (for room income)
    booking = models.ForeignKey(
        Booking,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="financial_entries",
        verbose_name="Đặt phòng liên quan",
    )

    # Payment
    payment_method = models.CharField(
        max_length=20,
        choices=Booking.PaymentMethod.choices,
        default=Booking.PaymentMethod.CASH,
        verbose_name="Hình thức thanh toán",
    )
    receipt_number = models.CharField(max_length=50, blank=True, verbose_name="Số hóa đơn")
    attachment = models.ImageField(
        upload_to="receipts/", null=True, blank=True, verbose_name="Ảnh hóa đơn"
    )

    # Audit
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_entries",
        verbose_name="Người tạo",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Giao dịch tài chính"
        verbose_name_plural = "Giao dịch tài chính"
        ordering = ["-date", "-created_at"]

    def __str__(self):
        sign = "+" if self.entry_type == self.EntryType.INCOME else "-"
        return f"{sign}{self.amount:,.0f} {self.currency} - {self.description[:30]}"

    @property
    def amount_in_vnd(self):
        """Convert amount to VND"""
        return self.amount * self.exchange_rate


class Payment(models.Model):
    """Individual payment transactions linked to bookings or standalone"""

    class PaymentType(models.TextChoices):
        DEPOSIT = "deposit", "Đặt cọc"
        ROOM_CHARGE = "room_charge", "Tiền phòng"
        EXTRA_CHARGE = "extra_charge", "Phụ thu"
        REFUND = "refund", "Hoàn tiền"
        ADJUSTMENT = "adjustment", "Điều chỉnh"

    class Status(models.TextChoices):
        PENDING = "pending", "Chờ xử lý"
        COMPLETED = "completed", "Hoàn thành"
        FAILED = "failed", "Thất bại"
        REFUNDED = "refunded", "Đã hoàn"
        CANCELLED = "cancelled", "Đã hủy"

    # Link to booking (optional - can be standalone payment)
    booking = models.ForeignKey(
        Booking,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="payments",
        verbose_name="Đặt phòng",
    )

    # Payment details
    payment_type = models.CharField(
        max_length=20, choices=PaymentType.choices, default=PaymentType.ROOM_CHARGE, verbose_name="Loại"
    )
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Số tiền",
    )
    currency = models.CharField(max_length=3, default="VND", verbose_name="Tiền tệ")
    payment_method = models.CharField(
        max_length=20,
        choices=Booking.PaymentMethod.choices,
        default=Booking.PaymentMethod.CASH,
        verbose_name="Hình thức thanh toán",
    )

    # Status and tracking
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.COMPLETED, verbose_name="Trạng thái"
    )
    transaction_id = models.CharField(max_length=100, blank=True, verbose_name="Mã giao dịch")
    reference_number = models.CharField(max_length=100, blank=True, verbose_name="Số tham chiếu")

    # Receipt
    receipt_number = models.CharField(max_length=50, blank=True, verbose_name="Số hóa đơn")
    receipt_generated = models.BooleanField(default=False, verbose_name="Đã tạo hóa đơn")

    # Notes
    description = models.TextField(blank=True, verbose_name="Mô tả")
    notes = models.TextField(blank=True, verbose_name="Ghi chú")

    # Dates
    payment_date = models.DateTimeField(auto_now_add=True, verbose_name="Ngày thanh toán")

    # Audit
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_payments",
        verbose_name="Người tạo",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Thanh toán"
        verbose_name_plural = "Thanh toán"
        ordering = ["-payment_date", "-created_at"]
        indexes = [
            models.Index(fields=["booking", "-payment_date"]),
            models.Index(fields=["status", "-payment_date"]),
            models.Index(fields=["payment_type", "-payment_date"]),
        ]

    def __str__(self):
        if self.booking:
            return f"{self.get_payment_type_display()} - {self.booking.room.number} - {self.amount:,.0f}đ"
        return f"{self.get_payment_type_display()} - {self.amount:,.0f}đ"

    def save(self, *args, **kwargs):
        # Generate receipt number if not set
        if not self.receipt_number and self.status == self.Status.COMPLETED:
            from django.utils import timezone

            date_str = timezone.now().strftime("%Y%m%d")
            count = Payment.objects.filter(
                created_at__date=timezone.now().date()
            ).count() + 1
            self.receipt_number = f"PMT-{date_str}-{count:04d}"
        super().save(*args, **kwargs)


class FolioItem(models.Model):
    """Charges added to a booking folio (minibar, services, etc.)"""

    class ItemType(models.TextChoices):
        ROOM = "room", "Tiền phòng"
        MINIBAR = "minibar", "Minibar"
        LAUNDRY = "laundry", "Giặt ủi"
        FOOD = "food", "Thức ăn/Đồ uống"
        SERVICE = "service", "Dịch vụ khác"
        EXTRA_BED = "extra_bed", "Giường phụ"
        EARLY_CHECKIN = "early_checkin", "Check-in sớm"
        LATE_CHECKOUT = "late_checkout", "Check-out muộn"
        DAMAGE = "damage", "Hư hỏng"
        OTHER = "other", "Khác"

    booking = models.ForeignKey(
        Booking, on_delete=models.CASCADE, related_name="folio_items", verbose_name="Đặt phòng"
    )
    item_type = models.CharField(
        max_length=20, choices=ItemType.choices, default=ItemType.SERVICE, verbose_name="Loại"
    )
    description = models.CharField(max_length=200, verbose_name="Mô tả")
    quantity = models.PositiveIntegerField(default=1, verbose_name="Số lượng")
    unit_price = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Đơn giá",
    )
    total_price = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Thành tiền",
    )
    date = models.DateField(verbose_name="Ngày")

    # Link to minibar sale if applicable
    minibar_sale = models.ForeignKey(
        "MinibarSale",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="folio_item",
        verbose_name="Bán minibar",
    )

    # Status
    is_paid = models.BooleanField(default=False, verbose_name="Đã thanh toán")
    is_voided = models.BooleanField(default=False, verbose_name="Đã hủy")
    void_reason = models.TextField(blank=True, verbose_name="Lý do hủy")

    # Audit
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_folio_items",
        verbose_name="Người tạo",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Chi phí phát sinh"
        verbose_name_plural = "Chi phí phát sinh"
        ordering = ["booking", "date", "created_at"]

    def __str__(self):
        return f"{self.booking.room.number} - {self.description} ({self.total_price:,.0f}đ)"

    def save(self, *args, **kwargs):
        self.total_price = self.unit_price * self.quantity
        super().save(*args, **kwargs)

        # Update booking additional_charges
        if not self.is_voided:
            from django.db.models import Sum

            total = self.booking.folio_items.filter(
                is_voided=False, is_paid=False
            ).exclude(item_type=self.ItemType.ROOM).aggregate(
                total=Sum("total_price")
            )["total"] or 0
            Booking.objects.filter(pk=self.booking_id).update(additional_charges=total)


class HotelUser(models.Model):
    """Extended user profile for hotel staff"""

    class Role(models.TextChoices):
        OWNER = "owner", "Chủ khách sạn"
        MANAGER = "manager", "Quản lý"
        STAFF = "staff", "Nhân viên"
        HOUSEKEEPING = "housekeeping", "Buồng phòng"

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="hotel_profile")
    role = models.CharField(
        max_length=20, choices=Role.choices, default=Role.STAFF, verbose_name="Vai trò"
    )
    phone = models.CharField(max_length=20, blank=True, verbose_name="Số điện thoại")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Người dùng"
        verbose_name_plural = "Người dùng"

    def __str__(self):
        return f"{self.user.get_full_name() or self.user.username} ({self.get_role_display()})"


class HousekeepingTask(models.Model):
    """Room cleaning and maintenance tasks"""

    class TaskType(models.TextChoices):
        CHECKOUT_CLEAN = "checkout_clean", "Dọn phòng trả"
        STAY_CLEAN = "stay_clean", "Dọn phòng đang ở"
        DEEP_CLEAN = "deep_clean", "Tổng vệ sinh"
        MAINTENANCE = "maintenance", "Bảo trì"
        INSPECTION = "inspection", "Kiểm tra"

    class Status(models.TextChoices):
        PENDING = "pending", "Chờ xử lý"
        IN_PROGRESS = "in_progress", "Đang thực hiện"
        COMPLETED = "completed", "Hoàn thành"
        VERIFIED = "verified", "Đã kiểm tra"

    room = models.ForeignKey(
        Room, on_delete=models.CASCADE, related_name="housekeeping_tasks", verbose_name="Phòng"
    )
    task_type = models.CharField(
        max_length=20, choices=TaskType.choices, verbose_name="Loại công việc"
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING, verbose_name="Trạng thái"
    )

    scheduled_date = models.DateField(verbose_name="Ngày dự kiến")
    completed_at = models.DateTimeField(null=True, blank=True, verbose_name="Hoàn thành lúc")

    assigned_to = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_housekeeping",
        verbose_name="Phân công cho",
    )
    notes = models.TextField(blank=True, verbose_name="Ghi chú")

    # Link to booking that triggered this task
    booking = models.ForeignKey(
        Booking,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="housekeeping_tasks",
        verbose_name="Đặt phòng liên quan",
    )

    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_housekeeping",
        verbose_name="Người tạo",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Công việc dọn phòng"
        verbose_name_plural = "Công việc dọn phòng"
        ordering = ["-scheduled_date", "room__number"]

    def __str__(self):
        return f"{self.room.number} - {self.get_task_type_display()}"


class MaintenanceRequest(models.Model):
    """Maintenance requests for room and facility issues"""

    class Priority(models.TextChoices):
        LOW = "low", "Thấp"
        MEDIUM = "medium", "Trung bình"
        HIGH = "high", "Cao"
        URGENT = "urgent", "Khẩn cấp"

    class Status(models.TextChoices):
        PENDING = "pending", "Chờ xử lý"
        ASSIGNED = "assigned", "Đã phân công"
        IN_PROGRESS = "in_progress", "Đang thực hiện"
        ON_HOLD = "on_hold", "Tạm dừng"
        COMPLETED = "completed", "Hoàn thành"
        CANCELLED = "cancelled", "Đã hủy"

    class Category(models.TextChoices):
        ELECTRICAL = "electrical", "Điện"
        PLUMBING = "plumbing", "Nước"
        AC_HEATING = "ac_heating", "Điều hòa/Sưởi"
        FURNITURE = "furniture", "Nội thất"
        APPLIANCE = "appliance", "Thiết bị"
        STRUCTURAL = "structural", "Kết cấu"
        SAFETY = "safety", "An toàn"
        OTHER = "other", "Khác"

    # Location
    room = models.ForeignKey(
        Room,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="maintenance_requests",
        verbose_name="Phòng",
        help_text="Để trống nếu là khu vực công cộng",
    )
    location_description = models.CharField(
        max_length=200,
        blank=True,
        verbose_name="Vị trí cụ thể",
        help_text="Mô tả vị trí nếu không phải phòng (ví dụ: Sảnh, Hành lang tầng 2)",
    )

    # Request details
    title = models.CharField(max_length=200, verbose_name="Tiêu đề")
    description = models.TextField(verbose_name="Mô tả chi tiết")
    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        default=Category.OTHER,
        verbose_name="Danh mục",
    )
    priority = models.CharField(
        max_length=10,
        choices=Priority.choices,
        default=Priority.MEDIUM,
        verbose_name="Mức ưu tiên",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name="Trạng thái",
    )

    # Assignment and resolution
    assigned_to = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_maintenance",
        verbose_name="Phân công cho",
    )
    assigned_at = models.DateTimeField(null=True, blank=True, verbose_name="Phân công lúc")

    # Cost tracking
    estimated_cost = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Chi phí dự kiến",
    )
    actual_cost = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Chi phí thực tế",
    )

    # Resolution details
    resolution_notes = models.TextField(blank=True, verbose_name="Ghi chú hoàn thành")
    completed_at = models.DateTimeField(null=True, blank=True, verbose_name="Hoàn thành lúc")
    completed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="completed_maintenance",
        verbose_name="Người hoàn thành",
    )

    # Audit fields
    reported_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="reported_maintenance",
        verbose_name="Người báo cáo",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Yêu cầu bảo trì"
        verbose_name_plural = "Yêu cầu bảo trì"
        ordering = ["-created_at"]

    def __str__(self):
        location = self.room.number if self.room else self.location_description
        return f"{location} - {self.title}"

    def assign(self, user, assigned_by=None):
        """Assign the request to a user"""
        from django.utils import timezone

        self.assigned_to = user
        self.assigned_at = timezone.now()
        if self.status == self.Status.PENDING:
            self.status = self.Status.ASSIGNED
        self.save()

    def complete(self, user, notes=""):
        """Mark the request as completed"""
        from django.utils import timezone

        self.status = self.Status.COMPLETED
        self.completed_by = user
        self.completed_at = timezone.now()
        if notes:
            self.resolution_notes = notes
        self.save()


class MinibarItem(models.Model):
    """Minibar inventory items"""

    name = models.CharField(max_length=100, verbose_name="Tên sản phẩm")
    price = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá bán",
    )
    cost = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        default=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá vốn",
    )
    category = models.CharField(max_length=50, blank=True, verbose_name="Danh mục")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Sản phẩm minibar"
        verbose_name_plural = "Sản phẩm minibar"
        ordering = ["category", "name"]

    def __str__(self):
        return f"{self.name} - {self.price:,.0f}đ"


class MinibarSale(models.Model):
    """Minibar sales/charges to room"""

    booking = models.ForeignKey(
        Booking, on_delete=models.CASCADE, related_name="minibar_sales", verbose_name="Đặt phòng"
    )
    item = models.ForeignKey(
        MinibarItem, on_delete=models.PROTECT, related_name="sales", verbose_name="Sản phẩm"
    )
    quantity = models.PositiveIntegerField(default=1, verbose_name="Số lượng")
    unit_price = models.DecimalField(max_digits=10, decimal_places=0, verbose_name="Đơn giá")
    total = models.DecimalField(max_digits=10, decimal_places=0, verbose_name="Thành tiền")
    date = models.DateField(verbose_name="Ngày")
    is_charged = models.BooleanField(default=False, verbose_name="Đã tính tiền")

    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, verbose_name="Người tạo"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Bán minibar"
        verbose_name_plural = "Bán minibar"
        ordering = ["-date", "-created_at"]

    def __str__(self):
        return f"{self.booking.room.number} - {self.item.name} x{self.quantity}"

    def save(self, *args, **kwargs):
        self.total = self.unit_price * self.quantity
        super().save(*args, **kwargs)


class ExchangeRate(models.Model):
    """Currency exchange rates"""

    from_currency = models.CharField(max_length=3, verbose_name="Từ")
    to_currency = models.CharField(max_length=3, default="VND", verbose_name="Sang")
    rate = models.DecimalField(max_digits=15, decimal_places=6, verbose_name="Tỷ giá")
    date = models.DateField(verbose_name="Ngày")
    source = models.CharField(max_length=20, default="manual", verbose_name="Nguồn")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Tỷ giá"
        verbose_name_plural = "Tỷ giá"
        unique_together = ["from_currency", "to_currency", "date"]
        ordering = ["-date", "from_currency"]

    def __str__(self):
        return f"1 {self.from_currency} = {self.rate:,.2f} {self.to_currency}"


class NightAudit(models.Model):
    """End-of-day audit record for financial reconciliation"""

    class Status(models.TextChoices):
        DRAFT = "draft", "Nháp"
        COMPLETED = "completed", "Hoàn thành"
        CLOSED = "closed", "Đã đóng"

    # Core identification
    audit_date = models.DateField(unique=True, verbose_name="Ngày kiểm toán")
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.DRAFT, verbose_name="Trạng thái"
    )

    # Room statistics
    total_rooms = models.PositiveIntegerField(default=0, verbose_name="Tổng phòng")
    rooms_occupied = models.PositiveIntegerField(default=0, verbose_name="Phòng có khách")
    rooms_available = models.PositiveIntegerField(default=0, verbose_name="Phòng trống")
    rooms_cleaning = models.PositiveIntegerField(default=0, verbose_name="Phòng đang dọn")
    rooms_maintenance = models.PositiveIntegerField(default=0, verbose_name="Phòng bảo trì")
    occupancy_rate = models.DecimalField(
        max_digits=5, decimal_places=2, default=0, verbose_name="Tỷ lệ lấp đầy (%)"
    )

    # Booking statistics
    check_ins_today = models.PositiveIntegerField(default=0, verbose_name="Check-in hôm nay")
    check_outs_today = models.PositiveIntegerField(default=0, verbose_name="Check-out hôm nay")
    no_shows = models.PositiveIntegerField(default=0, verbose_name="Không đến")
    cancellations = models.PositiveIntegerField(default=0, verbose_name="Hủy đặt phòng")
    new_bookings = models.PositiveIntegerField(default=0, verbose_name="Đặt phòng mới")

    # Financial summary
    total_income = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Tổng thu"
    )
    room_revenue = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Doanh thu phòng"
    )
    other_revenue = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Doanh thu khác"
    )
    total_expense = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Tổng chi"
    )
    net_revenue = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Lợi nhuận ròng"
    )

    # Payment breakdown
    cash_collected = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Tiền mặt thu"
    )
    bank_transfer_collected = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Chuyển khoản thu"
    )
    momo_collected = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="MoMo thu"
    )
    other_payments = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Thanh toán khác"
    )

    # Outstanding amounts
    pending_payments = models.DecimalField(
        max_digits=15, decimal_places=0, default=0, verbose_name="Thanh toán chờ"
    )
    unpaid_bookings_count = models.PositiveIntegerField(
        default=0, verbose_name="Số đặt phòng chưa thanh toán"
    )

    # Notes and metadata
    notes = models.TextField(blank=True, verbose_name="Ghi chú")

    # Audit trail
    performed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="night_audits",
        verbose_name="Người thực hiện",
    )
    performed_at = models.DateTimeField(null=True, blank=True, verbose_name="Thực hiện lúc")
    closed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="closed_audits",
        verbose_name="Người đóng",
    )
    closed_at = models.DateTimeField(null=True, blank=True, verbose_name="Đóng lúc")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Kiểm toán cuối ngày"
        verbose_name_plural = "Kiểm toán cuối ngày"
        ordering = ["-audit_date"]
        indexes = [
            models.Index(fields=["-audit_date"]),
            models.Index(fields=["status", "-audit_date"]),
        ]

    def __str__(self):
        return f"Night Audit - {self.audit_date} ({self.get_status_display()})"

    def calculate_statistics(self):
        """Calculate all statistics for this audit date"""
        from django.db.models import Count, Sum, Q
        from django.utils import timezone

        audit_date = self.audit_date

        # Room statistics
        room_stats = Room.objects.filter(is_active=True).aggregate(
            total=Count("id"),
            occupied=Count("id", filter=Q(status=Room.Status.OCCUPIED)),
            available=Count("id", filter=Q(status=Room.Status.AVAILABLE)),
            cleaning=Count("id", filter=Q(status=Room.Status.CLEANING)),
            maintenance=Count("id", filter=Q(status=Room.Status.MAINTENANCE)),
        )
        self.total_rooms = room_stats["total"] or 0
        self.rooms_occupied = room_stats["occupied"] or 0
        self.rooms_available = room_stats["available"] or 0
        self.rooms_cleaning = room_stats["cleaning"] or 0
        self.rooms_maintenance = room_stats["maintenance"] or 0

        if self.total_rooms > 0:
            self.occupancy_rate = (self.rooms_occupied / self.total_rooms) * 100
        else:
            self.occupancy_rate = 0

        # Booking statistics
        booking_stats = Booking.objects.filter(
            Q(check_in_date=audit_date)
            | Q(check_out_date=audit_date)
            | Q(created_at__date=audit_date)
        ).aggregate(
            check_ins=Count("id", filter=Q(check_in_date=audit_date, status=Booking.Status.CHECKED_IN)),
            check_outs=Count("id", filter=Q(check_out_date=audit_date, status=Booking.Status.CHECKED_OUT)),
            no_shows=Count("id", filter=Q(check_in_date=audit_date, status=Booking.Status.NO_SHOW)),
            cancellations=Count("id", filter=Q(status=Booking.Status.CANCELLED, updated_at__date=audit_date)),
            new_bookings=Count("id", filter=Q(created_at__date=audit_date)),
        )
        self.check_ins_today = booking_stats["check_ins"] or 0
        self.check_outs_today = booking_stats["check_outs"] or 0
        self.no_shows = booking_stats["no_shows"] or 0
        self.cancellations = booking_stats["cancellations"] or 0
        self.new_bookings = booking_stats["new_bookings"] or 0

        # Financial statistics from FinancialEntry
        financial_stats = FinancialEntry.objects.filter(date=audit_date).aggregate(
            total_income=Sum("amount", filter=Q(entry_type=FinancialEntry.EntryType.INCOME)),
            total_expense=Sum("amount", filter=Q(entry_type=FinancialEntry.EntryType.EXPENSE)),
            cash=Sum(
                "amount",
                filter=Q(
                    entry_type=FinancialEntry.EntryType.INCOME,
                    payment_method=Booking.PaymentMethod.CASH,
                ),
            ),
            bank_transfer=Sum(
                "amount",
                filter=Q(
                    entry_type=FinancialEntry.EntryType.INCOME,
                    payment_method=Booking.PaymentMethod.BANK_TRANSFER,
                ),
            ),
            momo=Sum(
                "amount",
                filter=Q(
                    entry_type=FinancialEntry.EntryType.INCOME,
                    payment_method=Booking.PaymentMethod.MOMO,
                ),
            ),
        )
        self.total_income = financial_stats["total_income"] or 0
        self.total_expense = financial_stats["total_expense"] or 0
        self.cash_collected = financial_stats["cash"] or 0
        self.bank_transfer_collected = financial_stats["bank_transfer"] or 0
        self.momo_collected = financial_stats["momo"] or 0
        self.other_payments = self.total_income - self.cash_collected - self.bank_transfer_collected - self.momo_collected

        # Room revenue from bookings checked out today
        room_revenue = Booking.objects.filter(
            check_out_date=audit_date,
            status=Booking.Status.CHECKED_OUT,
        ).aggregate(total=Sum("total_amount"))
        self.room_revenue = room_revenue["total"] or 0
        self.other_revenue = self.total_income - self.room_revenue
        self.net_revenue = self.total_income - self.total_expense

        # Pending payments - bookings that are checked in but not fully paid
        pending = Booking.objects.filter(
            status=Booking.Status.CHECKED_IN,
            is_paid=False,
        ).aggregate(
            total=Sum("total_amount"),
            count=Count("id"),
        )
        self.pending_payments = pending["total"] or 0
        self.unpaid_bookings_count = pending["count"] or 0

    def close_audit(self, user):
        """Close the audit - no more changes allowed"""
        from django.utils import timezone

        self.status = self.Status.CLOSED
        self.closed_by = user
        self.closed_at = timezone.now()
        self.save()


class LostAndFound(models.Model):
    """Track items left by guests or found in the hotel"""

    class Status(models.TextChoices):
        FOUND = "found", "Đã tìm thấy"
        STORED = "stored", "Đang lưu giữ"
        CLAIMED = "claimed", "Đã trả khách"
        DONATED = "donated", "Đã quyên góp"
        DISPOSED = "disposed", "Đã tiêu hủy"

    class Category(models.TextChoices):
        ELECTRONICS = "electronics", "Đồ điện tử"
        CLOTHING = "clothing", "Quần áo"
        JEWELRY = "jewelry", "Trang sức"
        DOCUMENTS = "documents", "Giấy tờ"
        MONEY = "money", "Tiền"
        BAGS = "bags", "Túi/Vali"
        PERSONAL = "personal", "Đồ cá nhân"
        OTHER = "other", "Khác"

    # Item details
    item_name = models.CharField(max_length=200, verbose_name="Tên vật phẩm")
    description = models.TextField(blank=True, verbose_name="Mô tả chi tiết")
    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        default=Category.OTHER,
        verbose_name="Danh mục",
    )
    estimated_value = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá trị ước tính",
    )

    # Location info
    room = models.ForeignKey(
        Room,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="lost_items",
        verbose_name="Phòng",
    )
    found_location = models.CharField(
        max_length=200,
        blank=True,
        verbose_name="Nơi tìm thấy",
        help_text="Vị trí cụ thể nếu không phải phòng",
    )
    storage_location = models.CharField(
        max_length=200,
        blank=True,
        verbose_name="Nơi lưu giữ",
    )

    # Guest association (if known)
    guest = models.ForeignKey(
        Guest,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="lost_items",
        verbose_name="Khách hàng",
    )
    booking = models.ForeignKey(
        Booking,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="lost_items",
        verbose_name="Đặt phòng",
    )

    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.FOUND,
        verbose_name="Trạng thái",
    )
    found_date = models.DateField(verbose_name="Ngày tìm thấy")
    claimed_date = models.DateField(null=True, blank=True, verbose_name="Ngày trả khách")
    disposed_date = models.DateField(null=True, blank=True, verbose_name="Ngày tiêu hủy/quyên góp")

    # Staff info
    found_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="found_items",
        verbose_name="Người tìm thấy",
    )
    claimed_by_staff = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="returned_items",
        verbose_name="Nhân viên trả",
    )

    # Guest contact attempts
    guest_contacted = models.BooleanField(default=False, verbose_name="Đã liên hệ khách")
    contact_notes = models.TextField(blank=True, verbose_name="Ghi chú liên hệ")

    # Image documentation
    image = models.ImageField(
        upload_to="lost_found/",
        null=True,
        blank=True,
        verbose_name="Ảnh vật phẩm",
    )

    # Notes
    notes = models.TextField(blank=True, verbose_name="Ghi chú")

    # Audit
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Vật thất lạc"
        verbose_name_plural = "Vật thất lạc"
        ordering = ["-found_date", "-created_at"]

    def __str__(self):
        return f"{self.item_name} - {self.get_status_display()}"

    def claim(self, staff_user, notes=""):
        """Mark item as claimed/returned to guest"""
        from django.utils import timezone

        self.status = self.Status.CLAIMED
        self.claimed_date = timezone.now().date()
        self.claimed_by_staff = staff_user
        if notes:
            self.contact_notes = notes
        self.save()

    def dispose(self, method="disposed"):
        """Mark item as disposed or donated"""
        from django.utils import timezone

        if method == "donated":
            self.status = self.Status.DONATED
        else:
            self.status = self.Status.DISPOSED
        self.disposed_date = timezone.now().date()
        self.save()


class GroupBooking(models.Model):
    """Group booking for multiple rooms (tours, events, corporate)"""

    class Status(models.TextChoices):
        TENTATIVE = "tentative", "Đang chờ"
        CONFIRMED = "confirmed", "Đã xác nhận"
        CHECKED_IN = "checked_in", "Đang ở"
        CHECKED_OUT = "checked_out", "Đã trả phòng"
        CANCELLED = "cancelled", "Đã hủy"

    # Group info
    name = models.CharField(max_length=200, verbose_name="Tên đoàn/nhóm")
    contact_name = models.CharField(max_length=100, verbose_name="Người liên hệ")
    contact_phone = models.CharField(max_length=20, verbose_name="SĐT liên hệ")
    contact_email = models.EmailField(blank=True, verbose_name="Email")
    company = models.CharField(max_length=200, blank=True, verbose_name="Công ty/Tổ chức")

    # Dates
    check_in_date = models.DateField(verbose_name="Ngày nhận phòng")
    check_out_date = models.DateField(verbose_name="Ngày trả phòng")
    actual_check_in = models.DateTimeField(null=True, blank=True, verbose_name="Giờ nhận thực tế")
    actual_check_out = models.DateTimeField(null=True, blank=True, verbose_name="Giờ trả thực tế")

    # Room allocation
    room_count = models.PositiveIntegerField(verbose_name="Số phòng")
    guest_count = models.PositiveIntegerField(verbose_name="Số khách")
    rooms = models.ManyToManyField(Room, related_name="group_bookings", blank=True, verbose_name="Phòng")

    # Pricing
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Tổng tiền",
    )
    deposit_amount = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        default=0,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Tiền cọc",
    )
    deposit_paid = models.BooleanField(default=False, verbose_name="Đã đặt cọc")
    special_rate = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
        verbose_name="Giá đặc biệt/đêm",
    )
    discount_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        verbose_name="Giảm giá (%)",
    )
    currency = models.CharField(max_length=3, default="VND", verbose_name="Tiền tệ")

    # Status
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.TENTATIVE,
        verbose_name="Trạng thái",
    )
    source = models.CharField(
        max_length=20,
        choices=Booking.Source.choices,
        default=Booking.Source.PHONE,
        verbose_name="Nguồn đặt",
    )

    # Notes
    notes = models.TextField(blank=True, verbose_name="Ghi chú")
    special_requests = models.TextField(blank=True, verbose_name="Yêu cầu đặc biệt")

    # Audit
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_group_bookings",
        verbose_name="Người tạo",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Đặt phòng nhóm"
        verbose_name_plural = "Đặt phòng nhóm"
        ordering = ["-check_in_date", "-created_at"]

    def __str__(self):
        return f"{self.name} ({self.room_count} phòng, {self.check_in_date})"

    @property
    def nights(self):
        """Calculate number of nights"""
        return (self.check_out_date - self.check_in_date).days

    @property
    def balance_due(self):
        """Calculate remaining balance"""
        return self.total_amount - self.deposit_amount
