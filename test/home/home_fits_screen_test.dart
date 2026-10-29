import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/continue/last_activity.dart';
import 'package:tadbeer/features/daily/ayah_of_day_card.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/journey/journey_screen.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

/// The Home page fits the screen without scrolling, and its Mushaf card
/// opens the Mushaf or the reading journey depending on where it is tapped.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    // The ayah card measures its verses in the Quran fonts.
    final amiri = FontLoader('Amiri')
      ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    final scheherazade = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'));
    await Future.wait([plex.load(), amiri.load(), scheherazade.load()]);
    // With the Madinah Mushaf (the default) the card writes the day's
    // ayahs in its glyphs; they load here, outside any test's clock.
    await QuranRepository.instance.init();
    for (final ayah in AyahOfTheDay.forDayAll(DateTime.now())) {
      await QcfGlyphs.prepare(ayah);
    }
  });

  /// Opens the store, with a commitment from two days ago when [busy], so
  /// the commitment card shows on Home.
  Future<void> openStore({bool busy = false}) async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_home_fits_');
    final file = File('${tempDir.path}/data.json');
    if (busy) {
      final at = DateTime.now().subtract(const Duration(days: 2));
      file.writeAsStringSync(
        jsonEncode({
          'tadbeer': [
            {
              'id': 't1',
              'surahNumber': 2,
              'ayahNumber': 255,
              'answers': {
                '1': 'الحي القيوم',
                '3':
                    'أقرأ آية الكرسي بعد كل صلاة، وأتذكر أن الله لا تأخذه '
                    'سنة ولا نوم، فأطمئن في كل أمر يقلقني مهما كان',
              },
              'createdAt': at.toIso8601String(),
              'updatedAt': at.toIso8601String(),
              'commitmentAt': at.toIso8601String(),
            },
          ],
        }),
      );
    }
    await UserDataStore.instance.init(file);
    await QuranRepository.instance.init();
    if (busy) {
      await LastActivityStore.record(
        ActivityKind.adhkar,
        ref: 'morning',
        title: 'morning',
      );
    }
  }

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  /// Checks that no ayah of the day is cut short on the Home card, in the
  /// flowing font or the Madinah glyphs: no text on the card is cut.
  void expectVerseWhole(WidgetTester tester) {
    final texts = find.descendant(
      of: find.byType(AyahOfTheDayCard),
      matching: find.byType(RichText),
    );
    expect(texts, findsWidgets);
    for (final paragraph in tester.renderObjectList<RenderParagraph>(texts)) {
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  }

  /// How far the Home page can scroll; 0 when it fits the screen.
  double extent(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .maxScrollExtent;

  // Heights are the space Home gets above the app's floating bar.
  const screens = {
    'small phone': Size(360, 540),
    'compact phone': Size(360, 700),
    'phone': Size(393, 770),
    'large phone': Size(412, 830),
    'tablet': Size(800, 1180),
  };

  for (final busy in [false, true]) {
    for (final entry in screens.entries) {
      testWidgets('Home fits a ${entry.key} without scrolling'
          '${busy ? ', with a commitment and an activity' : ''}', (
        tester,
      ) async {
        await tester.runAsync(() => openStore(busy: busy));
        await pumpHome(tester, entry.value);
        expect(tester.takeException(), isNull);

        // With a commitment and an activity both showing, a shorter phone
        // scrolls a little rather than cut the day's longest ayah.
        if (!busy || entry.value.height >= 830) {
          expect(extent(tester), 0, reason: 'the page does not scroll');
        }

        // Every part is on screen, the last one included.
        if (extent(tester) == 0) {
          for (final text in [
            'المصحف',
            'وقفاتي',
            'روابط الآيات',
            'كتب وملازم',
          ]) {
            final rect = tester.getRect(find.text(text));
            expect(rect.bottom, lessThanOrEqualTo(entry.value.height));
          }
        }
        if (busy) {
          expect(find.text('أكمل من حيث توقفت · الأذكار'), findsOneWidget);
          expect(find.textContaining('أقرأ آية الكرسي'), findsOneWidget);
        }
        // The ayah card keeps room for its verse and actions, in one row.
        final card = tester.getSize(find.byType(AyahOfTheDayCard));
        expect(card.height, greaterThanOrEqualTo(170));
        expect(find.text('تدبّرها'), findsOneWidget);
        final wrap = find.descendant(
          of: find.byType(AyahOfTheDayCard),
          matching: find.byType(Wrap),
        );
        expect(tester.getSize(wrap).height, lessThan(60));
      });
    }
  }

  testWidgets('a very short screen scrolls rather than crush the cards', (
    tester,
  ) async {
    await tester.runAsync(() => openStore(busy: true));
    await pumpHome(tester, const Size(360, 520));
    expect(tester.takeException(), isNull);
    expect(extent(tester), greaterThan(0));
    expectVerseWhole(tester);
  });

  testWidgets('the card writes the ayah in the Madinah glyphs', (tester) async {
    await tester.runAsync(() => openStore());
    await pumpHome(tester, const Size(393, 770));
    final first = AyahOfTheDay.forDayAll(DateTime.now()).first;
    expect(find.text(QcfGlyphs.of(first)!.text), findsOneWidget);
    expect(extent(tester), 0);
    expectVerseWhole(tester);
  });

  testWidgets('the Mushaf part of the card opens the Mushaf', (tester) async {
    await tester.runAsync(() => openStore());
    await pumpHome(tester, const Size(393, 770));
    await tester.tap(find.textContaining('سورة الفاتحة'));
    await tester.pumpAndSettle();
    expect(find.byType(QuranScreen), findsOneWidget);
    expect(find.byType(JourneyScreen), findsNothing);
  });

  testWidgets('the journey line of the card opens my journey', (tester) async {
    await tester.runAsync(() => openStore());
    await pumpHome(tester, const Size(393, 770));
    await tester.tap(find.textContaining('رحلتي مع القرآن'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyScreen), findsOneWidget);
    expect(find.byType(QuranScreen), findsNothing);
  });
}
