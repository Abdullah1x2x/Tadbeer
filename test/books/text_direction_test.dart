import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/features/books/data/book_model.dart';
import 'package:tadbeer/features/books/screens/book_reader_screen.dart';
import 'package:tadbeer/core/utils/text_direction.dart';

void main() {
  test('direction comes from the text itself', () {
    expect(directionOfText('الحمد لله رب العالمين'), TextDirection.rtl);
    expect(directionOfText('In the name of God'), TextDirection.ltr);
    // A few Latin words inside Arabic keep it right to left.
    expect(directionOfText('هذا كتاب PDF عن التدبر'), TextDirection.rtl);
    expect(directionOfText('   '), TextDirection.rtl);
  });

  testWidgets('Arabic book text stays right to left in the English UI', (
    tester,
  ) async {
    const book = BookModel(
      id: 'b',
      title: 'ملزمة',
      category: 'ملازم',
      chapters: [
        BookChapter(title: 'الدرس الأول', content: 'بسم الله الرحمن الرحيم'),
      ],
    );
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.english,
        strings: const AppStrings(AppLanguage.english),
        onLanguageChanged: (_) {},
        child: const MaterialApp(home: BookReaderScreen(book: book)),
      ),
    );
    await tester.pump();
    final content = tester.widget<SelectableText>(
      find.byType(SelectableText).first,
    );
    expect(content.textDirection, TextDirection.rtl);
    final title = tester.widget<Text>(find.text('الدرس الأول').last);
    expect(title.textDirection, TextDirection.rtl);
  });
}
