import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/settings/settings_screen.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Privacy Policy & Sources Tests', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_privacy_test_');
      testFile = File('${tempDir.path}/test_settings_privacy.json');
      await UserDataStore.instance.init(testFile);
      await QuranRepository.instance.init();
    });

    tearDown(() async {
      await UserDatabase.instance.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'SettingsScreen renders Privacy Policy tile and opens Privacy Policy bottom sheet',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down multiple times to reach the bottom
        for (int i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
        }

        // Privacy Policy button in About section
        final privacyTileFinder = find.text('سياسة الخصوصية');
        expect(privacyTileFinder, findsWidgets);

        // Tap the Privacy Policy button
        await tester.tap(privacyTileFinder.first);
        await tester.pumpAndSettle();

        // Verify Privacy Policy bottom sheet opened
        expect(find.text('ميثاق الخصوصية والأمان'), findsOneWidget);
        expect(
          find.text('التزام بحماية بياناتك دون خوادم أو تتبع'),
          findsOneWidget,
        );
        expect(find.text('يعمل دون إنترنت'), findsOneWidget);
        expect(find.text('عدم جمع أي بيانات شخصية'), findsOneWidget);

        // Close the modal sheet
        final closeButton = find.byIcon(AppIcons.x);
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Verify sheet is closed
        expect(
          find.text('التزام بحماية بياناتك دون خوادم أو تتبع'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'SettingsScreen Sources tile opens About & Sources bottom sheet with comprehensive Arabic attribution',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to the About section
        for (int i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
        }

        final aboutTileFinder = find.text('عن تَدبِير والمصادر المعتمدة');
        expect(aboutTileFinder, findsOneWidget);

        // Tap the tile to open the bottom sheet
        await tester.tap(aboutTileFinder);
        await tester.pumpAndSettle();

        final sourcesFinder = find.textContaining(
          'مشروع تنزيل (Tanzil Project',
        );

        // Verify Sources sheet text includes Tanzil, Malazem, Tasbeeh and the full list
        expect(sourcesFinder, findsOneWidget);
        expect(find.textContaining('ملازم هدي القرآن الكريم'), findsOneWidget);
        expect(find.textContaining('THIRD_PARTY_NOTICES.md'), findsOneWidget);
        expect(find.textContaining('باقة الاستغفار والتسبيح'), findsOneWidget);
      },
    );

    testWidgets(
      'SettingsScreen Sources tile opens About & Sources bottom sheet in English locale',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.english,
            strings: AppStrings(AppLanguage.english),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to the About section
        for (int i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
        }

        final aboutTileFinder = find.text('About Tadbeer & Sources');
        expect(aboutTileFinder, findsOneWidget);

        await tester.tap(aboutTileFinder);
        await tester.pumpAndSettle();

        expect(find.text('Sources & Documentation:'), findsOneWidget);

        final sourcesFinder = find.textContaining(
          'Holy Quran Text: Tanzil Project',
        );
        expect(sourcesFinder, findsOneWidget);
        expect(
          find.textContaining('Lessons from the Guidance of the Holy Quran'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Supplications, Adhkar & Tasbeeh: 91 Quranic duas',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Open Source Licenses is hidden from SettingsScreen and accessible at the bottom of About & Sources sheet',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll to the bottom of SettingsScreen and confirm the tile is absent
        for (int i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
        }
        expect(find.text('تراخيص المصادر المفتوحة'), findsNothing);

        // Open About & Sources sheet
        await tester.tap(find.text('عن تَدبِير والمصادر المعتمدة'));
        await tester.pumpAndSettle();

        // Scroll down inside the sheet to reach the subtle licenses button
        final sheetListFinder = find.byType(ListView).last;
        final licensesButton = find.text('تراخيص المصادر المفتوحة');
        await tester.scrollUntilVisible(
          licensesButton,
          300,
          scrollable: find.descendant(
            of: sheetListFinder,
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();

        expect(licensesButton, findsOneWidget);

        // Tap it and verify LicensePage opens
        await tester.tap(licensesButton);
        await tester.pumpAndSettle();

        expect(find.byType(LicensePage), findsOneWidget);
      },
    );
  });
}
