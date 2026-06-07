import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettings {
  final bool enabled;
  final TimeOfDay morningTime;
  final TimeOfDay eveningTime;
  final TimeOfDay nightTime;

  const NotificationSettings({
    this.enabled = true,
    this.morningTime = const TimeOfDay(hour: 9, minute: 0),
    this.eveningTime = const TimeOfDay(hour: 17, minute: 0),
    this.nightTime = const TimeOfDay(hour: 21, minute: 0),
  });

  NotificationSettings copyWith({
    bool? enabled,
    TimeOfDay? morningTime,
    TimeOfDay? eveningTime,
    TimeOfDay? nightTime,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      morningTime: morningTime ?? this.morningTime,
      eveningTime: eveningTime ?? this.eveningTime,
      nightTime: nightTime ?? this.nightTime,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationSettings> {
  NotificationNotifier() : super(const NotificationSettings()) {
    _load();
  }

  static const _kEnabled = 'notif_enabled';
  static const _kMorningH = 'notif_morning_h';
  static const _kMorningM = 'notif_morning_m';
  static const _kEveningH = 'notif_evening_h';
  static const _kEveningM = 'notif_evening_m';
  static const _kNightH = 'notif_night_h';
  static const _kNightM = 'notif_night_m';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled: prefs.getBool(_kEnabled) ?? true,
      morningTime: TimeOfDay(
        hour: prefs.getInt(_kMorningH) ?? 9,
        minute: prefs.getInt(_kMorningM) ?? 0,
      ),
      eveningTime: TimeOfDay(
        hour: prefs.getInt(_kEveningH) ?? 17,
        minute: prefs.getInt(_kEveningM) ?? 0,
      ),
      nightTime: TimeOfDay(
        hour: prefs.getInt(_kNightH) ?? 21,
        minute: prefs.getInt(_kNightM) ?? 0,
      ),
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, state.enabled);
    await prefs.setInt(_kMorningH, state.morningTime.hour);
    await prefs.setInt(_kMorningM, state.morningTime.minute);
    await prefs.setInt(_kEveningH, state.eveningTime.hour);
    await prefs.setInt(_kEveningM, state.eveningTime.minute);
    await prefs.setInt(_kNightH, state.nightTime.hour);
    await prefs.setInt(_kNightM, state.nightTime.minute);
  }

  Future<void> _apply() async {
    await NotificationService.scheduleDailyNotifications(
      enabled: state.enabled,
      morningTime: state.morningTime,
      eveningTime: state.eveningTime,
      nightTime: state.nightTime,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _save();
    if (value) {
      // Re-request permissions in case they were revoked since last launch.
      await NotificationService.requestPermissions();
    }
    await _apply();
  }

  Future<void> updateTime(String slot, TimeOfDay time) async {
    switch (slot) {
      case 'morning':
        state = state.copyWith(morningTime: time);
      case 'evening':
        state = state.copyWith(eveningTime: time);
      case 'night':
        state = state.copyWith(nightTime: time);
    }
    await _save();
    await _apply();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationSettings>(
  (ref) => NotificationNotifier(),
);
