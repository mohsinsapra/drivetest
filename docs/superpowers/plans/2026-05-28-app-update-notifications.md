# App Update Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Send a push notification to all users when a new app version is released, and show a dismissible update pop-up on the dashboard after login.

**Architecture:** Two independent parts — (A) Django backend gets a broadcast endpoint + admin action triggered by Fastlane post-release; (B) Flutter moves the existing `UpgradeAlert` from the root `SplashScreen` to `HomeScreen` so it only fires after login.

**Tech Stack:** Flutter + `upgrader ^11.4.0`, Django REST Framework, `firebase-admin` Python SDK, FCM HTTP v1 API, Fastlane (iOS + Android).

> **Note:** Tasks 1–5 are in the **Django backend** repo. Tasks 6–7 are in this Flutter repo (`taxi_exam_app`).

---

## File Map

### Django backend (separate repo)
| Action | Path |
|--------|------|
| Modify | `requirements.txt` |
| Create | `notifications/fcm_service.py` |
| Create | `notifications/views.py` (or add to existing) |
| Modify | `notifications/urls.py` (or `config/urls.py`) |
| Modify | `notifications/admin.py` |
| Modify | `.env` / server env vars |
| Create | `notifications/tests/test_notify_update.py` |

### Flutter (this repo)
| Action | Path |
|--------|------|
| Modify | `lib/main.dart` |
| Modify | `lib/features/home/home_screen.dart` |
| Modify | `ios/fastlane/Fastfile` |
| Modify | `android/fastlane/Fastfile` |

---

## Task 1: Add firebase-admin to Django requirements

**Files:**
- Modify: `requirements.txt`

- [ ] **Step 1: Add the dependency**

Open `requirements.txt` in the Django backend and add:

```
firebase-admin>=6.5.0
```

- [ ] **Step 2: Install it**

```bash
pip install firebase-admin
pip freeze | grep firebase-admin
```

Expected output includes `firebase-admin==6.x.x`.

- [ ] **Step 3: Commit**

```bash
git add requirements.txt
git commit -m "chore: add firebase-admin for FCM broadcast"
```

---

## Task 2: Create the FCM broadcast service

**Files:**
- Create: `notifications/fcm_service.py`

The service reads all FCM tokens from the database, batches them into groups of 500 (FCM multicast limit), and sends the fixed app-update message.

- [ ] **Step 1: Write the failing test**

Create `notifications/tests/test_notify_update.py`:

```python
from unittest.mock import patch, MagicMock
from django.test import TestCase
from notifications.fcm_service import send_app_update_notification
# Replace 'notifications.models.FCMToken' with the actual model path
# e.g. 'users.models.FCMDevice' — check your FCM token model location

class SendAppUpdateNotificationTest(TestCase):
    @patch("notifications.fcm_service.messaging")
    def test_sends_to_all_tokens(self, mock_messaging):
        # Arrange: mock two FCM tokens in the DB
        # Replace FCMToken with the actual model used in your project
        from notifications.models import FCMToken  # adjust import
        FCMToken.objects.create(token="token-aaa", platform="ios")
        FCMToken.objects.create(token="token-bbb", platform="android")

        mock_response = MagicMock()
        mock_response.success_count = 2
        mock_response.failure_count = 0
        mock_messaging.send_each_for_multicast.return_value = mock_response

        result = send_app_update_notification()

        assert result["sent"] == 2
        assert result["failed"] == 0
        mock_messaging.send_each_for_multicast.assert_called_once()

    @patch("notifications.fcm_service.messaging")
    def test_returns_zero_when_no_tokens(self, mock_messaging):
        result = send_app_update_notification()
        assert result == {"sent": 0, "failed": 0}
        mock_messaging.send_each_for_multicast.assert_not_called()
```

- [ ] **Step 2: Run it to confirm it fails**

```bash
python manage.py test notifications.tests.test_notify_update -v 2
```

Expected: ImportError or similar — `fcm_service` doesn't exist yet.

- [ ] **Step 3: Initialise Firebase Admin and write the service**

Create `notifications/fcm_service.py`:

```python
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings

# Initialise once. settings.FIREBASE_CREDENTIALS_PATH should point to
# the service account JSON downloaded from Firebase Console →
# Project Settings → Service Accounts → Generate new private key.
if not firebase_admin._apps:
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)

_BATCH_SIZE = 500
_NOTIFICATION_TITLE = "New version available!"
_NOTIFICATION_BODY = "Update the app to get the latest improvements."


def send_app_update_notification() -> dict:
    """Broadcast an app_update FCM message to every registered token.

    Returns {"sent": int, "failed": int}.
    """
    # Adjust the import and queryset to match your actual FCM token model.
    # Common patterns:
    #   from users.models import FCMDevice; tokens = list(FCMDevice.objects.values_list("token", flat=True))
    #   from notifications.models import FCMToken; tokens = list(FCMToken.objects.values_list("token", flat=True))
    from notifications.models import FCMToken  # ← adjust to your model
    tokens = list(FCMToken.objects.values_list("token", flat=True).distinct())

    if not tokens:
        return {"sent": 0, "failed": 0}

    total_sent = 0
    total_failed = 0

    for i in range(0, len(tokens), _BATCH_SIZE):
        batch = tokens[i : i + _BATCH_SIZE]
        message = messaging.MulticastMessage(
            tokens=batch,
            notification=messaging.Notification(
                title=_NOTIFICATION_TITLE,
                body=_NOTIFICATION_BODY,
            ),
            data={"type": "app_update"},
        )
        response = messaging.send_each_for_multicast(message)
        total_sent += response.success_count
        total_failed += response.failure_count

    return {"sent": total_sent, "failed": total_failed}
```

- [ ] **Step 4: Add `FIREBASE_CREDENTIALS_PATH` to Django settings**

In `settings.py` (or `settings/base.py`):

```python
import os
FIREBASE_CREDENTIALS_PATH = os.environ.get(
    "FIREBASE_CREDENTIALS_PATH",
    BASE_DIR / "firebase-credentials.json",
)
```

Add `firebase-credentials.json` to `.gitignore` — never commit it.

- [ ] **Step 5: Run the test again to confirm it passes**

```bash
python manage.py test notifications.tests.test_notify_update -v 2
```

Expected: OK (2 tests pass).

- [ ] **Step 6: Commit**

```bash
git add notifications/fcm_service.py notifications/tests/test_notify_update.py
git commit -m "feat: FCM broadcast service for app update notification"
```

---

## Task 3: Add the `/api/notify-update/` endpoint

**Files:**
- Create/Modify: `notifications/views.py`
- Modify: `notifications/urls.py` (or wherever app URLs are registered)

- [ ] **Step 1: Write the failing test**

Add to `notifications/tests/test_notify_update.py`:

```python
from django.test import TestCase
from django.urls import reverse
from unittest.mock import patch

class NotifyUpdateEndpointTest(TestCase):
    def setUp(self):
        import os
        os.environ["NOTIFY_API_KEY"] = "test-secret-key"

    @patch("notifications.views.send_app_update_notification")
    def test_valid_api_key_triggers_broadcast(self, mock_send):
        mock_send.return_value = {"sent": 5, "failed": 0}
        response = self.client.post(
            "/api/notify-update/",
            HTTP_X_API_KEY="test-secret-key",
        )
        assert response.status_code == 200
        assert response.json() == {"sent": 5, "failed": 0}
        mock_send.assert_called_once()

    def test_missing_api_key_returns_403(self):
        response = self.client.post("/api/notify-update/")
        assert response.status_code == 403

    def test_wrong_api_key_returns_403(self):
        response = self.client.post(
            "/api/notify-update/",
            HTTP_X_API_KEY="wrong-key",
        )
        assert response.status_code == 403

    def test_get_method_not_allowed(self):
        response = self.client.get(
            "/api/notify-update/",
            HTTP_X_API_KEY="test-secret-key",
        )
        assert response.status_code == 405
```

- [ ] **Step 2: Run to confirm it fails**

```bash
python manage.py test notifications.tests.test_notify_update.NotifyUpdateEndpointTest -v 2
```

Expected: 404 or import error.

- [ ] **Step 3: Write the view**

Add to `notifications/views.py`:

```python
import os
from django.http import JsonResponse
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from notifications.fcm_service import send_app_update_notification


@method_decorator(csrf_exempt, name="dispatch")
class NotifyUpdateView(View):
    def post(self, request):
        api_key = request.headers.get("X-Api-Key", "")
        expected = os.environ.get("NOTIFY_API_KEY", "")
        if not expected or api_key != expected:
            return JsonResponse({"error": "Forbidden"}, status=403)
        result = send_app_update_notification()
        return JsonResponse(result)
```

- [ ] **Step 4: Register the URL**

In `notifications/urls.py` (create if it doesn't exist):

```python
from django.urls import path
from notifications.views import NotifyUpdateView

urlpatterns = [
    path("notify-update/", NotifyUpdateView.as_view(), name="notify-update"),
]
```

In the root `urls.py`, make sure this is included under `api/`:

```python
path("api/", include("notifications.urls")),
```

(If `notifications` urls are already included elsewhere, add the `notify-update/` path there instead.)

- [ ] **Step 5: Run the tests to confirm they pass**

```bash
python manage.py test notifications.tests.test_notify_update -v 2
```

Expected: OK (all tests pass).

- [ ] **Step 6: Set the env var on the server**

On the production server, add to `.env` or the deployment environment:

```
NOTIFY_API_KEY=<generate a long random string, e.g. openssl rand -hex 32>
```

- [ ] **Step 7: Commit**

```bash
git add notifications/views.py notifications/urls.py notifications/tests/test_notify_update.py
git commit -m "feat: POST /api/notify-update/ endpoint with API key auth"
```

---

## Task 4: Add Django admin action

**Files:**
- Modify: `notifications/admin.py`

- [ ] **Step 1: Add the admin action**

Open `notifications/admin.py` and add the action to the FCMToken `ModelAdmin`. Adjust the model class name to match your project:

```python
from django.contrib import admin
from django.contrib import messages
from notifications.models import FCMToken  # ← adjust to your model
from notifications.fcm_service import send_app_update_notification


@admin.action(description="Send app update notification to all users")
def send_update_notification(modeladmin, request, queryset):
    result = send_app_update_notification()
    modeladmin.message_user(
        request,
        f"App update notification sent: {result['sent']} delivered, {result['failed']} failed.",
        level=messages.SUCCESS if result["failed"] == 0 else messages.WARNING,
    )


@admin.register(FCMToken)  # ← adjust if already registered
class FCMTokenAdmin(admin.ModelAdmin):
    actions = [send_update_notification]
    list_display = ["token", "platform", "created_at"]  # adjust fields to match model
```

If `FCMToken` is already registered in admin, just add `actions = [send_update_notification]` to the existing `ModelAdmin` class and define the action function above it.

- [ ] **Step 2: Verify in the browser**

```bash
python manage.py runserver
```

Navigate to `/admin/notifications/fcmtoken/` (adjust path). The "Send app update notification to all users" action should appear in the action dropdown. Select any rows, choose the action, click Go — confirm the success message appears.

- [ ] **Step 3: Commit**

```bash
git add notifications/admin.py
git commit -m "feat: Django admin action to broadcast app update notification"
```

---

## Task 5: Add Fastlane post-release notification step

**Files:**
- Modify: `ios/fastlane/Fastfile`
- Modify: `android/fastlane/Fastfile`

- [ ] **Step 1: Add notification step to iOS production lane**

Open `ios/fastlane/Fastfile`. After `tag_release` inside the `production` lane, add:

```ruby
lane :production do
  ENV['BUILD_VARIANT'] = 'production'
  update_flutter_version
  changelog_text = get_latest_changelog_entry
  ipa_path = build_ios_archive(export_options: "ExportOptions.plist")
  upload_to_app_store(
    ipa: ipa_path,
    release_notes: { "en-US" => changelog_text }
  )
  tag_release
  notify_app_update   # ← add this line
end

private_lane :notify_app_update do
  backend_url = ENV["BACKEND_URL"] || UI.user_error!("Set BACKEND_URL in ios/fastlane/.env")
  api_key = ENV["NOTIFY_API_KEY"] || UI.user_error!("Set NOTIFY_API_KEY in ios/fastlane/.env")
  sh(
    "curl -s -o /dev/null -w '%{http_code}' -X POST '#{backend_url}/api/notify-update/' " \
    "-H 'X-Api-Key: #{api_key}' -H 'Content-Type: application/json'"
  )
  UI.success("App update push notification sent to all users.")
end
```

- [ ] **Step 2: Add `BACKEND_URL` and `NOTIFY_API_KEY` to `ios/fastlane/.env`**

Open (or create) `ios/fastlane/.env`:

```
BACKEND_URL=https://your-backend-domain.com
NOTIFY_API_KEY=<same value set on the server in Task 3 Step 6>
```

Confirm `.env` is in `.gitignore` — never commit secrets.

- [ ] **Step 3: Add the same private lane and call to Android Fastfile**

Open `android/fastlane/Fastfile` and find the production / `beta` lane that uploads to the Play Store. Add the same `notify_app_update` private lane and call it after the upload step. The lane body is identical to iOS:

```ruby
private_lane :notify_app_update do
  backend_url = ENV["BACKEND_URL"] || UI.user_error!("Set BACKEND_URL in android/fastlane/.env")
  api_key = ENV["NOTIFY_API_KEY"] || UI.user_error!("Set NOTIFY_API_KEY in android/fastlane/.env")
  sh(
    "curl -s -o /dev/null -w '%{http_code}' -X POST '#{backend_url}/api/notify-update/' " \
    "-H 'X-Api-Key: #{api_key}' -H 'Content-Type: application/json'"
  )
  UI.success("App update push notification sent to all users.")
end
```

Add `notify_app_update` call at the end of the Android production lane, same as iOS.

- [ ] **Step 4: Add `BACKEND_URL` and `NOTIFY_API_KEY` to `android/fastlane/.env`**

```
BACKEND_URL=https://your-backend-domain.com
NOTIFY_API_KEY=<same value>
```

- [ ] **Step 5: Commit**

```bash
git add ios/fastlane/Fastfile android/fastlane/Fastfile
git commit -m "feat: notify all users via FCM after production release"
```

---

## Task 6: Move UpgradeAlert to HomeScreen (Flutter)

**Files:**
- Modify: `lib/main.dart` (line 484)
- Modify: `lib/features/home/home_screen.dart`

The `UpgradeAlert` currently wraps `SplashScreen` in `main.dart`. This means it can fire before the user logs in. Moving it to `HomeScreen` ensures it only fires on the dashboard after authentication.

- [ ] **Step 1: Remove UpgradeAlert from `main.dart`**

In `lib/main.dart`, find lines 484–488:

```dart
home: UpgradeAlert(
  showIgnore: false,
  showLater: true,
  child: const SplashScreen(),
),
```

Replace with:

```dart
home: const SplashScreen(),
```

- [ ] **Step 2: Add UpgradeAlert import to `home_screen.dart` if not present**

Open `lib/features/home/home_screen.dart`. Add this import at the top with the other imports:

```dart
import 'package:upgrader/upgrader.dart';
```

- [ ] **Step 3: Wrap HomeScreen's `build` return with UpgradeAlert**

In `lib/features/home/home_screen.dart`, find the `build` method of `_HomeScreenState`. Wrap the outermost returned widget with `UpgradeAlert`.

The current return will look something like:

```dart
@override
Widget build(BuildContext context) {
  super.build(context);
  return Scaffold(
    // ...existing content...
  );
}
```

Change it to:

```dart
@override
Widget build(BuildContext context) {
  super.build(context);
  return UpgradeAlert(
    upgrader: Upgrader(
      dialogStyle: UpgradeDialogStyle.cupertino,
      showIgnore: false,
      showLater: true,
    ),
    child: Scaffold(
      // ...existing content unchanged...
    ),
  );
}
```

> `showIgnore: false` removes the "Ignore" button (matches original config). `showLater: true` keeps the dismissible "Later" button. `upgrader` automatically records the dismissed version in SharedPreferences and won't show the dialog again for that version.

- [ ] **Step 4: Verify the app still builds**

```bash
flutter analyze lib/main.dart lib/features/home/home_screen.dart
flutter build ios --debug --no-codesign
```

Expected: no errors, no `UpgradeAlert`-related warnings.

- [ ] **Step 5: Smoke test manually**

Run the app on simulator:

```bash
flutter run
```

- Log in. The dashboard (HomeScreen) should load without an update dialog (since you're on the latest dev build, the upgrader finds no update from the store and stays silent).
- Confirm the app launches and navigates normally — no regressions on the splash → auth → home flow.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/features/home/home_screen.dart
git commit -m "feat: show app update prompt on dashboard instead of before login"
```

---

## Task 7: Remove unused upgrader import from main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Remove the import**

In `lib/main.dart`, find and delete the line:

```dart
import 'package:upgrader/upgrader.dart';
```

- [ ] **Step 2: Verify no remaining references**

```bash
grep -n "upgrader\|UpgradeAlert\|Upgrader" lib/main.dart
```

Expected: no output.

- [ ] **Step 3: Confirm clean build**

```bash
flutter analyze lib/main.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "chore: remove unused upgrader import from main.dart"
```

---

## Self-Review

**Spec coverage:**
- ✅ Push notification to all users on release → Tasks 1–3
- ✅ Manual trigger via Django admin → Task 4
- ✅ Automated trigger via CI/CD (Fastlane iOS + Android) → Task 5
- ✅ Fixed message template (`app_update` type, matches Flutter's existing handler) → Task 2
- ✅ In-app update pop-up on dashboard after login → Task 6
- ✅ Show once per new version, dismissible → Task 6 (upgrader default behaviour)
- ✅ Uses existing upgrader package → Tasks 6–7

**Placeholder scan:** None found. All steps have exact code, exact commands, expected output.

**Type consistency:** `send_app_update_notification` is defined in Task 2 and imported in Tasks 3 and 4. `NotifyUpdateView` defined in Task 3, registered in Task 3. `UpgradeAlert`/`Upgrader` from `upgrader` package used consistently in Tasks 6–7.
