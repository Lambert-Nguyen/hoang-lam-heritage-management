"""
Management command to seed default message templates.

Usage:
    python manage.py seed_message_templates
"""

from django.core.management.base import BaseCommand

from hotel_api.models import MessageTemplate

DEFAULT_TEMPLATES = [
    {
        "name": "Xác nhận đặt phòng (SMS)",
        "template_type": "booking_confirmation",
        "channel": "sms",
        "subject": "Xác nhận đặt phòng - {hotel_name}",
        "body": (
            "Kính chào {guest_name},\n\n"
            "Đặt phòng của bạn tại {hotel_name} đã được xác nhận.\n"
            "Phòng: {room_number} ({room_type})\n"
            "Nhận phòng: {check_in_date}\n"
            "Trả phòng: {check_out_date}\n"
            "Số đêm: {nights}\n\n"
            "Chúng tôi rất hân hạnh được đón tiếp bạn!\n"
            "SĐT: {hotel_phone}"
        ),
    },
    {
        "name": "Xác nhận đặt phòng (Email)",
        "template_type": "booking_confirmation",
        "channel": "email",
        "subject": "Xác nhận đặt phòng #{room_number} - {hotel_name}",
        "body": (
            "Kính chào {guest_name},\n\n"
            "Cảm ơn bạn đã đặt phòng tại {hotel_name}.\n\n"
            "Chi tiết đặt phòng:\n"
            "- Phòng: {room_number} ({room_type})\n"
            "- Nhận phòng: {check_in_date} (từ 14:00)\n"
            "- Trả phòng: {check_out_date} (trước 12:00)\n"
            "- Số đêm: {nights}\n"
            "- Tổng tiền: {total_amount}\n\n"
            "Nếu bạn có câu hỏi, vui lòng liên hệ: {hotel_phone}\n\n"
            "Trân trọng,\n"
            "{hotel_name}"
        ),
    },
    {
        "name": "Thông tin trước khi đến (SMS)",
        "template_type": "pre_arrival",
        "channel": "sms",
        "subject": "Thông tin nhận phòng - {hotel_name}",
        "body": (
            "Chào {guest_name},\n\n"
            "Ngày mai bạn sẽ nhận phòng tại {hotel_name}!\n"
            "Phòng: {room_number}\n"
            "Giờ nhận phòng: từ 14:00\n"
            "WiFi: {wifi_password}\n\n"
            "Chúng tôi sẵn sàng đón tiếp bạn!\n"
            "SĐT: {hotel_phone}"
        ),
    },
    {
        "name": "Thông tin trước khi đến (Email)",
        "template_type": "pre_arrival",
        "channel": "email",
        "subject": "Chào mừng đến {hotel_name} - Thông tin nhận phòng",
        "body": (
            "Kính chào {guest_name},\n\n"
            "Chúng tôi rất vui được đón tiếp bạn ngày mai tại {hotel_name}!\n\n"
            "Thông tin nhận phòng:\n"
            "- Phòng: {room_number} ({room_type})\n"
            "- Giờ nhận phòng: từ 14:00\n"
            "- Giờ trả phòng: trước 12:00\n\n"
            "Thông tin tiện ích:\n"
            "- WiFi: {wifi_password}\n"
            "- Liên hệ lễ tân: {hotel_phone}\n\n"
            "Hẹn gặp bạn sớm!\n\n"
            "Trân trọng,\n"
            "{hotel_name}"
        ),
    },
    {
        "name": "Nhắc trả phòng (SMS)",
        "template_type": "checkout_reminder",
        "channel": "sms",
        "subject": "Nhắc trả phòng - {hotel_name}",
        "body": (
            "Chào {guest_name},\n\n"
            "Xin nhắc bạn trả phòng {room_number} trước 12:00 hôm nay.\n"
            "Nếu cần gia hạn, vui lòng liên hệ lễ tân: {hotel_phone}\n\n"
            "Cảm ơn bạn đã lưu trú tại {hotel_name}!"
        ),
    },
    {
        "name": "Yêu cầu đánh giá (SMS)",
        "template_type": "review_request",
        "channel": "sms",
        "subject": "Cảm ơn bạn! - {hotel_name}",
        "body": (
            "Chào {guest_name},\n\n"
            "Cảm ơn bạn đã lưu trú tại {hotel_name}!\n"
            "Chúng tôi rất mong nhận được đánh giá của bạn "
            "để phục vụ tốt hơn.\n\n"
            "Hẹn gặp lại bạn!\n"
            "{hotel_name}"
        ),
    },
]


class Command(BaseCommand):
    help = "Seed default message templates for guest communication"

    def handle(self, *args, **options):
        created_count = 0
        for template_data in DEFAULT_TEMPLATES:
            _, created = MessageTemplate.objects.get_or_create(
                name=template_data["name"],
                defaults=template_data,
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'  Created template: {template_data["name"]}')
                )
            else:
                self.stdout.write(f'  Template exists: {template_data["name"]}')

        self.stdout.write(
            self.style.SUCCESS(
                f"\nDone! Created {created_count} new templates "
                f"({len(DEFAULT_TEMPLATES)} total)"
            )
        )
