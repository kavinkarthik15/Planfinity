import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import FIREBASE_API_KEY, FIREBASE_CREDENTIALS_PATH

API_KEY = FIREBASE_API_KEY

if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)


def send_notification(token: str, title: str, body: str) -> str:
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='planfinity_alerts',
                sound='default',
            ),
        ),
        apns=messaging.APNSConfig(
            headers={'apns-priority': '10'},
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound='default')
            ),
        ),
        token=token,
    )

    return messaging.send(message)
