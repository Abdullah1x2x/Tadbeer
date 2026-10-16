import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/core/utils/arabic_root_search_helper.dart';
import 'package:tadbeer/core/utils/arabic_search_normalizer.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/search/built_in_search_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_root_search_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ArabicRootSearchHelper & Morphological Search Tests', () {
    test('Prefix detection recognizes root search syntax', () {
      expect(ArabicRootSearchHelper.isRootQuery('جذر:صبر'), isTrue);
      expect(ArabicRootSearchHelper.isRootQuery('جذر: صبر'), isTrue);
      expect(ArabicRootSearchHelper.isRootQuery('جذر صبر'), isTrue);
      expect(ArabicRootSearchHelper.isRootQuery('root:sbr'), isTrue);
      expect(ArabicRootSearchHelper.isRootQuery('#جذر علم'), isTrue);

      expect(ArabicRootSearchHelper.isRootQuery('صبر'), isFalse);
      expect(ArabicRootSearchHelper.isRootQuery('الرحمن الرحيم'), isFalse);
      expect(ArabicRootSearchHelper.isRootQuery(''), isFalse);
    });

    test('extractRoot cleans prefix and normalizes Arabic text', () {
      expect(ArabicRootSearchHelper.extractRoot('جذر:صبر'), equals('صبر'));
      expect(ArabicRootSearchHelper.extractRoot('جذر: رَحْم'), equals('رحم'));
      expect(ArabicRootSearchHelper.extractRoot('جذر:  عِلْم '), equals('علم'));
      expect(ArabicRootSearchHelper.extractRoot('root:كتب'), equals('كتب'));
    });

    test('getRootForms returns rich morphological derivations', () {
      final sabrForms = ArabicRootSearchHelper.getRootForms('صبر');
      expect(sabrForms, contains('صبر'));
      expect(sabrForms, contains('صابر'));
      expect(sabrForms, contains('اصبر'));
      expect(sabrForms, contains('الصابرين'));

      final rahmForms = ArabicRootSearchHelper.getRootForms('رحم');
      expect(rahmForms, contains('رحم'));
      expect(rahmForms, contains('رحمه'));
      expect(rahmForms, contains('الرحمن'));
      expect(rahmForms, contains('الرحيم'));

      // Arbitrary 3-letter root rule-based expansion
      final arbitraryForms = ArabicRootSearchHelper.getRootForms('فرح');
      expect(arbitraryForms, contains('فرح'));
      expect(arbitraryForms, contains('فارح'));
      expect(arbitraryForms, contains('يفرح'));
    });

    test('QuranRepository.searchAyahsByRoot finds authentic matching verses', () {
      final repo = QuranRepository.instance;
      final results = repo.searchAyahsByRoot('صبر', limit: 30);
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(5));

      // Verifies that returned verses actually contain one of the root variations
      final forms = ArabicRootSearchHelper.getRootForms('صبر');
      final firstMatch = results.first;
      final normalizedAyah = ArabicSearchNormalizer.normalize(firstMatch.text);
      final containsForm = forms.any((f) => normalizedAyah.contains(f));
      expect(containsForm, isTrue);
    });

    test('QuranRepository.searchAyahs seamlessly delegates root queries', () {
      final repo = QuranRepository.instance;
      final directResults = repo.searchAyahsByRoot('رحم', limit: 20);
      final queryResults = repo.searchAyahs('جذر:رحم', limit: 20);

      expect(queryResults.length, equals(directResults.length));
      expect(queryResults.first.id, equals(directResults.first.id));
    });

    testWidgets('QuranSearchProvider returns root-badged items for root queries', (tester) async {
      await tester.pumpWidget(
        AppLocalizationScope(
          currentLanguage: AppLanguage.arabic,
          strings: const AppStrings(AppLanguage.arabic),
          onLanguageChanged: (_) {},
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox.shrink(),
          ),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      const provider = QuranSearchProvider();

      final results = await provider.search('جذر:صبر', context);
      expect(results, isNotEmpty);
      expect(results.first.badge, contains('جذر: صبر'));
      expect(results.first.sectionTitle, contains('جذر: صبر'));
    });
  });
}
