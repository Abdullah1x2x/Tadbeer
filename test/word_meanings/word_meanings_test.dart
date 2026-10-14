import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_models.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/quran/widgets/word_meanings_panel.dart';
import 'package:tadbeer/features/word_meanings/data/custom_word_meanings.dart';
import 'package:tadbeer/features/word_meanings/word_meanings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_word_meanings_test_');
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

  group('Word Meanings Dataset & Integrity Tests (1 to 4, 11, 12)', () {
    test('1. قراءة البيانات المعتمدة: assets/quran/word_meanings.json is valid and populated with lexicon data', () {
      final file = File('assets/quran/word_meanings.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final list = jsonDecode(content) as List<dynamic>;
      expect(list.length, equals(6465));

      // Assert that every entry is strictly a single Quranic word without compound spaces
      for (final item in list) {
        final w = (item as Map<String, dynamic>)['word'] as String;
        expect(w.trim().split(' ').length, equals(1), reason: 'Word "$w" must be a single word');
      }

      final first = list.first as Map<String, dynamic>;
      expect(first['surah'], isNotNull);
      expect(first['ayah'], isNotNull);
      expect(first['word'], isNotEmpty);
      expect(first['meaning'], isNotEmpty);
      final firstModel = QuranWordMeaning.fromJson(first);
      expect(firstModel.sourceName, contains('المعجم الوسيط'));
      expect(firstModel.sourceUrl, equals('https://www.arabicacademy.gov.eg/ar/'));

      // Check specific user-requested verified examples
      final abb = list.firstWhere((e) => e['word'] == 'أَبًّا' || e['word'] == 'أَبّ');
      expect(abb['meaning'], equals('الكلأ والمرعى'));

      final deez = list.firstWhere((e) => (e['word'] as String).contains('ضِيزَى'));
      expect(deez['meaning'], equals('جائرة، غير عادلة'));

      final sarmad = list.firstWhere((e) => (e['word'] as String).contains('سَرْمَدًا'));
      expect(sarmad['meaning'], equals('دائمًا لا ينقطع'));
    });

    test('2. خلوّ الأصول من ملفات المراجعة المستبعدة: word_meanings_excluded.json is not bundled in assets', () {
      final file = File('assets/quran/word_meanings_excluded.json');
      expect(file.existsSync(), isFalse);
    });

    test('3. صحة أرقام السور والآيات: all approved entries map to valid Ayahs and Pages', () {
      final repo = QuranRepository.instance;
      for (final item in repo.allWordMeanings) {
        expect(item.surah, inInclusiveRange(1, 114));
        expect(item.ayah, greaterThan(0));
        expect(item.page, inInclusiveRange(1, 604));

        final ayah = repo.getAyah(item.surah, item.ayah);
        expect(ayah, isNotNull);
        expect(ayah!.page, equals(item.page));
      }
    });

    test('4. عدم فقدان مصادر المداخل: approved entries preserve their source attribution', () {
      final repo = QuranRepository.instance;
      for (final item in repo.allWordMeanings) {
        expect(item.sourceName, contains('المعجم الوسيط'));
        expect(item.sourceUrl, equals('https://www.arabicacademy.gov.eg/ar/'));
      }
    });

    test('11. إمكانية إعادة اعتماد مدخل مستبعد بعد توثيقه المعجمي: safe re-admission into approved list', () {
      final reviewSample = {
        'surah': 80,
        'ayah': 31,
        'word': 'أَبًّا',
        'meaning': 'الكلأ والمرعى',
        'source_name': 'المعجم الوسيط، مجمع اللغة العربية بالقاهرة',
        'source_url': 'https://www.arabicacademy.gov.eg/ar/',
        'status': 'approved',
      };

      final word = QuranWordMeaning.fromJson(reviewSample, page: 585);
      expect(word.surah, equals(80));
      expect(word.ayah, equals(31));
      expect(word.word, equals('أَبًّا'));
      expect(word.meaning, equals('الكلأ والمرعى'));
      expect(word.status, equals('approved'));
      expect(word.page, equals(585));
    });

    test('12. التعامل مع البيانات الناقصة أو المكررة بصورة آمنة: robust fromJson fallbacks', () {
      final minimalJson = {
        'surah': 53,
        'ayah': 22,
        'word': 'ضِيزَى',
        'meaning': 'جائرة، غير عادلة',
      };

      final word = QuranWordMeaning.fromJson(minimalJson, page: 527);
      expect(word.sourceName, contains('المعجم الوسيط'));
      expect(word.sourceUrl, equals('https://www.arabicacademy.gov.eg/ar/'));
      expect(word.status, equals('approved'));
      expect(word.page, equals(527));
      expect(word.ayahKey, equals('53:22'));
    });
  });

  group('Repository Queries & Filters (5, 6, 8)', () {
    test('5. البحث عن الكلمات: search finds words by text and meaning with diacritics flexibility', () {
      final repo = QuranRepository.instance;
      // Search with diacritics
      final res1 = repo.searchWordMeanings('ضِيزَى');
      expect(res1, isNotEmpty);

      // Search without diacritics
      final res2 = repo.searchWordMeanings('ضيزى');
      expect(res2, isNotEmpty);
      expect(res1.first.word, equals(res2.first.word));

      // Search by meaning snippet
      final resMeaning = repo.searchWordMeanings('المرعى');
      expect(resMeaning, isNotEmpty);
      expect(resMeaning.any((w) => w.meaning.contains('المرعى')), isTrue);

      // Search by distinctive meaning snippet
      final resSarmad = repo.searchWordMeanings('دائمًا لا ينقطع');
      expect(resSarmad, isNotEmpty);
      expect(resSarmad.first.meaning, contains('دائمًا لا ينقطع'));
    });

    test('6. التصفية حسب السورة: filter by surah number returns only words of that surah', () {
      final repo = QuranRepository.instance;
      final fatihahWords = repo.getWordMeaningsForSurah(1);
      expect(fatihahWords, isNotEmpty);
      for (final w in fatihahWords) {
        expect(w.surah, equals(1));
      }

      final abasaWords = repo.getWordMeaningsForSurah(80);
      expect(abasaWords, isNotEmpty);
      for (final w in abasaWords) {
        expect(w.surah, equals(80));
      }
      expect(abasaWords.any((w) => w.word.contains('أَبّ')), isTrue);
    });

    test('8. عدم ظهور كلمات غير معتمدة في لوحة القراءة: excluded words never appear in page queries', () {
      final repo = QuranRepository.instance;
      // Page 1 contains Surah Al-Fatihah
      final page1Words = repo.getWordMeaningsForPage(1);

      // Excluded words like 'بسم الله', 'الرحمن', 'الرحيم' should NOT appear
      final wordsText = page1Words.map((w) => w.word).toList();
      expect(wordsText.contains('بِسْمِ اللهِ'), isFalse);
      expect(wordsText.contains('الرَّحْمنِ'), isFalse);
      expect(wordsText.contains('الرَّحِيمِ'), isFalse);

      // Verified lexical words like 'الصِّرَاطَ' MUST appear
      expect(wordsText.contains('الصِّرَاطَ'), isTrue);
      expect(wordsText.contains('المُسْتَقِيمَ'), isTrue);
    });
  });

  group('UI & Screen Flow Tests (7, 9, 10)', () {
    testWidgets('7. تحديث لوحة المعاني عند تغيير صفحة المصحف: panel updates for current page', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int currentPage = 1;
      bool isExpanded = true;

      await tester.pumpWidget(
        buildTestWidget(
          StatefulBuilder(
            builder: (ctx, setState) {
              return Scaffold(
                body: WordMeaningsPanel(
                  pageNumber: currentPage,
                  isExpanded: isExpanded,
                  onToggle: () {
                    setState(() => isExpanded = !isExpanded);
                  },
                  onClose: () {
                    setState(() => isExpanded = false);
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    setState(() => currentPage = 2);
                  },
                  child: const Icon(Icons.arrow_forward),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Page 1: Header shows "معاني كلمات صفحة ١"
      expect(find.textContaining('صفحة ١'), findsOneWidget);

      // Tap to switch to Page 2
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // On Page 2: Header updates automatically to "معاني كلمات صفحة ٢"
      expect(find.textContaining('صفحة ٢'), findsOneWidget);
    });

    testWidgets('9. عدم ظهور اسم المرجع بجانب الكلمة: WordMeaningsPanel does NOT render source name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(
          WordMeaningsPanel(
            pageNumber: 1,
            isExpanded: true,
            onToggle: () {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified word is displayed
      expect(find.text('الصِّرَاطَ'), findsOneWidget);

      // Source names must NEVER appear next to the word in the panel
      expect(find.textContaining('المعجم الوسيط'), findsNothing);
      expect(find.textContaining('معجم الدوحة'), findsNothing);
      expect(find.textContaining('السراج'), findsNothing);
    });

    testWidgets('10. ظهور المصادر في صفحة المصادر: WordMeaningsSourcesScreen displays lexicon sources and legal terms', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(const WordMeaningsSourcesScreen()),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('المصادر المعتمدة'), findsOneWidget);

      // Primary source: Al-Mu'jam Al-Waseet
      expect(find.text('المعجم الوسيط'), findsOneWidget);
      expect(find.textContaining('مجمع اللغة العربية بالقاهرة'), findsWidgets);
      expect(find.textContaining('arabicacademy.gov.eg'), findsWidgets);

      // Verification source: Doha Historical Dictionary
      expect(find.text('معجم الدوحة التاريخي للغة العربية'), findsOneWidget);
      expect(find.textContaining('dohadictionary.org'), findsWidgets);

      // Legal & Licensing compliance card
      expect(find.text('تحقيق الملكية الفكرية وتراخيص الاستخدام'), findsOneWidget);
    });

    testWidgets('WordMeaningsScreen renders and filters words smoothly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(const WordMeaningsScreen()),
      );
      await tester.pumpAndSettle();

      // Title is present, and Sources button is completely removed
      expect(find.text('معاني كلمات القرآن'), findsOneWidget);
      expect(find.text('المصادر'), findsNothing);

      // Search for specific word
      await tester.enterText(find.byType(TextField), 'الصراط');
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      expect(find.text('الصِّرَاطَ'), findsOneWidget);
    });

    testWidgets('QuranScreen integrates WordMeaningsPanel and toggles it smoothly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(const QuranScreen(initialPage: 1)),
      );
      await tester.pumpAndSettle();

      // Word meanings collapsed bar should be visible at bottom
      expect(find.byType(WordMeaningsPanel), findsOneWidget);

      // Toggle top bar
      await tester.tap(find.byType(QuranScreen));
      await tester.pumpAndSettle();

      // Top bar word meanings button exists
      expect(find.byTooltip('معاني كلمات الصفحة'), findsOneWidget);
    });

    test('CustomWordMeaningConfig converts to QuranWordMeaning correctly', () {
      const config = CustomWordMeaningConfig(
        surah: 1,
        ayah: 2,
        word: 'الْحَمْدُ',
        meaning: 'الثناء بالجميل على جهة التبجيل',
      );
      final model = config.toQuranWordMeaning(1);
      expect(model.surah, 1);
      expect(model.ayah, 2);
      expect(model.word, 'الْحَمْدُ');
      expect(model.page, 1);
      expect(model.meaning, 'الثناء بالجميل على جهة التبجيل');
      expect(model.sourceId, 999);
    });
  });
}
