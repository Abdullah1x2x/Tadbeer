import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/books/book_reader_screen.dart';
import 'package:tadbeer/features/books/book_repository.dart';
import 'package:tadbeer/features/books/books_screen.dart';
import 'package:tadbeer/features/books/curated_books.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/tasbeeh/tasbeeh_model.dart';
import 'package:tadbeer/features/tasbeeh/tasbeeh_repository.dart';
import 'package:tadbeer/features/tasbeeh/tasbeeh_screen.dart';

Widget buildTestWidget(Widget child) {
  return MaterialApp(
    home: AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: Directionality(
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

  group('Tasbeeh & Istighfar Tests', () {
    late TasbeehRepository repo;

    setUp(() async {
      repo = TasbeehRepository.instance;
      await repo.init();
      repo.resetCurrentCount();
      repo.setActiveDhikr(TasbeehDhikr.defaultDhikrs.first);
    });

    test('TasbeehRepository increments and triggers target completion', () {
      repo.setTarget(3);
      expect(repo.currentCount, 0);

      expect(repo.increment(), isFalse);
      expect(repo.currentCount, 1);

      expect(repo.increment(), isFalse);
      expect(repo.currentCount, 2);

      expect(repo.increment(), isTrue);
      expect(repo.currentCount, 3);
    });

    test('TasbeehRepository resets current count while retaining lifetime', () {
      final initialLifetime = repo.lifetimeTotalCount;
      repo.increment();
      repo.increment();
      expect(repo.currentCount, 2);
      expect(repo.lifetimeTotalCount, initialLifetime + 2);

      repo.resetCurrentCount();
      expect(repo.currentCount, 0);
      expect(repo.lifetimeTotalCount, initialLifetime + 2);
    });

    test('TasbeehDhikr catalog has 49 authentic items across both sections', () {
      expect(TasbeehDhikr.defaultDhikrs.length, 49);
      expect(TasbeehDhikr.istighfarDhikrs.length, 20);
      expect(TasbeehDhikr.tasbeehDhikrs.length, 29);
      expect(TasbeehDhikr.categories, containsAll(['استغفار', 'تسبيح']));

      for (final cat in ['استغفار', 'تسبيح']) {
        final count = TasbeehDhikr.defaultDhikrs.where((d) => d.category == cat).length;
        expect(count, greaterThan(0), reason: 'Category $cat should have items');
      }
    });

    test('TasbeehRepository nextDhikr and previousDhikr cycles correctly', () {
      final total = TasbeehDhikr.defaultDhikrs.length;
      expect(repo.activeDhikr.id, TasbeehDhikr.defaultDhikrs.first.id);

      repo.nextDhikr();
      expect(repo.activeDhikr.id, TasbeehDhikr.defaultDhikrs[1].id);

      repo.previousDhikr();
      expect(repo.activeDhikr.id, TasbeehDhikr.defaultDhikrs.first.id);

      repo.previousDhikr();
      expect(repo.activeDhikr.id, TasbeehDhikr.defaultDhikrs[total - 1].id);

      // Testing within scoped pool
      final pool = TasbeehDhikr.defaultDhikrs.where((d) => d.category == 'تسبيح').toList();
      repo.setActiveDhikr(pool.first);
      expect(repo.activeDhikr.id, pool[0].id);

      repo.nextDhikr(pool: pool);
      expect(repo.activeDhikr.id, pool[1].id);
    });

    test('TasbeehRepository auto-advance toggling works', () {
      repo.setAutoAdvance(true);
      expect(repo.autoAdvanceEnabled, isTrue);

      repo.toggleAutoAdvance();
      expect(repo.autoAdvanceEnabled, isFalse);

      repo.toggleAutoAdvance();
      expect(repo.autoAdvanceEnabled, isTrue);
    });

    testWidgets('TasbeehScreen renders and responds to tap counting', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
      await tester.pumpAndSettle();

      expect(find.text('استغفار وتسبيح'), findsOneWidget);
      expect(find.text(TasbeehDhikr.defaultDhikrs.first.arabicText), findsOneWidget);

      final initialCount = repo.currentCount;
      // Tap on the center counting circle area
      await tester.tap(find.text('انقر في أي مكان للعدّ'));
      await tester.pumpAndSettle();

      expect(repo.currentCount, initialCount + 1);
    });

    testWidgets('TasbeehScreen auto-advances when target reached', (
      WidgetTester tester,
    ) async {
      repo.setActiveDhikr(TasbeehDhikr.defaultDhikrs.first);
      repo.setAutoAdvance(true);
      repo.setTarget(1);
      repo.resetCurrentCount();

      await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
      await tester.pumpAndSettle();

      expect(repo.currentCount, 0);
      final firstDhikrId = repo.activeDhikr.id;

      // Tap once to reach target (1 of 1)
      await tester.tap(find.text('انقر في أي مكان للعدّ'));
      await tester.pumpAndSettle();

      // Should automatically advance to the next dhikr and reset count to 0
      expect(repo.activeDhikr.id, isNot(firstDhikrId));
      expect(repo.currentCount, 0);
      expect(find.textContaining('تم الانتقال تلقائياً'), findsOneWidget);
    });

    testWidgets('TasbeehScreen switches dhikr via Next and Previous buttons', (
      WidgetTester tester,
    ) async {
      repo.setActiveDhikr(TasbeehDhikr.defaultDhikrs.first);
      await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
      await tester.pumpAndSettle();

      final firstId = repo.activeDhikr.id;

      // Tap Next button (tooltip: 'الذكر التالي')
      await tester.tap(find.byTooltip('الذكر التالي'));
      await tester.pumpAndSettle();

      expect(repo.activeDhikr.id, isNot(firstId));

      // Tap Previous button (tooltip: 'الذكر السابق')
      await tester.tap(find.byTooltip('الذكر السابق'));
      await tester.pumpAndSettle();

      expect(repo.activeDhikr.id, firstId);
    });

    testWidgets('TasbeehScreen switches sections between Istighfar and Tasbeeh', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
      await tester.pumpAndSettle();

      expect(repo.activeDhikr.isIstighfar, isTrue);

      // 1. Switch to Tasbeeh section
      final tasbeehTab = find.textContaining('التسبيح');
      expect(tasbeehTab, findsWidgets);
      await tester.tap(tasbeehTab.first);
      await tester.pumpAndSettle();

      expect(repo.activeDhikr.isTasbeeh, isTrue);
      expect(repo.activeSection, DhikrSection.tasbeeh);

      // 2. Switch back to Istighfar section
      final istighfarTab = find.textContaining('الاستغفار');
      expect(istighfarTab, findsWidgets);
      await tester.tap(istighfarTab.first);
      await tester.pumpAndSettle();

      expect(repo.activeDhikr.isIstighfar, isTrue);
      expect(repo.activeSection, DhikrSection.istighfar);
    });

    test('TasbeehRepository setActiveSection switches active dhikr between sections', () {
      repo.setActiveSection(DhikrSection.istighfar);
      expect(repo.activeSection, DhikrSection.istighfar);
      expect(repo.activeDhikr.isIstighfar, isTrue);

      repo.setActiveSection(DhikrSection.tasbeeh);
      expect(repo.activeSection, DhikrSection.tasbeeh);
      expect(repo.activeDhikr.isTasbeeh, isTrue);
      expect(repo.activeDhikr.id, TasbeehDhikr.tasbeehDhikrs.first.id);

      repo.setActiveSection(DhikrSection.istighfar);
      expect(repo.activeSection, DhikrSection.istighfar);
      expect(repo.activeDhikr.id, TasbeehDhikr.istighfarDhikrs.first.id);
    });

    testWidgets('TasbeehScreen changes target count via control chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
      await tester.pumpAndSettle();

      // Tap 33 target
      final target33 = find.text('33 مرة');
      expect(target33, findsOneWidget);
      await tester.ensureVisible(target33);
      await tester.tap(target33);
      await tester.pumpAndSettle();
      expect(repo.targetCount, 33);

      // Tap Free Count (0)
      final freeCount = find.text('عدّ حر (مفتوح)');
      expect(freeCount, findsOneWidget);
      await tester.ensureVisible(freeCount);
      await tester.tap(freeCount);
      await tester.pumpAndSettle();
      expect(repo.targetCount, 0);

      // Tap 100 target
      final target100 = find.text('100 مرة');
      expect(target100, findsOneWidget);
      await tester.ensureVisible(target100);
      await tester.tap(target100);
      await tester.pumpAndSettle();
      expect(repo.targetCount, 100);
    });

    testWidgets('TasbeehScreen copies dhikr text to clipboard', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
      await tester.pumpAndSettle();

      final copyButton = find.byTooltip('نسخ نص الذكر');
      expect(copyButton, findsOneWidget);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('تم نسخ نص الذكر'), findsOneWidget);
    });

    testWidgets(
      'TasbeehScreen AppBar has BackButton on right, actions on left, and dhikr text centered',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
        await tester.pumpAndSettle();

        final backButtonFinder = find.byType(BackButton);
        expect(backButtonFinder, findsOneWidget);

        final resetButtonFinder = find.byTooltip('تصفير عداد الدورة');
        expect(resetButtonFinder, findsOneWidget);

        final backOffset = tester.getCenter(backButtonFinder);
        final resetOffset = tester.getCenter(resetButtonFinder);

        // In RTL: BackButton (leading) is on the right, actions on the left
        expect(backOffset.dx, greaterThan(resetOffset.dx));
        expect(backOffset.dx, greaterThan(400.0));
        expect(resetOffset.dx, lessThan(400.0));

        // Dhikr text is strictly centered
        final dhikrTextFinder = find.text(repo.activeDhikr.arabicText);
        expect(dhikrTextFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(dhikrTextFinder);
        expect(textWidget.textAlign, TextAlign.center);

        final textCenter = tester.getCenter(dhikrTextFinder);
        expect((textCenter.dx - 400.0).abs(), lessThan(10.0));
      },
    );
  });

  group('Books & Booklets Tests', () {
    setUp(() async {
      await BookRepository.instance.init(disableDisk: true);
      await BookRepository.instance.clearAll();
    });

    test('BookModel defaultBooks is empty as requested', () {
      expect(BookModel.defaultBooks.isEmpty, isTrue);
    });

    test('BookRepository manages sections and books', () async {
      final repo = BookRepository.instance;
      expect(repo.sections.isEmpty, isTrue);
      expect(repo.books.isEmpty, isTrue);

      final section = await repo.addSection(
        name: 'ملازم التدبر',
        description: 'ملازم دورات التدبر وتفسير الآيات',
      );
      expect(section.name, 'ملازم التدبر');
      expect(repo.sections.length, 1);
      expect(repo.categoryNames, contains('ملازم التدبر'));

      final book = await repo.addBook(
        title: 'ملزمة مدارسة سورة الفاتحة',
        sectionName: 'ملازم التدبر',
        chapters: const [
          BookChapter(title: 'المبحث الأول', content: 'محتوى تفسير الاستعاذة'),
          BookChapter(title: 'المبحث الثاني', content: 'محتوى تفسير البسملة'),
        ],
      );
      expect(book.title, 'ملزمة مدارسة سورة الفاتحة');
      expect(repo.books.length, 1);
      expect(repo.getBooksBySection('ملازم التدبر').length, 1);
      expect(repo.getBooksBySection('الكل').length, 1);

      await repo.deleteBook(book.id);
      expect(repo.books.isEmpty, isTrue);

      await repo.deleteSection(section.id);
      expect(repo.sections.isEmpty, isTrue);
    });

    testWidgets('BooksScreen displays empty state when no books exist', (
      WidgetTester tester,
    ) async {
      await BookRepository.instance.clearAll();
      await tester.pumpWidget(buildTestWidget(const BooksScreen()));
      await tester.pumpAndSettle();

      expect(find.text('كتب وملازم'), findsOneWidget);
      expect(find.text('قسم الكتب والملازم فارغ حالياً'), findsOneWidget);
    });

    testWidgets('BooksScreen displays added books and sections', (
      WidgetTester tester,
    ) async {
      final repo = BookRepository.instance;
      await repo.clearAll();
      await repo.addSection(name: 'ملازم التدبر');
      await repo.addBook(
        title: 'ملزمة مدارسة الكهف',
        sectionName: 'ملازم التدبر',
        chapters: const [
          BookChapter(title: 'المقدمة', content: 'قصص سورة الكهف'),
        ],
      );

      await tester.pumpWidget(buildTestWidget(const BooksScreen()));
      await tester.pumpAndSettle();

      expect(find.text('كتب وملازم'), findsOneWidget);
      expect(find.text('ملزمة مدارسة الكهف'), findsOneWidget);
      expect(find.text('ملازم التدبر'), findsWidgets);
    });

    testWidgets('BookReaderScreen renders chapter content and navigates chapters', (
      WidgetTester tester,
    ) async {
      const book = BookModel(
        id: 'test_book_custom',
        title: 'ملزمة القواعد الحسان',
        category: 'ملازم',
        chapters: [
          BookChapter(title: 'المبحث الأول: الإخلاص', content: 'نص المبحث الأول عن الإخلاص'),
          BookChapter(title: 'المبحث الثاني: التدبر', content: 'نص المبحث الثاني عن التدبر'),
        ],
      );

      await tester.pumpWidget(
        buildTestWidget(const BookReaderScreen(book: book, initialChapterIndex: 0)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ملزمة القواعد الحسان'), findsOneWidget);
      expect(find.text('المبحث الأول: الإخلاص'), findsOneWidget);
      expect(find.text('نص المبحث الأول عن الإخلاص'), findsOneWidget);

      // Scroll to Next Chapter button and tap it
      await tester.ensureVisible(find.text('المبحث التالي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المبحث التالي'));
      await tester.pumpAndSettle();

      expect(find.text('المبحث الثاني: التدبر'), findsOneWidget);
      expect(find.text('نص المبحث الثاني عن التدبر'), findsOneWidget);
    });

    testWidgets('BookReaderScreen renders PDF attachment info card', (
      WidgetTester tester,
    ) async {
      const pdfBook = BookModel(
        id: 'test_pdf_custom',
        title: 'ملخص التفسير الموضوعي',
        category: 'ملازم',
        filePath: '/mock/path/tafseer.pdf',
        fileName: 'tafseer.pdf',
        fileType: 'pdf',
        fileSizeBytes: 2097152,
      );

      await tester.pumpWidget(
        buildTestWidget(const BookReaderScreen(book: pdfBook)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ملخص التفسير الموضوعي'), findsWidgets);
      expect(find.text('فتح ومطالعة ملف PDF'), findsOneWidget);
    });

    test('curatedBookSections contains Sayyed Hussein booklets, Ahlulbayt heritage, and Quranic sciences', () {
      expect(curatedBookSections.length, 3);

      final malazemSec = curatedBookSections.firstWhere((s) => s.name == 'ملازم السيد حسين الحوثي');
      expect(malazemSec.books.length, 86);
      expect(malazemSec.books.every((b) => b.author == 'السيد حسين بدر الدين الحوثي'), isTrue);
      expect(malazemSec.books.every((b) => b.assetPath != null && b.assetPath!.startsWith('assets/books/malazem/')), isTrue);

      final ahlulbaytSec = curatedBookSections.firstWhere((s) => s.name == 'تراث وأدعية أهل البيت (عليهم السلام)');
      expect(ahlulbaytSec.books.length, 4);
      expect(ahlulbaytSec.books.any((b) => b.title == 'الصحيفة السجادية الكاملة'), isTrue);
      final sahifah = ahlulbaytSec.books.firstWhere((b) => b.title == 'الصحيفة السجادية الكاملة');
      expect(sahifah.chapters.length, 54);

      expect(ahlulbaytSec.books.any((b) => b.title == 'رسالة الحقوق'), isTrue);
      final huquq = ahlulbaytSec.books.firstWhere((b) => b.title == 'رسالة الحقوق');
      expect(huquq.chapters.length, 17);

      expect(ahlulbaytSec.books.any((b) => b.title.contains('نهج البلاغة')), isTrue);
      expect(ahlulbaytSec.books.any((b) => b.title.contains('تحف العقول')), isTrue);

      final quranSciencesSec = curatedBookSections.firstWhere((s) => s.name == 'علوم وتدبر القرآن الكريم');
      expect(quranSciencesSec.books.length, 3);
      expect(quranSciencesSec.books.any((b) => b.title.contains('أخلاق حَمَلَة القرآن')), isTrue);
      expect(quranSciencesSec.books.any((b) => b.title.contains('قواعد وأصول في تدبر القرآن')), isTrue);
      expect(quranSciencesSec.books.any((b) => b.title.contains('التبيان')), isTrue);
    });

    testWidgets('BooksScreen renders sections, series chips for Sayyed Hussein, and filters', (
      WidgetTester tester,
    ) async {
      await BookRepository.instance.init(disableDisk: true);
      await tester.pumpWidget(buildTestWidget(const BooksScreen()));
      await tester.pumpAndSettle();

      expect(find.text('كتب وملازم'), findsWidgets);

      // Section FilterChips exist
      expect(find.textContaining('الكل'), findsWidgets);
      expect(find.textContaining('ملازم السيد حسين الحوثي'), findsWidgets);
      expect(find.textContaining('تراث وأدعية أهل البيت'), findsWidgets);

      // Tap on 'ملازم السيد حسين الحوثي' section chip
      final malazemChip = find.textContaining('ملازم السيد حسين الحوثي');
      await tester.tap(malazemChip);
      await tester.pumpAndSettle();

      // Verify series filter chips appear
      expect(find.textContaining('معرفة الله'), findsWidgets);
      expect(find.textContaining('مديح القرآن'), findsWidgets);

      // Search for specific booklet title
      await tester.enterText(find.byType(TextField), 'يوم القدس العالمي');
      await tester.pump();

      expect(find.textContaining('يوم القدس العالمي'), findsWidgets);
    });
  });

  group('HomeScreen Integration Tests', () {
    testWidgets('HomeScreen renders cards and navigates properly', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.updateSettings(
          UserDataStore.instance.settings.copyWith(
            hideTadbeerIntroPermanently: true,
          ),
        );
      });

      await tester.pumpWidget(const TadbeerApp());
      await tester.pumpAndSettle();

      // Check existence of sections on HomeScreen
      expect(find.text('استغفار وتسبيح'), findsOneWidget);
      expect(find.text('كتب وملازم'), findsOneWidget);

      // Ensure visible and tap on 'استغفار وتسبيح'
      await tester.ensureVisible(find.text('استغفار وتسبيح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('استغفار وتسبيح'));
      await tester.pumpAndSettle();

      expect(find.byType(TasbeehScreen), findsOneWidget);

      // Pop back to HomeScreen
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Scroll down to see 'كتب وملازم' and tap it
      await tester.ensureVisible(find.text('كتب وملازم'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('كتب وملازم'));
      await tester.pumpAndSettle();

      expect(find.byType(BooksScreen), findsOneWidget);
    });
  });
}
