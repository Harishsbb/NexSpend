import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'expense_reminders';
  static const _channelName = 'Expense Reminders';
  static const _channelDesc = 'Daily reminders to log your expenses';

  static const actionAdd = 'ACTION_ADD_EXPENSE';
  static const actionDismiss = 'ACTION_DISMISS';

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    debugPrint('NotificationService: Initializing NotificationService...');

    tz.initializeTimeZones();
    try {
      debugPrint('NotificationService: Fetching local timezone...');
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 2));
      String id;
      if (tzInfo is String) {
        id = tzInfo;
      } else {
        id = tzInfo.identifier.toString();
      }
      tz.setLocalLocation(tz.getLocation(id));
      debugPrint('NotificationService: Local timezone set to $id');
    } catch (e) {
      debugPrint('NotificationService: Error getting timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('ic_notification');
    try {
      debugPrint('NotificationService: Initializing local notifications plugin...');
      await _plugin.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: (details) {
          debugPrint('NotificationService: onDidReceiveNotificationResponse: ${details.payload} / ${details.actionId}');
          if (details.payload == actionAdd || details.actionId == actionAdd) {
            // Handle navigation or action here
            // This will be connected to the app UI
          }
        },
      );
      debugPrint('NotificationService plugin initialized successfully');
    } catch (e, s) {
      debugPrint('NotificationService plugin initialization failed: $e\n$s');
      rethrow;
    }

    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    debugPrint('NotificationService: requestPermissions called');
    if (!_initialized) {
      debugPrint('NotificationService: requestPermissions called before initialization, initializing first...');
      await initialize();
    }
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      debugPrint('NotificationService: requesting POST_NOTIFICATIONS permission...');
      final granted = await androidImpl?.requestNotificationsPermission();
      debugPrint('NotificationService: POST_NOTIFICATIONS permission granted: $granted');
      debugPrint('NotificationService: requesting EXACT_ALARMS permission...');
      final exactGranted = await androidImpl?.requestExactAlarmsPermission();
      debugPrint('NotificationService: EXACT_ALARMS permission granted: $exactGranted');
    } catch (e, s) {
      debugPrint('NotificationService: ERROR requesting permissions: $e\n$s');
    }
  }

  /// Re-reads saved prefs and reschedules notifications. Call at every app startup.
  static Future<void> scheduleFromPrefs() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await scheduleDailyNotifications(
      enabled: prefs.getBool('notif_enabled') ?? true,
      morningTime: TimeOfDay(
        hour: prefs.getInt('notif_morning_h') ?? 9,
        minute: prefs.getInt('notif_morning_m') ?? 0,
      ),
      eveningTime: TimeOfDay(
        hour: prefs.getInt('notif_evening_h') ?? 17,
        minute: prefs.getInt('notif_evening_m') ?? 0,
      ),
      nightTime: TimeOfDay(
        hour: prefs.getInt('notif_night_h') ?? 21,
        minute: prefs.getInt('notif_night_m') ?? 0,
      ),
    );
  }

  static Future<void> scheduleDailyNotifications({
    required bool enabled,
    required TimeOfDay morningTime,
    required TimeOfDay eveningTime,
    required TimeOfDay nightTime,
  }) async {
    if (kIsWeb) return;
    debugPrint('NotificationService: scheduleDailyNotifications: enabled=$enabled, morning=$morningTime, evening=$eveningTime, night=$nightTime');
    try {
      await _plugin.cancelAll();
      if (!enabled) {
        debugPrint('NotificationService: Notifications are disabled, cancelled all scheduled notifications');
        return;
      }

      await _scheduleDailyAt(
        id: 1001,
        title: 'Good Morning ☀️',
        body: "Track today's expenses & crush your budget!",
        time: morningTime,
        contentTitle: '<b>Fresh Start!</b>',
        summaryText: 'Set your daily budget goal and stay on track.',
      );
      await _scheduleDailyAt(
        id: 1002,
        title: 'Evening Reminder 💰',
        body: 'Logging your afternoon coffee or lunch now saves time later!',
        time: eveningTime,
        contentTitle: '<b>Mid-day Check-in</b>',
        summaryText: 'Keep your spending history accurate and complete.',
      );
      await _scheduleDailyAt(
        id: 1003,
        title: 'Daily Expense Check 🌙',
        body: 'One last check! Did you log all expenses today?',
        time: nightTime,
        contentTitle: '<b>Day Complete!</b>',
        summaryText: 'Sweet dreams! Your financial tracker is fully updated.',
      );
      debugPrint('NotificationService: scheduleDailyNotifications completed successfully');
    } catch (e, stack) {
      debugPrint('NotificationService: ERROR in scheduleDailyNotifications: $e\n$stack');
    }
  }

  static Future<void> _scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String contentTitle,
    required String summaryText,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    debugPrint('NotificationService: Scheduling daily at: $scheduled (id=$id)');

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            color: const Color(0xFF6366F1), // Indigo brand color tint
            styleInformation: BigPictureStyleInformation(
              const DrawableResourceAndroidBitmap('reminder_banner'),
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              contentTitle: contentTitle,
              summaryText: summaryText,
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            ),
            actions: [
              const AndroidNotificationAction(
                actionAdd,
                'Add Expense ➕',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                actionDismiss,
                'Later ⏰',
                cancelNotification: true,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: actionAdd,
      );
      debugPrint('NotificationService: Successfully scheduled daily notification id=$id at $scheduled');
    } catch (e, s) {
      debugPrint('NotificationService: ERROR scheduling daily at id $id: $e\n$s');
      rethrow;
    }
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb || !_initialized) {
      debugPrint('NotificationService: Cannot show test notification (kIsWeb=$kIsWeb, _initialized=$_initialized)');
      return;
    }
    debugPrint('NotificationService: Showing test notification');

    try {
      await _plugin.show(
        0,
        'Test Reminder 💰',
        'This is how your rich notifications will look!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.max,
            color: const Color(0xFF6366F1), // Indigo brand color tint
            styleInformation: const BigPictureStyleInformation(
              DrawableResourceAndroidBitmap('reminder_banner'),
              largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              contentTitle: '<b>Stunning Rich View!</b>',
              summaryText: 'Vibrant banners, crisp stencil icons, and smart actions are active.',
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            ),
            actions: [
              const AndroidNotificationAction(
                actionAdd,
                'Add Expense ➕',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                actionDismiss,
                'Later ⏰',
                cancelNotification: true,
              ),
            ],
          ),
        ),
        payload: actionAdd,
      );
      debugPrint('NotificationService: Successfully showed test notification');
    } catch (e, s) {
      debugPrint('NotificationService: ERROR showing test notification: $e\n$s');
    }
  }

  static Future<void> cancelAll() async {
    if (!kIsWeb) await _plugin.cancelAll();
  }
}
