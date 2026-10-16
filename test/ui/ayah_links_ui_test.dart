import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/core/utils/arabic_search_normalizer.dart';
import 'package:tadbeer/features/ayah_links/ayah_link_model.dart';
import 'package:tadbeer/features/ayah_links/ayah_link_repository.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/ayah_links/ayah_link_detail_screen.dart';
import 'package:tadbeer/features/ayah_links/ayah_links_screen.dart';
import 'package:tadbeer/features/ayah_links/views/ayah_link_network_view.dart';
import 'package:tadbeer/features/ayah_links/views/ayah_link_ordered_view.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'tadbeer_ayah_links_ui_test_',
    );
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
    await UserDataStore.instance.updateSettings(
      UserDataStore.instance.settings.copyWith(
        hideTadabburIntroPermanently: true,
      ),
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Ayah Links UI & Flow Tests', () {
    testWidgets(
      'AyahLinksScreen renders, creates a link and navigates to detail',
      (WidgetTester tester) async {
        await tester.pumpWidget(const TadbeerApp());
        await tester.pumpAndSettle();

        // Open Ayah Links from Home Dashboard
        final linksFinder = find.text('روابط الآيات');
        expect(linksFinder, findsWidgets);
        await tester.ensureVisible(linksFinder.first);
        await tester.tap(linksFinder.first);
        await tester.pumpAndSettle();

        expect(find.byType(AyahLinksScreen), findsOneWidget);
        expect(find.text('لا توجد روابط آيات بعد'), findsOneWidget);

        // Tap create link FAB
        final createFab = find.byType(FloatingActionButton);
        expect(createFab, findsOneWidget);
        await tester.tap(createFab);
        await tester.pumpAndSettle();

        // Enter Title
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'الصبر عند الشدة');
        await tester.pumpAndSettle();

        // Submit
        final submitButton = find.text('إنشاء');
        expect(submitButton, findsOneWidget);
        await tester.runAsync(() async {
          await tester.tap(submitButton);
          await Future.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        // Should navigate to AyahLinkDetailScreen
        expect(find.byType(AyahLinkDetailScreen), findsOneWidget);
        expect(find.text('الصبر عند الشدة'), findsWidgets);
      },
    );

    Widget buildTestApp(Widget child) {
      return AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      'Detail Screen switches smoothly between Network and Ordered views (Cards view removed)',
      (WidgetTester tester) async {
        late AyahLinkItem link;
        await tester.runAsync(() async {
          final repo = AyahLinkRepository();
          link = await repo.createLink(
            title: 'الاستعانة بالصبر',
            description: 'وصف التجربة',
          );
          await repo.addVerseToLink(
            link.id,
            ayahId: 160,
            surahNumber: 2,
            ayahNumber: 153,
            page: 23,
          );
        });

        await tester.pumpWidget(
          buildTestApp(AyahLinkDetailScreen(linkId: link.id)),
        );
        await tester.pumpAndSettle();

        // Starts in Network View
        expect(find.byType(AyahLinkNetworkView), findsOneWidget);
        expect(
          find.byType(AyahLinkOrderedView, skipOffstage: false),
          findsOneWidget,
        );

        // Cards tab should NOT exist
        expect(find.text('بطاقات'), findsNothing);

        // Switch to Ordered view
        final orderedTab = find.text('مرتب');
        expect(orderedTab, findsOneWidget);
        await tester.runAsync(() async {
          await tester.tap(orderedTab);
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(find.byType(AyahLinkOrderedView), findsOneWidget);

        // Verify verse content is visible in Ordered view
        final verseFinder = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              ArabicSearchNormalizer.normalize(w.data ?? '')
                  .contains('استعينوا بالصبر'),
        );
        expect(verseFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Open in Quran from Ayah Link opens correct page and surah in QuranScreen',
      (WidgetTester tester) async {
        late AyahLinkItem link;
        await tester.runAsync(() async {
          final repo = AyahLinkRepository();
          link = await repo.createLink(title: 'الانتقال للمصحف');
          await repo.addVerseToLink(
            link.id,
            ayahId: 160,
            surahNumber: 2,
            ayahNumber: 153,
            page: 23,
          );
        });

        await tester.pumpWidget(
          buildTestApp(AyahLinkDetailScreen(linkId: link.id)),
        );
        await tester.pumpAndSettle();

        // Switch to Ordered view
        await tester.runAsync(() async {
          await tester.tap(find.text('مرتب'));
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // Tap verse text box in Ordered view
        final verseTextFinder = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              ArabicSearchNormalizer.normalize(w.data ?? '')
                  .contains('استعينوا بالصبر'),
        );
        expect(verseTextFinder, findsOneWidget);
        await tester.runAsync(() async {
          await tester.tap(verseTextFinder);
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // QuranScreen should open on page 23
        expect(find.byType(QuranScreen), findsOneWidget);
        expect(find.textContaining('٢٣'), findsWidgets);
      },
    );

    testWidgets(
      'Network view displays simplified bottom controls: Add Ayah and Center button only, no zoom/dpad',
      (WidgetTester tester) async {
        late AyahLinkItem link;
        await tester.runAsync(() async {
          final repo = AyahLinkRepository();
          link = await repo.createLink(
            title: 'اختبار التحكم بالشبكة',
            description: 'تجربة زر التمركز وزر إضافة آية',
          );
        });

        await tester.pumpWidget(
          buildTestApp(AyahLinkDetailScreen(linkId: link.id)),
        );
        await tester.pumpAndSettle();

        // 1. Zoom controls and D-Pad arrows must NOT exist
        expect(find.byTooltip('تكبير'), findsNothing);
        expect(find.byTooltip('تصغير'), findsNothing);
        expect(find.byTooltip('أعلى'), findsNothing);
        expect(find.byTooltip('أسفل'), findsNothing);
        expect(find.byTooltip('يمين'), findsNothing);
        expect(find.byTooltip('يسار'), findsNothing);

        // 2. Exactly the two required buttons exist: Add Verse and Center
        expect(
          find.widgetWithText(FloatingActionButton, 'إضافة آية'),
          findsOneWidget,
        );
        final centerButton = find.byTooltip('العودة إلى الوسط');
        expect(centerButton, findsOneWidget);
        expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);

        // 3. Tapping Center button triggers centerView smoothly without error
        await tester.tap(centerButton);
        await tester.pumpAndSettle();

        // 4. Switching to Ordered view hides the Center button, Add Verse remains
        await tester.runAsync(() async {
          await tester.tap(find.text('مرتب'));
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        expect(find.byTooltip('العودة إلى الوسط'), findsNothing);
        expect(
          find.widgetWithText(FloatingActionButton, 'إضافة آية'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Network view displays full long ayah without truncation and scrolls smoothly in bottom sheet',
      (WidgetTester tester) async {
        late AyahLinkItem link;
        await tester.runAsync(() async {
          final repo = AyahLinkRepository();
          link = await repo.createLink(
            title: 'آية الكرسي ورابط التوحيد',
            description: 'فحص عرض الآية الطويلة بالكامل',
          );
          // Add Ayat al-Kursi (Surah 2, Ayah 255)
          final ayahObj = QuranRepository.instance.getAyah(2, 255);
          await repo.addVerseToLink(
            link.id,
            ayahId: ayahObj?.id ?? 255,
            surahNumber: 2,
            ayahNumber: 255,
            page: 42,
            note: 'ملاحظة تدبر تفصيلية لآية الكرسي العظيمة وفضائلها',
          );
        });

        await tester.pumpWidget(
          buildTestApp(AyahLinkDetailScreen(linkId: link.id)),
        );
        await tester.pumpAndSettle();

        // 1. Ayah text in canvas should be present without maxLines
        final ayah = QuranRepository.instance.getAyah(2, 255);
        expect(ayah, isNotNull);
        final ayahFinder = find.text('﴿ ${ayah!.text} ﴾');
        expect(ayahFinder, findsWidgets);

        // 2. Tap on the verse node to open the bottom sheet
        await tester.tap(ayahFinder.first);
        await tester.pumpAndSettle();

        // 3. Verify bottom sheet has header, scrollable content, and action buttons
        expect(find.textContaining('سورة البقرة'), findsWidgets);
        expect(find.text('فتح في المصحف'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsWidgets);
      },
    );
  });
}

