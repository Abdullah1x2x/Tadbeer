/// بيانات ودجت الشاشة الرئيسية: آية اليوم وتقدم الختمة.
///
/// The widget runs outside the app, so it is given what it needs ahead of
/// time: the ayah for each of the next [days] days (it picks today's itself,
/// changing daily even when the app is not opened) and the khatma's state.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/localization.dart';
import '../../core/storage/user_data_store.dart';
import '../daily/ayah_of_day_card.dart';
import '../journey/reading_journey.dart';
import '../quran/data/quran_repository.dart';

class HomeWidgetSync {
  HomeWidgetSync._();

  static const androidName = 'TadbeerWidgetProvider';
  static const iOSName = 'TadbeerWidget';
  static const appGroupId = 'group.com.tadbeer.app';

  /// Days of ayahs stored ahead.
  static const days = 30;

  static String? _lastKey;

  /// Everything the widget shows, keyed as the native code reads it.
  @visibleForTesting
  static Map<String, Object> payload(UserDataStore store, DateTime now) {
    final strings = AppStrings(
      AppLanguage.fromCode(store.settings.languageCode),
    );
    final repo = QuranRepository.instance;
    final ayahs = [
      for (var d = 0; d < days; d++)
        () {
          final day = DateTime(now.year, now.month, now.day + d);
          final ayah = AyahOfTheDay.forDay(day);
          return {
            'd': dayKey(day),
            't': ayah.text,
            'r': strings.ayahReference(
              repo.getSurah(ayah.surahNumber).name,
              ayah.ayahNumber,
            ),
          };
        }(),
    ];
    final journey = store.journey;
    final plan = journey.plan;
    return {
      'title': strings.ayahOfTheDay,
      'ayahs': jsonEncode(ayahs),
      'has_khatma': plan != null && !plan.isComplete,
      'khatma_title': strings.myJourney,
      'khatma_progress': plan == null ? 0 : (plan.progress * 100).round(),
      // Today's pages left are worked out by the widget from these, so
      // they stay right after midnight.
      'portion': plan?.pagesPerDay ?? 0,
      'read_day': dayKey(now),
      'read_today': journey.pagesOn(now),
      'portion_template': strings.widgetPortionLeftTemplate,
      'portion_done': strings.widgetPortionDone,
    };
  }

  /// Sends the data to the widget when it changed since the last time.
  static Future<void> update({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final data = payload(UserDataStore.instance, at);
    final key = jsonEncode(data);
    if (key == _lastKey) return;
    _lastKey = key;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      for (final entry in data.entries) {
        await HomeWidget.saveWidgetData(entry.key, entry.value);
      }
      await HomeWidget.updateWidget(androidName: androidName, iOSName: iOSName);
    } catch (e) {
      // No widget support on this platform (tests, desktop).
      debugPrint('Home widget update skipped: $e');
    }
  }

  /// Keeps the widget current while the app runs.
  static void attach() {
    UserDataStore.instance.addListener(update);
    update();
  }
}
