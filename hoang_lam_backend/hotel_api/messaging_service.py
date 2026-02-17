"""
Guest messaging services for SMS, Email, and Zalo integration.

Phase 5.3: Guest Communication
"""

import logging

import requests
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger("hotel_api")


class SMSService:
    """
    SMS sending service.

    In production, integrate with a Vietnamese SMS gateway such as:
    - eSMS.vn
    - SpeedSMS.vn
    - Vietguys.biz

    For MVP, this creates message records with 'sent' status for tracking.
    """

    @classmethod
    def send(cls, phone_number: str, message: str) -> dict:
        """
        Send an SMS to a phone number.

        Args:
            phone_number: Recipient phone number (Vietnamese format)
            message: SMS body text

        Returns:
            dict with 'success' (bool), 'message_id' (str), 'error' (str)
        """
        # Validate phone number
        if not phone_number:
            return {
                "success": False,
                "message_id": "",
                "error": "Số điện thoại không hợp lệ",
            }

        sms_enabled = getattr(settings, "SMS_ENABLED", False)

        if not sms_enabled:
            logger.info(
                f"SMS disabled. Would send to {phone_number}: {message[:50]}..."
            )
            return {
                "success": True,
                "message_id": f"mock-sms-{timezone.now().timestamp():.0f}",
                "error": "",
            }

        # eSMS.vn production integration
        try:
            response = requests.post(
                "https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post",
                json={
                    "ApiKey": settings.SMS_API_KEY,
                    "SecretKey": settings.SMS_SECRET_KEY,
                    "Phone": phone_number,
                    "Content": message,
                    "SmsType": "2",
                    "Brandname": settings.SMS_BRAND_NAME,
                },
                timeout=30,
            )
            response.raise_for_status()
            data = response.json()

            success = str(data.get("CodeResult")) == "100"
            return {
                "success": success,
                "message_id": data.get("SMSID", ""),
                "error": "" if success else data.get(
                    "ErrorMessage", f"eSMS error code: {data.get('CodeResult')}"
                ),
            }
        except requests.Timeout:
            logger.error(f"SMS timeout sending to {phone_number}")
            return {"success": False, "message_id": "", "error": "SMS gateway timeout"}
        except requests.RequestException as e:
            logger.error(f"SMS request error to {phone_number}: {e}")
            return {"success": False, "message_id": "", "error": str(e)}
        except Exception as e:
            logger.error(f"SMS unexpected error to {phone_number}: {e}")
            return {"success": False, "message_id": "", "error": str(e)}


class EmailService:
    """
    Email sending service using Django's email backend.

    Uses Django's built-in email functionality, which can be configured
    for SMTP, SendGrid, Mailgun, etc. in settings.
    """

    @classmethod
    def send(cls, to_email: str, subject: str, body: str, html_body: str = "") -> dict:
        """
        Send an email.

        Args:
            to_email: Recipient email address
            subject: Email subject
            body: Plain text body
            html_body: Optional HTML body

        Returns:
            dict with 'success' (bool), 'message_id' (str), 'error' (str)
        """
        if not to_email:
            return {
                "success": False,
                "message_id": "",
                "error": "Email không hợp lệ",
            }

        email_enabled = getattr(settings, "EMAIL_ENABLED", False)

        if not email_enabled:
            logger.info(f"Email disabled. Would send to {to_email}: {subject}")
            return {
                "success": True,
                "message_id": f"mock-email-{timezone.now().timestamp():.0f}",
                "error": "",
            }

        try:
            from django.core.mail import send_mail

            send_mail(
                subject=subject,
                message=body,
                html_message=html_body or None,
                from_email=getattr(
                    settings, "DEFAULT_FROM_EMAIL", "noreply@hoanglam.vn"
                ),
                recipient_list=[to_email],
                fail_silently=False,
            )
            return {
                "success": True,
                "message_id": f"email-{timezone.now().timestamp():.0f}",
                "error": "",
            }
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}")
            return {
                "success": False,
                "message_id": "",
                "error": str(e),
            }


class ZaloService:
    """
    Zalo OA (Official Account) messaging service.

    Requires Zalo OA registration and API key.
    See: https://developers.zalo.me/docs/official-account

    For MVP, this is a stub that logs messages.
    """

    @classmethod
    def send(cls, phone_number: str, message: str) -> dict:
        """
        Send a Zalo message.

        Args:
            phone_number: Recipient phone number (linked to Zalo account)
            message: Message body

        Returns:
            dict with 'success' (bool), 'message_id' (str), 'error' (str)
        """
        if not phone_number:
            return {
                "success": False,
                "message_id": "",
                "error": "Số điện thoại không hợp lệ",
            }

        zalo_enabled = getattr(settings, "ZALO_ENABLED", False)

        if not zalo_enabled:
            logger.info(
                f"Zalo disabled. Would send to {phone_number}: {message[:50]}..."
            )
            return {
                "success": True,
                "message_id": f"mock-zalo-{timezone.now().timestamp():.0f}",
                "error": "",
            }

        # Production Zalo OA integration would go here
        # Example:
        # try:
        #     response = requests.post(
        #         "https://openapi.zalo.me/v3.0/oa/message/cs",
        #         headers={
        #             "access_token": settings.ZALO_OA_ACCESS_TOKEN,
        #         },
        #         json={
        #             "recipient": {"user_id": zalo_user_id},
        #             "message": {"text": message},
        #         }
        #     )
        #     ...

        return {
            "success": True,
            "message_id": f"mock-zalo-{timezone.now().timestamp():.0f}",
            "error": "",
        }


class GuestMessagingService:
    """
    Unified guest messaging service that routes messages to the appropriate channel.
    """

    CHANNEL_SERVICES = {
        "sms": SMSService,
        "email": EmailService,
        "zalo": ZaloService,
    }

    @classmethod
    def get_recipient_address(cls, guest, channel: str) -> str:
        """
        Get the recipient address for a guest based on channel.

        Args:
            guest: Guest model instance
            channel: Message channel (sms, email, zalo)

        Returns:
            str: Recipient address (phone or email)
        """
        if channel == "email":
            return guest.email or ""
        return guest.phone or ""

    @classmethod
    def render_template(cls, template, guest, booking=None) -> tuple:
        """
        Render a message template with guest and booking context.

        Args:
            template: MessageTemplate instance
            guest: Guest instance
            booking: Optional Booking instance

        Returns:
            tuple: (rendered_subject, rendered_body)
        """
        context = {
            "guest_name": guest.full_name,
            "hotel_name": "Hoàng Lâm Heritage Suites",
            "hotel_phone": "0xxx xxx xxx",
            "wifi_password": "hoanglam2026",
        }

        if booking:
            context.update(
                {
                    "room_number": str(booking.room.number) if booking.room else "",
                    "room_type": (
                        booking.room.room_type.name if booking.room and booking.room.room_type else ""
                    ),
                    "check_in_date": (
                        booking.check_in_date.strftime("%d/%m/%Y")
                        if booking.check_in_date
                        else ""
                    ),
                    "check_out_date": (
                        booking.check_out_date.strftime("%d/%m/%Y")
                        if booking.check_out_date
                        else ""
                    ),
                    "total_amount": f"{booking.total_amount:,.0f}đ" if booking.total_amount else "0đ",
                    "nights": str(
                        (booking.check_out_date - booking.check_in_date).days
                        if booking.check_in_date and booking.check_out_date
                        else 0
                    ),
                    "booking_source": booking.get_source_display() if hasattr(booking, "get_source_display") else "",
                }
            )

        return template.render(context)

    @classmethod
    def send_message(cls, guest_message) -> bool:
        """
        Send a GuestMessage via the appropriate channel.

        Args:
            guest_message: GuestMessage model instance

        Returns:
            bool: True if sent successfully
        """
        channel = guest_message.channel
        service_class = cls.CHANNEL_SERVICES.get(channel)

        if not service_class:
            guest_message.status = "failed"
            guest_message.send_error = f"Unsupported channel: {channel}"
            guest_message.save(update_fields=["status", "send_error"])
            return False

        # Get recipient address
        recipient = guest_message.recipient_address
        if not recipient:
            recipient = cls.get_recipient_address(guest_message.guest, channel)
            guest_message.recipient_address = recipient

        if not recipient:
            guest_message.status = "failed"
            guest_message.send_error = (
                "Không có thông tin liên hệ phù hợp cho kênh này"
            )
            guest_message.save(update_fields=["status", "send_error", "recipient_address"])
            return False

        # Update status to pending
        guest_message.status = "pending"
        guest_message.save(update_fields=["status"])

        # Send via appropriate service
        try:
            if channel == "email":
                result = service_class.send(
                    to_email=recipient,
                    subject=guest_message.subject,
                    body=guest_message.body,
                )
            else:
                result = service_class.send(
                    phone_number=recipient,
                    message=f"{guest_message.subject}\n\n{guest_message.body}",
                )

            if result["success"]:
                guest_message.status = "sent"
                guest_message.sent_at = timezone.now()
                guest_message.send_error = ""
                guest_message.save(
                    update_fields=["status", "sent_at", "send_error", "recipient_address"]
                )
                logger.info(
                    f"Message sent via {channel} to {recipient} "
                    f"(message_id: {result.get('message_id', 'N/A')})"
                )
                return True
            else:
                guest_message.status = "failed"
                guest_message.send_error = result.get("error", "Unknown error")
                guest_message.save(update_fields=["status", "send_error", "recipient_address"])
                logger.error(
                    f"Failed to send message via {channel} to {recipient}: "
                    f"{result.get('error')}"
                )
                return False

        except Exception as e:
            guest_message.status = "failed"
            guest_message.send_error = str(e)
            guest_message.save(update_fields=["status", "send_error", "recipient_address"])
            logger.error(f"Exception sending message via {channel}: {e}")
            return False
