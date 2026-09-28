import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'pdf_service.dart';

/// AlarmManager-based scheduler that can run even if the app is closed on Android.
/// Call [initialize] once on app start. When the user taps "Download PPT Overnight",
/// call [scheduleOvernightDownload]. It re-schedules itself daily.
class SchedulerService {
  SchedulerService._internal();
  static final SchedulerService instance = SchedulerService._internal();

  static const String _prefsKeyHour = 'overnight_pdf_hour_24h';
  static const String _prefsEnabled = 'overnight_pdf_enabled';
  static const String _prefsUrl = 'overnight_pdf_url';
  static const String _prefsTitle = 'overnight_pdf_title';

  /// Demo PDF already used elsewhere in the app.
  static const String _demoPdfUrl =
      'https://basponccollege.org/LMS/EMaterial/Science/Comp/HVP/JS%20Notes.pdf';
  static const String _demoPdfTitle = 'JS_Notes_Demo';

  /// Must be called once in main() before runApp.
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    // Re-register the alarm if previously enabled
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsEnabled) ?? false;
    if (enabled) {
      final hour = prefs.getInt(_prefsKeyHour) ?? 23;
      await _registerForHour(hour);
    }
  }

  /// Schedule nightly download at [hour24] (0..23). Shows effect even if app is closed.
  Future<void> scheduleOvernightDownload({int hour24 = 23, String? url, String? title}) async {
    assert(hour24 >= 0 && hour24 <= 23);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, true);
    await prefs.setInt(_prefsKeyHour, hour24);
    await prefs.setString(_prefsUrl, url ?? _demoPdfUrl);
    await prefs.setString(_prefsTitle, title ?? _demoPdfTitle);
    await _registerForHour(hour24);
  }

  /// Cancel background download scheduling.
  Future<void> cancel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, false);
    await AndroidAlarmManager.cancel(424242);
  }

  DateTime _nextOccurrence(int hour24) {
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, now.day, hour24);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> _registerForHour(int hour24) async {
    final when = _nextOccurrence(hour24);
    if (kDebugMode) {
      debugPrint('[SchedulerService] Scheduling alarm at $when');
    }
    await AndroidAlarmManager.oneShotAt(
      when,
      424242,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }
}

/// Alarm callback; schedules the next day and performs download.
@pragma('vm:entry-point')
Future<void> _alarmCallback() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(SchedulerService._prefsEnabled) ?? false;
    if (!enabled) return;
    final url = prefs.getString(SchedulerService._prefsUrl) ?? SchedulerService._demoPdfUrl;
    final title = prefs.getString(SchedulerService._prefsTitle) ?? SchedulerService._demoPdfTitle;
    final hour = prefs.getInt(SchedulerService._prefsKeyHour) ?? 23;

    final service = PdfService();
    await service.downloadAndSavePdf(url: url, title: title);

    // Re-schedule for next day
    final next = SchedulerService.instance._nextOccurrence(hour);
    await AndroidAlarmManager.oneShotAt(
      next,
      424242,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[SchedulerService] Alarm error: $e');
    }
  }
}


