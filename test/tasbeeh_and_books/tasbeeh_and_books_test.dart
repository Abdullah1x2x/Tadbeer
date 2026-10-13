import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/books/book_model.dart';
import 'package:tadbeer/features/books/book_reader_screen.dart';
import 'package:tadbeer/features/books/book_repository.dart';
import 'package:tadbeer/features/books/books_screen.dart';
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

    test('TasbeehDhikr catalog has 31 authentic items across all categories', () {
      expect(TasbeehDhikr.defaultDhikrs.length, 31);
      expect(TasbeehDhikr.categories.length, greaterThanOrEqualTo(7));

      for (final cat in TasbeehDhikr.categories) {
        if (cat == 'الكل') continue;
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
      final pool = TasbeehDhikr.defaultDhikrs.where((d) => d.category == 'حمد وشكر').toList();
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

    testWidgets('TasbeehScreen filters dhikrs by category chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const TasbeehScreen()));
      await tester.pumpAndSettle();

      // Find category chip 'تسبيح وتنزيه' and tap it
      final chipFinder = find.text('تسبيح وتنزيه');
      expect(chipFinder, findsWidgets);

      await tester.tap(chipFinder.first);
      await tester.pumpAndSettle();

      expect(repo.activeDhikr.category, 'تسبيح وتنزيه');
    });
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
      expect(find.text('إضافة كتاب أو ملزمة مع إرفاق ملف'), findsOneWidget);
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
  });

  group('HomeScreen Integration Tests', () {
    testWidgets('HomeScreen renders both new cards and navigates properly', (
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

      // Check existence of both sections on HomeScreen
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
