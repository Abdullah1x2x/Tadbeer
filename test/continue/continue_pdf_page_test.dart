import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/books/book_reader_screen.dart';
import 'package:tadbeer/features/books/book_repository.dart';
import 'package:tadbeer/features/continue/continue_card.dart';
import 'package:tadbeer/features/continue/last_activity.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_continue_pdf_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    final books = Directory('${tempDir.path}/books')..createSync();
    await BookRepository.instance.init(
      disableDisk: true,
      booksDirectory: books,
    );
    await BookRepository.instance.clearAll();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget host(Widget child) => AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: const AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('continue opens a PDF book at the page it was left on', (
    tester,
  ) async {
    final book = await tester.runAsync(() async {
      final pdf = File('${tempDir.path}/lesson.pdf')
        ..writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);
      return BookRepository.instance.addBook(
        title: 'ملزمة',
        sectionName: 'ملازم',
        attachedFile: pdf,
      );
    });
    expect(book!.isPdf, isTrue);

    // Opening at page 13 (index 12) records that page.
    await tester.pumpWidget(
      host(BookReaderScreen(book: book, initialPdfPage: 12)),
    );
    await tester.pump();
    final recorded = LastActivityStore.recent().first;
    expect(recorded.kind, ActivityKind.book);
    expect(recorded.position, 12);

    await tester.pumpWidget(host(const ContinueCard()));
    await tester.pump();
    expect(find.text('صفحة ١٣'), findsOneWidget);

    await tester.tap(find.text('ملزمة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final reader = tester.widget<BookReaderScreen>(
      find.byType(BookReaderScreen),
    );
    expect(reader.initialPdfPage, 12);
  });
}
