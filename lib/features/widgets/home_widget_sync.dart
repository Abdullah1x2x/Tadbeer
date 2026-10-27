/// بيانات ودجت الشاشة الرئيسية: آية كل ربع ساعة وتقدم الختمة.
///
/// The widget runs outside the app, so it is given what it needs ahead of
/// time: an ayah for every quarter hour of the next [quarters] quarters
/// (it picks the current one itself, from the clock) with each ayah drawn
/// in the Quranic font, the khatma's state and the colour theme.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/localization.dart';
import '../../core/storage/user_data_store.dart';
import '../daily/ayah_of_day_card.dart';
import '../journey/reading_journey.dart';
import '../quran/data/quran_models.dart';
import '../quran/data/quran_repository.dart';
import 'widget_ayah_image.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../settings/user_settings_model.dart';

class HomeWidgetSync {
  HomeWidgetSync._();

  static const androidName = 'TadbeerWidgetProvider';
  static const iOSName = 'TadbeerWidget';
  static const appGroupId = 'group.com.tadbeer.app';

  /// Quarter hours stored ahead: two days. Past them the widget cycles
  /// through the stored ayahs until the app is opened again.
  static const quarters = 2 * 96;

  static String? _lastKey;

  /// Number of the quarter hour [time] falls in, counted from 2020-01-01 in
  /// local time. The widget's native code counts the same way.
  static int quarterOf(DateTime time) {
    final days = DateTime.utc(
      time.year,
      time.month,
      time.day,
    ).difference(DateTime.utc(2020)).inDays;
    return days * 96 + time.hour * 4 + time.minute ~/ 15;
  }

  /// The ayah shown during quarter [quarter]; a large prime stride spreads
  /// consecutive quarters across the Mushaf.
  static Ayah ayahForQuarter(int quarter) {
    final pool = AyahOfTheDay.pool;
    return pool[(quarter * 7919) % pool.length];
  }

  /// Everything the widget shows, keyed as the native code reads it.
  @visibleForTesting
  static Map<String, Object> payload(UserDataStore store, DateTime now) {
    final strings = AppStrings(
      AppLanguage.fromCode(store.settings.languageCode),
    );
    final repo = QuranRepository.instance;
    final first = quarterOf(now);
    final ayahs = [
      for (var q = first; q < first + quarters; q++)
        () {
          final ayah = ayahForQuarter(q);
          return {
            'q': q,
            's': ayah.surahNumber,
            'a': ayah.ayahNumber,
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
      'title': strings.widgetAyahTitle,
      'ayahs': jsonEncode(ayahs),
      'theme': store.settings.colorTheme.name,
      'has_khatma': plan != null && !plan.isComplete,
      'khatma_title': strings.myJourney,
      'khatma_progress': plan == null ? 0 : (plan.progress * 100).round(),
      // Today's pages left are worked out by the widget from these, so
      // they stay right after midnight.
      'portion': plan?.pagesPerDay ?? 0,
      'read_day': dayKey(now),
      'read_today': journey.portionPagesOn(now),
      'portion_template': strings.widgetPortionLeftTemplate,
      'portion_done': strings.widgetPortionDone,
      'khatma_page': plan == null ? '' : strings.pageNumber(plan.currentPage),
      'reflect_label': strings.reflectOnIt,
      'read_label': store.readingNotStarted
          ? strings.khatmaStartNow
          : strings.resumeReading,
    };
  }

  /// Sends the data to the widget when it changed since the last time.
  static Future<void> update({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final store = UserDataStore.instance;
    final data = payload(store, at);
    final key = jsonEncode(data);
    if (key == _lastKey) return;
    _lastKey = key;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      for (final entry in data.entries) {
        await HomeWidget.saveWidgetData(entry.key, entry.value);
      }
      await HomeWidget.updateWidget(androidName: androidName, iOSName: iOSName);
      unawaited(_renderAyahImages(at, store.settings.languageCode));
    } catch (e) {
      // No widget support on this platform (tests, desktop).
      debugPrint('Home widget update skipped: $e');
    }
  }

  /// Bump when the drawn ayah's look changes, so every image is redrawn.
  static const _imageStyle = 4;
  static bool _rendering = false;

  /// Image key of an ayah; the widget reads the same key.
  static String imageKey(Ayah ayah) =>
      'img_${ayah.surahNumber}_${ayah.ayahNumber}';

  /// Draws each ayah of the stored quarters in the Quranic font, once per
  /// ayah, and deletes the images no longer needed.
  static Future<void> _renderAyahImages(DateTime now, String language) async {
    if (_rendering) return;
    _rendering = true;
    try {
      // The selected Mushaf's font: a change of it redraws every image.
      final settings = UserDataStore.instance.settings;
      final madinah = settings.mushafStyle == MushafStyle.madinah;
      final font = UserDataStore.instance.quranFontFamily;
      final stamp = '$_imageStyle-$language-${madinah ? 'madinah' : font}';
      final sameStyle =
          await HomeWidget.getWidgetData<String>('img_stamp') == stamp;
      final previous =
          (await HomeWidget.getWidgetData<String>('img_keys') ?? '')
              .split(',')
              .where((k) => k.isNotEmpty)
              .toSet();
      final first = quarterOf(now);
      final wanted = <String, Ayah>{
        for (var q = first; q < first + quarters; q++)
          imageKey(ayahForQuarter(q)): ayahForQuarter(q),
      };
      var drew = 0;
      for (final MapEntry(key: key, value: ayah) in wanted.entries) {
        if (sameStyle && previous.contains(key)) continue;
        // Without its glyphs (a font that failed to load) the ayah is
        // drawn in the flowing text's font rather than not at all.
        final glyphs = madinah && await QcfGlyphs.prepare(ayah)
            ? QcfGlyphs.of(ayah)
            : null;
        await HomeWidget.renderFlutterWidget(
          WidgetAyahImage(ayah: ayah, glyphs: glyphs, font: font),
          key: key,
          logicalSize: WidgetAyahImage.sizeFor(
            ayah,
            glyphs: glyphs,
            font: font,
          ),
          pixelRatio: 2.5,
        );
        // Show the first ones as soon as they exist.
        if (++drew == 2) {
          await HomeWidget.updateWidget(
            androidName: androidName,
            iOSName: iOSName,
          );
        }
      }
      for (final old in previous.difference(wanted.keys.toSet())) {
        // Removing the key also deletes the image file.
        await HomeWidget.saveWidgetData<String>(old, null);
      }
      await HomeWidget.saveWidgetData('img_keys', wanted.keys.join(','));
      await HomeWidget.saveWidgetData('img_stamp', stamp);
      if (drew > 0) {
        await HomeWidget.updateWidget(
          androidName: androidName,
          iOSName: iOSName,
        );
      }
    } catch (e) {
      debugPrint('Home widget ayah images skipped: $e');
    } finally {
      _rendering = false;
    }
  }

  static Timer? _debounce;

  /// Keeps the widget current while the app runs. Changes come in bursts
  /// (a page turn saves the position and counts the page), so the widget
  /// is refreshed once things settle rather than on every change.
  static void attach() {
    UserDataStore.instance.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1500), update);
    });
    update();
  }
}
