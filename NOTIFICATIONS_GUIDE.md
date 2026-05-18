# NexSpend Notification & Reminder Setup Guide

This document summarizes the fixes and enhancements made to the notification system to ensure reliable and "Better than MMS" reminders.

---

## 🛠 Fixes Implemented

### 1. Timezone Synchronization
Fixed a bug where the app was falling back to **UTC** instead of your local timezone (+05:30). This was causing notifications to be 5.5 hours late.
- **File**: `lib/services/notification_service.dart`
- **Fix**: Correctly handling the `TimezoneInfo` object returned by the device.

### 2. Android Background Receivers
Fixed a package naming bug where the background receivers were using `flutter_local_notifications` (with underscores) instead of `flutterlocalnotifications` (no underscores). Without this exact class path, Android was unable to register the receivers and silently ignored all scheduled reminders.
- **File**: `android/app/src/main/AndroidManifest.xml`
- **Fix**: Reconfigured `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` and `com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver` correctly.

---

## 🌟 Enhanced "Rich" Notifications
We upgraded the system to provide a premium, multimedia experience similar to MMS but interactive.

### Features:
- **Visual Banners**: Beautiful 3D glassmorphism banners included in every reminder.
- **Quick Actions**: Buttons on the notification to "Add Expense" or "Dismiss" without opening the app.
- **Test Mode**: A dedicated button in Settings to verify everything is working.

---

## 📋 How to Test & Maintain

### Testing the Setup:
1. Open **Settings** in the app.
2. Tap **"Send Test Notification"**.
3. Expand the notification on your lock screen to see the image and buttons.

### Troubleshooting (If not received):
If notifications stop appearing, check these system settings on your Android device:
1. **App Info > Notifications**: Must be "Allowed".
2. **App Info > Battery Saver**: Set to **"No Restrictions"**.
3. **Special App Access > Alarms & Reminders**: Ensure the app is "Allowed".

---

## 📁 Key Files
- `lib/services/notification_service.dart`: Main logic for scheduling and actions.
- `android/app/src/main/res/drawable/reminder_banner.jpg`: High-res image for notifications.
- `lib/screens/settings_screen.dart`: UI for managing reminder times and testing.

---
*NexSpend - Smart Expense Tracking*
