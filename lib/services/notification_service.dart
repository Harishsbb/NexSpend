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
  // Dedicated flag avoids relying on tz.local != tz.UTC object-identity comparison,
  // which can break after tz.initializeTimeZones() replaces the UTC Location object.
  static bool _timezoneInitialized = false;

  static const _channelId = 'expense_reminders';
  static const _channelName = 'Expense Reminders';
  static const _channelDesc = 'Daily reminders to log your expenses';

  static const actionAdd = 'ACTION_ADD_EXPENSE';
  static const actionDismiss = 'ACTION_DISMISS';

  static bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> initialize() async {
    if (_initialized || !_isSupported) return;
    debugPrint('NotificationService: Initializing...');

    tz.initializeTimeZones();
    await _ensureTimezoneInitialized();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: android, iOS: ios);

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('NotificationService: response: ${details.payload} / ${details.actionId}');
        },
      );
      debugPrint('NotificationService: plugin initialized');
    } catch (e, s) {
      debugPrint('NotificationService: plugin init failed: $e\n$s');
      rethrow;
    }

    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    if (!_isSupported) return;
    if (!_initialized) await initialize();

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      debugPrint('NotificationService: requesting POST_NOTIFICATIONS...');
      final granted = await androidImpl?.requestNotificationsPermission();
      debugPrint('NotificationService: POST_NOTIFICATIONS granted: $granted');

      debugPrint('NotificationService: requesting SCHEDULE_EXACT_ALARM...');
      final exactGranted = await androidImpl?.requestExactAlarmsPermission();
      debugPrint('NotificationService: SCHEDULE_EXACT_ALARM granted: $exactGranted');

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
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
    // Ensure plugin is ready before trying to schedule.
    if (!_initialized) await initialize();

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
    debugPrint('NotificationService: scheduleDailyNotifications: enabled=$enabled');

    try {
      await _plugin.cancelAll();
      if (!enabled) {
        debugPrint('NotificationService: notifications disabled — all cancelled');
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
      debugPrint('NotificationService: all 3 reminders scheduled');
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
    await _ensureTimezoneInitialized();

    // Bug fix: construct TZDateTime directly in tz.local instead of converting
    // from a plain DateTime via TZDateTime.from(). The from() conversion interprets
    // the DateTime's UTC epoch value, which silently schedules at the wrong wall-clock
    // time when tz.local differs from the device system timezone.
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    debugPrint('NotificationService: scheduling id=$id at $scheduled');

    const details = NotificationDetails(
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
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: actionAdd,
      );
      debugPrint('NotificationService: scheduled id=$id (exact)');
    } catch (e) {
      // SCHEDULE_EXACT_ALARM not granted — fall back to inexact.
      // Inexact alarms may be delayed on battery-optimized devices, but still fire.
      debugPrint('NotificationService: exact failed for id=$id ($e), falling back to inexact...');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: actionAdd,
        );
        debugPrint('NotificationService: scheduled id=$id (inexact fallback)');
      } catch (ex, sx) {
        debugPrint('NotificationService: ERROR — both exact and inexact failed for id=$id: $ex\n$sx');
        rethrow;
      }
    }
  }

  static Future<void> _ensureTimezoneInitialized() async {
    // Bug fix: use a dedicated flag instead of `tz.local != tz.UTC`.
    // After tz.initializeTimeZones(), the tz.UTC object reference may change,
    // making the identity comparison unreliable and causing early return before
    // the local timezone is set, leaving tz.local stuck at UTC.
    if (_timezoneInitialized) return;

    try {
      debugPrint('NotificationService: resolving local timezone...');
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 4));

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

      tz.Location localLocation;
      try {
        localLocation = tz.getLocation(id);
      } catch (_) {
        // Timezone ID not in database — fall back to offset match.
        final offset = DateTime.now().timeZoneOffset;
        localLocation = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) {
            final zone = loc.timeZone(DateTime.now().millisecondsSinceEpoch);
            return zone.offset == offset.inMilliseconds;
          },
          orElse: () => tz.UTC,
        );
        debugPrint('NotificationService: "$id" not found, fell back to ${localLocation.name} by offset');
      }

      tz.setLocalLocation(localLocation);
      _timezoneInitialized = true;
      debugPrint('NotificationService: timezone set to ${localLocation.name}');
    } catch (e) {
      debugPrint('NotificationService: timezone lookup failed ($e), trying offset match...');
      try {
        final offset = DateTime.now().timeZoneOffset;
        final localLocation = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) {
            final zone = loc.timeZone(DateTime.now().millisecondsSinceEpoch);
            return zone.offset == offset.inMilliseconds;
          },
          orElse: () => tz.UTC,
        );
        tz.setLocalLocation(localLocation);
        _timezoneInitialized = true;
        debugPrint('NotificationService: timezone set to ${localLocation.name} via offset match');
      } catch (ex) {
        debugPrint('NotificationService: offset match also failed ($ex) — remaining at UTC');
        // Mark as initialized anyway so we don't retry on every schedule call.
        _timezoneInitialized = true;
      }
    }
  }

  static Future<void> showTestNotification() async {
    if (!_isSupported || !_initialized) {
      debugPrint('NotificationService: cannot show test (supported=$_isSupported, initialized=$_initialized)');
      return;
    }
    debugPrint('NotificationService: showing test notification');
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
    } catch (e, s) {
      debugPrint('NotificationService: ERROR showing test notification: $e\n$s');
    }
  }

  static Future<void> cancelAll() async {
    if (_isSupported) await _plugin.cancelAll();
  }
}
