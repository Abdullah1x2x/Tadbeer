import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/books/book_model.dart';
import 'package:tadbeer/features/books/book_reader_screen.dart';
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
  });

  group('Books & Booklets Tests', () {
    test('BookModel has default curated study booklets', () {
      expect(BookModel.defaultBooks.isNotEmpty, isTrue);
      final firstBook = BookModel.defaultBooks.first;
      expect(firstBook.chapters.isNotEmpty, isTrue);
      expect(firstBook.title, contains('القواعد الحسان'));
    });

    testWidgets('BooksScreen displays booklets and filters by category', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const BooksScreen()));
      await tester.pumpAndSettle();

      expect(find.text('كتب وملازم'), findsOneWidget);
      expect(find.text('القواعد الحسان في تدبر القرآن'), findsOneWidget);

      // Filter by 'علوم القرآن' specifically on FilterChip
      await tester.tap(find.widgetWithText(FilterChip, 'علوم القرآن'));
      await tester.pumpAndSettle();

      expect(find.text('مدخل ميسر إلى علوم القرآن وأصول التفسير'), findsOneWidget);
    });

    testWidgets('BookReaderScreen renders chapter content and navigates chapters', (
      WidgetTester tester,
    ) async {
      final book = BookModel.defaultBooks.first;
      await tester.pumpWidget(
        buildTestWidget(BookReaderScreen(book: book, initialChapterIndex: 0)),
      );
      await tester.pumpAndSettle();

      expect(find.text(book.title), findsOneWidget);
      expect(find.text(book.chapters[0].title), findsOneWidget);

      // Scroll to Next Chapter button and tap it
      await tester.ensureVisible(find.text('المبحث التالي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المبحث التالي'));
      await tester.pumpAndSettle();

      expect(find.text(book.chapters[1].title), findsOneWidget);
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
