# Changelog

## [Unreleased] — Smart Daily Expense Reminder Notifications

### New Dependencies (pubspec.yaml)
- `flutter_local_notifications: ^18.0.1` — schedules and displays local notifications
- `timezone: ^0.9.4` — timezone-aware scheduling
- `flutter_timezone: ^1.0.4` — reads device local timezone
- `shared_preferences: ^2.3.3` — persists notification settings across restarts

---

### New Files

#### `lib/services/notification_service.dart`
- Initialises `flutter_local_notifications` plugin on app startup
- Detects device timezone via `flutter_timezone` so alarms fire at the correct local time
- Requests `POST_NOTIFICATIONS` permission on Android 13+
- `scheduleDailyNotifications()` — cancels existing and schedules 3 repeating daily alarms:
  - ID 1001 → Morning (default 09:00) — "Good Morning ☀️ Don't forget to track today's expenses."
  - ID 1002 → Evening (default 17:00) — "Evening Reminder 💰 Add your spending before you forget."
  - ID 1003 → Night  (default 21:00) — "Daily Expense Check 🌙 Update your expenses for today."
- Uses `AndroidScheduleMode.exactAllowWhileIdle` + `DateTimeComponents.time` for daily repeat
- All methods are no-ops on web (`kIsWeb` guard)

#### `lib/providers/notification_provider.dart`
- `NotificationSettings` data class — holds `enabled`, `morningTime`, `eveningTime`, `nightTime`
- `NotificationNotifier` (Riverpod `StateNotifier`):
  - Loads saved settings from `SharedPreferences` on first read
  - `setEnabled(bool)` — toggles all notifications on/off
  - `updateTime(slot, TimeOfDay)` — updates morning / evening / night time
  - Saves to `SharedPreferences` and reschedules notifications on every change
- `notificationProvider` — global `StateNotifierProvider`

#### `lib/screens/settings_screen.dart`
- Gradient header banner matching app design
- **Daily Reminders toggle** (`SwitchListTile`) — enables or disables all 3 notifications instantly
- When enabled, shows three tappable time tiles:
  - Morning (sun icon, amber)
  - Evening (twilight icon, indigo)
  - Night (moon icon, dark)
- Each tile shows the current time and opens a native `showTimePicker` on tap
- Info banner explaining notifications work when the app is closed

---

### Modified Files

#### `android/app/src/main/AndroidManifest.xml`
Added permissions required by `flutter_local_notifications`:
```
RECEIVE_BOOT_COMPLETED   — reschedule alarms after device reboot
VIBRATE                  — notification vibration
POST_NOTIFICATIONS       — show notifications on Android 13+
SCHEDULE_EXACT_ALARM     — exact alarm scheduling on Android 12+
USE_EXACT_ALARM          — exact alarm on Android 13+
```

#### `lib/main.dart`
- Added import for `notification_service.dart`
- Called `await NotificationService.initialize()` after Firebase init, before `runApp()`

#### `lib/screens/dashboard_screen.dart`
- Added import for `settings_screen.dart`
- Added bell icon button (`Icons.notifications_outlined`) to the `SliverAppBar` actions
- Tapping the bell navigates to `SettingsScreen`

#### `lib/screens/splash_screen.dart`
- Fixed missing `Future<void> _navigateToHome() async {` function declaration
  (the method body existed but the opening signature was accidentally deleted)

---

### How It Works

1. App launches → `NotificationService.initialize()` runs once
2. `NotificationNotifier` loads saved prefs and calls `scheduleDailyNotifications()`
3. Three exact daily alarms are registered with the OS
4. Alarms fire at the scheduled time even when the app is closed
5. User opens Settings (bell icon in dashboard) to toggle or change times
6. Any change instantly cancels old alarms and registers new ones
7. Settings survive app restarts via `SharedPreferences`
