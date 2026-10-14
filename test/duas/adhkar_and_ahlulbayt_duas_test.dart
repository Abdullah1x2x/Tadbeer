import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/features/duas/adhkar_repository.dart';
import 'package:tadbeer/features/duas/ahlulbayt_dua_reader_screen.dart';
import 'package:tadbeer/features/duas/ahlulbayt_duas_repository.dart';
import 'package:tadbeer/features/duas/ahlulbayt_duas_screen.dart';
import 'package:tadbeer/features/duas/duas_screen.dart';
import 'package:tadbeer/features/duas/general_duas_list_screen.dart';
import 'package:tadbeer/features/duas/morning_evening_adhkar_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

Widget buildTestWidget(Widget child) {
  return AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: const AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await QuranRepository.instance.init();
  });

  group('Adhkar Repository & MorningEveningAdhkarScreen Tests', () {
    test('AdhkarRepository contains authentic morning and evening adhkar', () {
      final morning = AdhkarRepository.morningAdhkar;
      final evening = AdhkarRepository.eveningAdhkar;

      expect(morning.length, greaterThanOrEqualTo(10));
      expect(evening.length, greaterThanOrEqualTo(10));

      // Check Sayyidah Fatimah Al-Zahra's supplication
      final zahraDhikr = morning.firstWhere((d) => d.id == 'm_zahra_dua');
      expect(zahraDhikr.text, contains('يَا حَيُّ يَا قَيُّومُ، بِرَحْمَتِكَ أَسْتَغِيثُ'));
      expect(zahraDhikr.text, contains('لَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ'));
    });

    testWidgets('MorningEveningAdhkarScreen renders and switches tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(const MorningEveningAdhkarScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('أذكار الصباح والمساء'), findsOneWidget);
      expect(find.textContaining('أذكار الصباح'), findsWidgets);
      expect(find.textContaining('أذكار المساء'), findsWidgets);

      // Verify first morning dhikr is present
      expect(find.textContaining('اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ'), findsOneWidget);

      // Tap on evening adhkar tab
      final eveningTab = find.textContaining('أذكار المساء').first;
      await tester.tap(eveningTab);
      await tester.pumpAndSettle();

      // Check evening dhikr (Ayat Al-Kursi or Amsayna)
      expect(find.textContaining('أُجير من الشياطين حتى يصبح'), findsOneWidget);
    });

    testWidgets('MorningEveningAdhkarScreen taps counter and copies dhikr', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(const MorningEveningAdhkarScreen()),
      );
      await tester.pumpAndSettle();

      // Tap copy button on the first card
      final copyButtons = find.byTooltip('نسخ نص الذكر');
      expect(copyButtons, findsWidgets);
      await tester.tap(copyButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('تم نسخ نص الذكر الشريف بنجاح'), findsOneWidget);

      // Tap counter on single-time dhikr
      final singleCountBtn = find.text('مرة واحدة').first;
      await tester.tap(singleCountBtn);
      await tester.pumpAndSettle();

      expect(find.text('اكتمل'), findsWidgets);

      // Tap reset all counts
      final resetBtn = find.byTooltip('إعادة ضبط العدادات');
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('تمت إعادة ضبط عدادات الأذكار'), findsOneWidget);
    });
  });

  group('Ahlulbayt Duas Repository & Screen Tests', () {
    test('AhlulbaytDuasRepository contains all user requested duas', () {
      final repo = AhlulbaytDuasRepository.instance;
      final allDuas = repo.getAllDuas();

      expect(allDuas.length, greaterThanOrEqualTo(10));

      final titles = allDuas.map((d) => d.title).toList();

      // 1. دعاء مكارم الأخلاق
      expect(titles, anyElement(contains('مكارم الأخلاق')));
      final makarim = allDuas.firstWhere((d) => d.title.contains('مكارم الأخلاق'));
      expect(makarim.attributedTo, contains('زين العابدين'));
      expect(makarim.fullText, contains('بَلِّغْ بِإِيمَانِي أَكْمَلَ الإِيمَانِ'));

      // 2. دعاء أهل الثغور
      expect(titles, anyElement(contains('الثغور')));
      final thughoor = allDuas.firstWhere((d) => d.title.contains('الثغور'));
      expect(thughoor.fullText, contains('حَصِّنْ ثُغُورَ الْمُسْلِمِينَ بِعِزَّتِكَ'));

      // 3. دعاء كميل بن زياد
      expect(titles, anyElement(contains('كميل')));
      final kumayl = allDuas.firstWhere((d) => d.title.contains('كميل'));
      expect(kumayl.fullText, contains('اللَّهُمَّ إِنِّي أَسْأَلُكَ بِرَحْمَتِكَ الَّتِي وَسِعَتْ كُلَّ شَيْءٍ'));

      // 4. دعاء الندبة
      expect(titles, anyElement(contains('الندبة')));
      final nudba = allDuas.firstWhere((d) => d.title.contains('الندبة'));
      expect(nudba.fullText, contains('أَيْنَ بَقِيَّةُ اللَّهِ'));

      // 5. دعاء التوسل
      expect(titles, anyElement(contains('التوسل')));
      final tawassul = allDuas.firstWhere((d) => d.title.contains('التوسل'));
      expect(tawassul.fullText, contains('يَا وَجِيهاً عِنْدَ اللَّهِ اشْفَعْ لَنَا عِنْدَ اللَّهِ'));

      // 6. دعاء الإمام الحسين (يوم عرفة)
      expect(titles, anyElement(contains('عرفة')));
      final arafah = allDuas.firstWhere((d) => d.title.contains('عرفة'));
      expect(arafah.fullText, contains('مَاذَا وَجَدَ مَنْ فَقَدَكَ'));

      // 7. دعاء الجوشن الكبير
      expect(titles, anyElement(contains('الجوشن الكبير')));
      final jawshan = allDuas.firstWhere((d) => d.title.contains('الجوشن الكبير'));
      expect(jawshan.fullText, contains('سُبْحَانَكَ يَا لا إِلَهَ إِلا أَنْتَ، الْغَوْثَ الْغَوْثَ'));

      // 8. دعاء الإمام الصادق لقضاء الحوائج
      expect(titles, anyElement(contains('الصادق')));
      final sadiq = allDuas.firstWhere((d) => d.title.contains('الصادق'));
      expect(sadiq.fullText, contains('اللّهُمَّ اجْعَلْني أخْشاكَ كأني أراكَ'));
      expect(sadiq.fullText, contains('وَأسْعِدْني بِتَقْواكَ'));

      // 9. دعاء السيدة فاطمة الزهراء (عليها السلام)
      expect(titles, anyElement(contains('الزهراء')));
      final zahra = allDuas.firstWhere((d) => d.title.contains('الزهراء'));
      expect(zahra.fullText, contains('يَا حَيُّ يَا قَيُّومُ، بِرَحْمَتِكَ أَسْتَغِيثُ'));

      // 10. أدعية إضافية
      expect(titles, anyElement(contains('الفرج')));
      expect(titles, anyElement(contains('الصباح')));
      expect(titles, anyElement(contains('العهد')));
      expect(titles, anyElement(contains('المناجاة الشعبانية')));
      expect(titles, anyElement(contains('يستشير')));
    });

    testWidgets('AhlulbaytDuasScreen renders list, searches and filters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const AhlulbaytDuasScreen()));
      await tester.pumpAndSettle();

      expect(find.text('أدعية أهل البيت عليهم السلام'), findsOneWidget);
      expect(find.textContaining('دعاء كميل بن زياد'), findsOneWidget);
      expect(find.textContaining('دعاء مكارم الأخلاق'), findsOneWidget);

      // Search for 'كميل'
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'كميل');
      await tester.pumpAndSettle();

      expect(find.textContaining('دعاء كميل بن زياد'), findsOneWidget);
      expect(find.textContaining('دعاء مكارم الأخلاق'), findsNothing);

      // Clear search
      final clearBtn = find.byIcon(Icons.clear_rounded);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('دعاء مكارم الأخلاق'), findsOneWidget);
    });

    testWidgets('AhlulbaytDuaReaderScreen renders paragraphs and handles font size', (
      WidgetTester tester,
    ) async {
      final dua = AhlulbaytDuasRepository.instance.getDuaById('dua_kumayl')!;
      await tester.pumpWidget(buildTestWidget(AhlulbaytDuaReaderScreen(dua: dua)));
      await tester.pumpAndSettle();

      expect(find.text('دعاء كميل بن زياد'), findsWidgets);
      expect(find.textContaining('اللَّهُمَّ إِنِّي أَسْأَلُكَ بِرَحْمَتِكَ'), findsOneWidget);

      // Font size increase
      final increaseBtn = find.byTooltip('تكبير الخط');
      expect(increaseBtn, findsOneWidget);
      await tester.tap(increaseBtn);
      await tester.pumpAndSettle();

      // Copy all text
      final copyAllBtn = find.byTooltip('نسخ الدعاء كاملاً');
      await tester.tap(copyAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('تم نسخ نص الدعاء كاملاً إلى الحافظة'), findsOneWidget);
    });
  });

  group('DuasScreen Hub Flow Integration Tests', () {
    testWidgets('DuasScreen navigates to all sub-sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const DuasScreen()));
      await tester.pumpAndSettle();

      // 1. Open Morning & Evening Adhkar
      final adhkarCard = find.text('أذكار الصباح والمساء');
      expect(adhkarCard, findsOneWidget);
      await tester.tap(adhkarCard);
      await tester.pumpAndSettle();

      expect(find.byType(MorningEveningAdhkarScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 2. Open Ahlulbayt Duas
      final ahlulbaytCard = find.text('أدعية مأثورة عن أهل البيت');
      expect(ahlulbaytCard, findsOneWidget);
      await tester.tap(ahlulbaytCard);
      await tester.pumpAndSettle();

      expect(find.byType(AhlulbaytDuasScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Open Prophetic Duas (أدعية من السنة النبوية)
      final sunnahCard = find.text('أدعية من السنة النبوية');
      expect(sunnahCard, findsOneWidget);
      await tester.ensureVisible(sunnahCard);
      await tester.pumpAndSettle();
      await tester.tap(sunnahCard);
      await tester.pumpAndSettle();

      expect(find.byType(GeneralDuasListScreen), findsOneWidget);
      expect(find.text('دعاء تفريج الهم والحزن'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 4. Open Comprehensive Duas (جوامع الدعاء والرجاء)
      final jawamiCard = find.text('جوامع الدعاء والرجاء');
      expect(jawamiCard, findsOneWidget);
      await tester.ensureVisible(jawamiCard);
      await tester.pumpAndSettle();
      await tester.tap(jawamiCard);
      await tester.pumpAndSettle();

      expect(find.byType(GeneralDuasListScreen), findsOneWidget);
      expect(find.text('دعاء جوامع الخير كله'), findsOneWidget);
    });
  });
}
