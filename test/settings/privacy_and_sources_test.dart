import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/core/storage/user_database.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/settings/settings_screen.dart';

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
            strings: const AppStrings(AppLanguage.arabic),
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
          find.text('التزام مطلق بحماية بياناتك بدون خوادم أو تتبع (100% أوفلاين)'),
          findsOneWidget,
        );
        expect(
          find.text('عمل محلي تام دون إنترنت (100% Offline-First)'),
          findsOneWidget,
        );
        expect(
          find.text('عدم جمع أي بيانات شخصية (Zero Data Collection)'),
          findsOneWidget,
        );

        // Close the modal sheet
        final closeButton = find.byIcon(Icons.close_rounded);
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Verify sheet is closed
        expect(
          find.text('التزام مطلق بحماية بياناتك بدون خوادم أو تتبع (100% أوفلاين)'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'SettingsScreen Sources card displays comprehensive Arabic attribution',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: const AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to the Sources card
        for (int i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
        }

        final sourcesFinder = find.textContaining('مشروع تنزيل (Tanzil Project');

        // Verify Sources card text includes Tanzil, Quranpedia, Books/Malazem, Ahlulbayt, and Tasbeeh
        expect(sourcesFinder, findsOneWidget);
        expect(find.textContaining('الموسوعة القرآنية (Quranpedia.net'), findsOneWidget);
        expect(find.textContaining('ملازم هدي القرآن الكريم'), findsOneWidget);
        expect(find.textContaining('الصحيفة السجادية، رسالة الحقوق، نهج البلاغة'), findsOneWidget);
        expect(find.textContaining('باقة الاستغفار والتسبيح'), findsOneWidget);
      },
    );

    testWidgets(
      'SettingsScreen Sources card displays comprehensive English attribution in English locale',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.english,
            strings: const AppStrings(AppLanguage.english),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to the Sources card
        for (int i = 0; i < 4; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();
        }

        expect(find.text('Sources & Documentation:'), findsOneWidget);

        final sourcesFinder = find.textContaining('Holy Quran Text: Tanzil Project');
        expect(sourcesFinder, findsOneWidget);
        expect(find.textContaining('Quran Vocabulary Lexicon: Quranic Encyclopedia'), findsOneWidget);
        expect(find.textContaining('Lessons from the Guidance of the Holy Quran'), findsOneWidget);
        expect(find.textContaining('Supplications, Adhkar & Tasbeeh: 88 Quranic duas'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Open Source Licenses'), findsOneWidget);
      },
    );
  });
}
