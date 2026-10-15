import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/duas/duas_screen.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:tadbeer/features/duas/quran_dua_card.dart';
import 'package:tadbeer/features/duas/quran_duas_screen.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_duas_ui_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestWidget(Widget child) {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }

  group('DuasScreen Hub & QuranDuasScreen Flow Tests', () {
    testWidgets(
      'DuasScreen Hub renders sections and contains "أدعية من القرآن"',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const DuasScreen()));
        await tester.pumpAndSettle();

        // Title: "الأدعية"
        expect(find.text('الأدعية'), findsOneWidget);

        // Prominent sub-section card: "أدعية من القرآن"
        expect(find.text('أدعية من القرآن'), findsOneWidget);
        expect(find.text('٨٨ دعاء'), findsOneWidget);

        // Other sections remain present
        expect(find.text('أدعية من السنة النبوية'), findsOneWidget);
        expect(find.text('أذكار الصباح والمساء'), findsOneWidget);
        expect(find.text('جوامع الدعاء والرجاء'), findsOneWidget);
      },
    );

    testWidgets(
      'All non-Quran section cards have identical size',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const DuasScreen()));
        await tester.pumpAndSettle();

        final cardTitles = [
          'أذكار الصباح والمساء',
          'أدعية مأثورة عن أهل البيت',
          'أدعية من السنة النبوية',
          'جوامع الدعاء والرجاء',
        ];

        final heights = <double>[];
        for (final title in cardTitles) {
          final inkWell = find.ancestor(
            of: find.text(title),
            matching: find.byType(InkWell),
          );
          expect(inkWell, findsOneWidget);
          heights.add(tester.getSize(inkWell).height);
        }

        // All 4 cards must have the exact same height
        expect(heights.toSet().length, 1);
      },
    );

    testWidgets(
      'Tapping "أدعية من القرآن" in DuasScreen opens QuranDuasScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const DuasScreen()));
        await tester.pumpAndSettle();

        // Tap on "أدعية من القرآن" card
        final quranDuasCard = find.text('أدعية من القرآن');
        await tester.tap(quranDuasCard);
        await tester.pumpAndSettle();

        // Opens QuranDuasScreen
        expect(find.byType(QuranDuasScreen), findsOneWidget);
        expect(find.byType(QuranDuaCard), findsWidgets);
      },
    );

    testWidgets(
      'QuranDuasScreen renders appbar, search field, count badge and cards',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const QuranDuasScreen()));
        await tester.pumpAndSettle();

        // Title: "أدعية من القرآن"
        expect(find.text('أدعية من القرآن'), findsOneWidget);

        // Search input field
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('ابحث في أدعية القرآن الكريم...'), findsOneWidget);

        // Count badge (88 duas)
        expect(find.text('٨٨ دعاء'), findsOneWidget);

        // Cards should be rendered
        expect(find.byType(QuranDuaCard), findsWidgets);

        // First dua is from Al-Fatihah
        expect(find.textContaining('سورة الفاتحة'), findsWidgets);
      },
    );

    testWidgets(
      'Search filters Duas and updates count badge in QuranDuasScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const QuranDuasScreen()));
        await tester.pumpAndSettle();

        // Search for Yunus's prayer
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'لا اله الا انت');
        await tester.pumpAndSettle();

        // Badge should show 1 dua
        expect(find.text('١ دعاء'), findsOneWidget);
        expect(find.textContaining('الأنبياء'), findsOneWidget);

        // Clear search
        final clearButton = find.byIcon(Icons.clear);
        expect(clearButton, findsOneWidget);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Should restore 88
        expect(find.text('٨٨ دعاء'), findsOneWidget);
      },
    );

    testWidgets('Empty search shows empty state message in QuranDuasScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const QuranDuasScreen()));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'نص غير موجود في القرآن إطلاقا');
      await tester.pumpAndSettle();

      expect(find.text('٠ دعاء'), findsOneWidget);
      expect(find.text('لا توجد أدعية مطابقة لبحثك'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('Tapping "عرض الآية" navigates to QuranScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const QuranDuasScreen()));
      await tester.pumpAndSettle();

      // Find first "عرض الآية" button
      final viewAyahFinder = find.text('عرض الآية').first;
      expect(viewAyahFinder, findsOneWidget);

      await tester.tap(viewAyahFinder);
      await tester.pumpAndSettle();

      // Should push QuranScreen
      expect(find.byType(QuranScreen), findsOneWidget);
    });

    testWidgets('HomeScreen "الأدعية" tile opens DuasScreen Hub', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Find "الأدعية" card
      final duasCard = find.text('الأدعية');
      expect(duasCard, findsWidgets);
      expect(find.byIcon(FlutterIslamicIcons.prayer), findsWidgets);

      await tester.tap(duasCard.first);
      await tester.pumpAndSettle();

      // Should open DuasScreen (Hub)
      expect(find.byType(DuasScreen), findsOneWidget);
      expect(find.text('الأدعية'), findsOneWidget);
      expect(find.text('أدعية من القرآن'), findsOneWidget);
    });

    testWidgets(
      'Multi-Ayah QuranDuaCard renders authentic Ayah end rosettes and numbers',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const QuranDuasScreen()));
        await tester.pumpAndSettle();

        // First card is Al-Fatihah (5-7), which is a multi-ayah card
        expect(find.textContaining('سورة الفاتحة'), findsWidgets);
        expect(find.text('الآيات ٥–٧'), findsOneWidget);

        // Verify that rosettes with authentic numbers ٥, ٦, ٧ appear
        expect(find.textContaining('﴿٥﴾'), findsOneWidget);
        expect(find.textContaining('﴿٦﴾'), findsOneWidget);
        expect(find.textContaining('﴿٧﴾'), findsOneWidget);

        // Verify verse texts are rendered
        expect(
          find.textContaining('إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ'),
          findsOneWidget,
        );
        expect(
          find.textContaining('اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ'),
          findsOneWidget,
        );
        expect(
          find.textContaining('صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Single-Ayah QuranDuaCard does NOT inject internal Ayah markers',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const QuranDuasScreen()));
        await tester.pumpAndSettle();

        // Filter for Al-Baqarah 201 (Single Ayah)
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'خير الدنيا والآخرة');
        await tester.pumpAndSettle();

        expect(find.text('١ دعاء'), findsOneWidget);
        expect(find.text('الآية ٢٠١'), findsOneWidget);

        // Single ayah should NOT contain internal rosette ﴿٢٠١﴾ inside the text
        expect(find.textContaining('﴿٢٠١﴾'), findsNothing);

        // But should have the outer brackets
        expect(
          find.textContaining(
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Copying Dua works smoothly with SnackBar confirmation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const QuranDuasScreen()));
      await tester.pumpAndSettle();

      // Find first "نسخ" button
      final copyButton = find.text('نسخ').first;
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump();

      // SnackBar should be displayed
      expect(find.text('تم نسخ نص الدعاء بنجاح'), findsOneWidget);
    });
  });
}
