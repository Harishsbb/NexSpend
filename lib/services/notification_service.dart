import 'dart:io';
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

  static bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> initialize() async {
    if (_initialized || !_isSupported) return;
    debugPrint('NotificationService: Initializing NotificationService...');

    tz.initializeTimeZones();
    try {
      debugPrint('NotificationService: Fetching local timezone...');
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 3));
      String id;
      if (tzInfo is String) {
        id = tzInfo;
      } else {
        try {
          id = (tzInfo as dynamic).identifier.toString();
        } catch (_) {
          id = tzInfo.toString();
        }
      }
      tz.setLocalLocation(tz.getLocation(id));
      debugPrint('NotificationService: Local timezone set to $id');
    } catch (e) {
      debugPrint('NotificationService: Error getting timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    try {
      debugPrint('NotificationService: Initializing local notifications plugin...');
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('NotificationService: onDidReceiveNotificationResponse: ${details.payload} / ${details.actionId}');
          if (details.payload == actionAdd || details.actionId == actionAdd) {
            // Handle notification tap / action
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
    if (!_isSupported) return;
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
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      debugPrint('NotificationService: requesting iOS permission...');
      final iosGranted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('NotificationService: iOS permission granted: $iosGranted');
    } catch (e, s) {
      debugPrint('NotificationService: ERROR requesting permissions: $e\n$s');
    }
  }

  /// Re-reads saved prefs and reschedules notifications. Call at every app startup.
  static Future<void> scheduleFromPrefs() async {
    if (!_isSupported) return;
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
    if (!_isSupported) return;
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
      );
      await _scheduleDailyAt(
        id: 1002,
        title: 'Evening Reminder 💰',
        body: 'Logging your afternoon coffee or lunch now saves time later!',
        time: eveningTime,
      );
      await _scheduleDailyAt(
        id: 1003,
        title: 'Daily Expense Check 🌙',
        body: 'One last check! Did you log all expenses today?',
        time: nightTime,
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
  }) async {
    final localNow = DateTime.now();
    var scheduledLocal = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      time.hour,
      time.minute,
    );
    if (scheduledLocal.isBefore(localNow)) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 1));
    }
    final scheduled = tz.TZDateTime.from(scheduledLocal, tz.local);
    debugPrint('NotificationService: Scheduling daily at: $scheduled (id=$id)');

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
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
    if (!_isSupported || !_initialized) {
      debugPrint('NotificationService: Cannot show test notification (supported=$_isSupported, initialized=$_initialized)');
      return;
    }
    debugPrint('NotificationService: Showing test notification');

    try {
      await _plugin.show(
        0,
        'Test Reminder 💰',
        'This is how your notifications will look!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
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
    if (_isSupported) await _plugin.cancelAll();
  }
}
