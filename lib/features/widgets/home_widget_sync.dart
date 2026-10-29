/// بيانات ودجت الشاشة الرئيسية: آية كل ربع ساعة وتقدم الختمة.
///
/// الودجت يعمل خارج التطبيق، فيُعطى ما يحتاجه مسبقاً: آية لكل ربع ساعة من الأرباع [quarters] القادمة مرسومة بالخط القرآني (ويختار الحالية بنفسه من الساعة)، وحالة الختمة، والثيم.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/localization.dart';
import '../../data/storage/user_data_store.dart';
import '../daily/ayah_of_day_card.dart';
import '../../data/models/reading_journey.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import 'widget_ayah_image.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../../data/models/user_settings_model.dart';

class HomeWidgetSync {
  HomeWidgetSync._();

  static const androidName = 'TadbeerWidgetProvider';
  static const iOSName = 'TadbeerWidget';
  static const appGroupId = 'group.com.tadbeer.app';

  /// الأرباع المخزنة مسبقاً: يومان. بعدها يدور الودجت على الآيات المخزنة حتى يُفتح التطبيق.
  static const quarters = 2 * 96;

  static String? _lastKey;

  /// رقم ربع الساعة الذي يقع فيه [time]، محسوباً من 2020-01-01 بالتوقيت المحلي؛ الكود الأصلي للودجت يحسب بنفس الطريقة.
  static int quarterOf(DateTime time) {
    final days = DateTime.utc(
      time.year,
      time.month,
      time.day,
    ).difference(DateTime.utc(2020)).inDays;
    return days * 96 + time.hour * 4 + time.minute ~/ 15;
  }

  /// الآية المعروضة في الربع [quarter]؛ خطوة أولية كبيرة توزّع الأرباع المتتالية على المصحف.
  static Ayah ayahForQuarter(int quarter) {
    final pool = AyahOfTheDay.pool;
    return pool[(quarter * 7919) % pool.length];
  }

  /// كل ما يعرضه الودجت، بالمفاتيح التي يقرؤها الكود الأصلي.
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
      // يحسب الودجت صفحات اليوم المتبقية من هذه القيم، فتبقى صحيحة بعد منتصف الليل.
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

  /// يرسل البيانات إلى الودجت إن تغيّرت منذ آخر مرة.
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
      // لا دعم للودجت على هذه المنصة (اختبارات أو سطح مكتب).
      debugPrint('Home widget update skipped: $e');
    }
  }

  /// يُرفع حين يتغيّر شكل الآية المرسومة، فتُعاد رسم كل الصور.
  static const _imageStyle = 4;
  static bool _rendering = false;

  /// مفتاح صورة الآية؛ الودجت يقرأ نفس المفتاح.
  static String imageKey(Ayah ayah) =>
      'img_${ayah.surahNumber}_${ayah.ayahNumber}';

  /// يرسم كل آية من الأرباع المخزنة بالخط القرآني، مرة لكل آية، ويحذف الصور التي لم تعد لازمة.
  static Future<void> _renderAyahImages(DateTime now, String language) async {
    if (_rendering) return;
    _rendering = true;
    try {
      // خط المصحف المختار؛ تغييره يعيد رسم كل الصور.
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
        // إن لم تُحمّل خطوط الصفحة، تُرسم الآية بخط النص المتدفق بدل ألا تُرسم.
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
        // تُعرض الأولى فور وجودها.
        if (++drew == 2) {
          await HomeWidget.updateWidget(
            androidName: androidName,
            iOSName: iOSName,
          );
        }
      }
      for (final old in previous.difference(wanted.keys.toSet())) {
        // حذف المفتاح يحذف ملف الصورة أيضاً.
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

  /// يُبقي الودجت محدّثاً أثناء عمل التطبيق. التغييرات تأتي متتابعة (تقليب صفحة يحفظ الموضع ويعدّ الصفحة)، فيُحدّث مرة بعد أن تهدأ لا مع كل تغيير.
  static void attach() {
    UserDataStore.instance.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1500), update);
    });
    update();
  }
}
