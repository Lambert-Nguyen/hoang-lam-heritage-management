"""
Notification services for push notification delivery via Firebase Cloud Messaging.
"""

import logging

from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone

logger = logging.getLogger("hotel_api")

User = get_user_model()


class PushNotificationService:
    """
    Service for sending push notifications via Firebase Cloud Messaging.

    Gracefully degrades when FCM is not configured (development).
    Creates Notification records regardless of FCM availability.
    """

    _firebase_app = None
    _initialized = False

    @classmethod
    def _reset(cls):
        """Reset initialization state (for testing)."""
        cls._firebase_app = None
        cls._initialized = False

    @classmethod
    def _init_firebase(cls):
        """Lazy-initialize Firebase Admin SDK."""
        if cls._initialized:
            return cls._firebase_app is not None

        cls._initialized = True

        if not getattr(settings, "FCM_ENABLED", False):
            logger.info("FCM is disabled. Push notifications will be skipped.")
            return False

        try:
            import firebase_admin
            from firebase_admin import credentials

            cred = None
            cred_file = getattr(settings, "FCM_CREDENTIALS_FILE", "")
            cred_json = getattr(settings, "FCM_CREDENTIALS_JSON", "")

            if cred_file:
                cred = credentials.Certificate(cred_file)
            elif cred_json:
                import json

                cred_dict = json.loads(cred_json)
                cred = credentials.Certificate(cred_dict)
            else:
                logger.warning("FCM enabled but no credentials provided.")
                return False

            cls._firebase_app = firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized successfully.")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase: {e}")
            return False

    @classmethod
    def send_push_notification(cls, notification):
        """
        Send a push notification via FCM for a Notification record.

        Args:
            notification: Notification model instance

        Returns:
            bool: True if sent successfully (or FCM disabled), False on error
        """
        from .models import DeviceToken

        if not cls._init_firebase():
            logger.debug(
                f"FCM not available. Notification {notification.id} stored in DB only."
            )
            return True

        try:
            from firebase_admin import messaging

            tokens = list(
                DeviceToken.objects.filter(
                    user=notification.recipient,
                    is_active=True,
                ).values_list("token", flat=True)
            )

            if not tokens:
                logger.info(
                    f"No active device tokens for user {notification.recipient.username}"
                )
                return True

            message = messaging.MulticastMessage(
                tokens=tokens,
                notification=messaging.Notification(
                    title=notification.title,
                    body=notification.body,
                ),
                data=(
                    {k: str(v) for k, v in notification.data.items()}
                    if notification.data
                    else {}
                ),
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        click_action="FLUTTER_NOTIFICATION_CLICK",
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            badge=1,
                            sound="default",
                        ),
                    ),
                ),
            )

            response = messaging.send_each_for_multicast(message)

            # Deactivate invalid tokens
            if response.failure_count > 0:
                for i, send_response in enumerate(response.responses):
                    if send_response.exception:
                        error_code = getattr(send_response.exception, "code", "")
                        if error_code in ["NOT_FOUND", "UNREGISTERED", "INVALID_ARGUMENT"]:
                            DeviceToken.objects.filter(token=tokens[i]).update(
                                is_active=False
                            )
                            logger.info(f"Deactivated invalid token: {tokens[i][:20]}...")

            notification.is_sent = True
            notification.sent_at = timezone.now()
            notification.save(update_fields=["is_sent", "sent_at"])

            logger.info(
                f"Push notification sent: {response.success_count}/{len(tokens)} successful"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to send push notification: {e}")
            notification.send_error = str(e)
            notification.save(update_fields=["send_error"])
            return False

    @classmethod
    def notify_staff(
        cls,
        notification_type,
        title,
        body,
        data=None,
        booking=None,
        exclude_user=None,
    ):
        """
        Send a notification to all staff who have notifications enabled.

        Creates Notification records for each eligible staff member
        and sends push notifications.

        Args:
            notification_type: Notification.NotificationType value
            title: Notification title
            body: Notification body text
            data: Optional dict of additional data
            booking: Optional Booking instance to link
            exclude_user: Optional User to exclude (e.g., the action performer)

        Returns:
            list[Notification]: Created notification records
        """
        from .models import Notification

        staff_users = User.objects.filter(
            is_active=True,
            hotel_profile__is_active=True,
            hotel_profile__receive_notifications=True,
        )

        if exclude_user:
            staff_users = staff_users.exclude(pk=exclude_user.pk)

        notifications = []
        for user in staff_users:
            notification = Notification.objects.create(
                recipient=user,
                notification_type=notification_type,
                title=title,
                body=body,
                data=data or {},
                booking=booking,
            )
            cls.send_push_notification(notification)
            notifications.append(notification)

        return notifications
