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
        verbose_name="Giá cơ bản",
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
        """Calculate remaining balance including additional charges"""
        return self.total_amount + self.additional_charges - self.deposit_amount


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
