import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/notes/note_model.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';
import 'package:tadbeer/features/settings/user_settings_model.dart';

List<Rect> mergeTextBoxes(List<TextBox> boxes, double maxWidth) {
  if (boxes.isEmpty) return const [];

  final lineGroups = <List<Rect>>[];

  for (final box in boxes) {
    var rect = box.toRect();
    rect = Rect.fromLTRB(
      rect.left.clamp(0.0, maxWidth),
      rect.top,
      rect.right.clamp(0.0, maxWidth),
      rect.bottom,
    );
    if (rect.width <= 0.1 || rect.height <= 0.1) continue;

    bool foundLine = false;
    for (final group in lineGroups) {
      final sample = group.first;
      final vOverlap = math.min(sample.bottom, rect.bottom) - math.max(sample.top, rect.top);
      if (vOverlap > (sample.height * 0.5)) {
        group.add(rect);
        foundLine = true;
        break;
      }
    }

    if (!foundLine) {
      lineGroups.add([rect]);
    }
  }

  final mergedLines = <Rect>[];
  for (final group in lineGroups) {
    double minLeft = group.map((r) => r.left).reduce(math.min);
    double maxRight = group.map((r) => r.right).reduce(math.max);
    double minTop = group.map((r) => r.top).reduce(math.min);
    double maxBottom = group.map((r) => r.bottom).reduce(math.max);

    mergedLines.add(Rect.fromLTRB(minLeft, minTop, maxRight, maxBottom));
  }

  mergedLines.sort((a, b) => a.top.compareTo(b.top));
  return mergedLines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hl_test_');
    final dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    // These tests cover the flowing text view, not the Madinah pages.
    await UserDataStore.instance.setMushafStyle(MushafStyle.text);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Ayah highlight boxes computation and separation', (tester) async {
    const text1 = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ﴿١﴾';
    const text2 = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ﴿٢﴾';
    const fullText = '$text1 $text2 ';

    final span = TextSpan(
      style: const TextStyle(
        fontFamily: 'AmiriQuran',
        fontSize: 22,
        height: 1.95,
      ),
      text: fullText,
    );

    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
    tp.layout(maxWidth: 400);

    // Ayah 1 selection
    final boxes1 = tp.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: text1.length),
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    final merged1 = mergeTextBoxes(boxes1, 400);

    // Ayah 2 selection
    final start2 = text1.length + 1; // skip space
    final end2 = start2 + text2.length;
    final boxes2 = tp.getBoxesForSelection(
      TextSelection(baseOffset: start2, extentOffset: end2),
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    final merged2 = mergeTextBoxes(boxes2, 400);

    expect(merged1.isNotEmpty, isTrue);
    expect(merged2.isNotEmpty, isTrue);

    // If both ayahs share a line, verify they don't overlap horizontally
    for (final r1 in merged1) {
      for (final r2 in merged2) {
        final vOverlap = math.min(r1.bottom, r2.bottom) - math.max(r1.top, r2.top);
        if (vOverlap > 10) {
          // On same line: verify horizontal separation
          final hOverlap = math.min(r1.right, r2.right) - math.max(r1.left, r2.left);
          expect(hOverlap <= 0, isTrue, reason: 'Adjacent ayahs on same line must not overlap: r1=$r1, r2=$r2');
        }
      }
    }
  });

  testWidgets('QuranPageView renders CustomPaint highlight when Ayah is selected', (tester) async {
    final page1 = QuranRepository.instance.getPage(1);
    final selected = page1.ayahs.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranPageView(
            page: page1,
            selectedAyah: selected,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify CustomPaint is rendered for the active selection
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('سُورَةُ الفاتحة'), findsWidgets);
  });

  testWidgets('QuranPageView displays bookmark and note icons next to Ayah', (tester) async {
    final page1 = QuranRepository.instance.getPage(1);
    final firstAyah = page1.ayahs.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranPageView(
            page: page1,
            selectedAyah: firstAyah,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsNothing);
    expect(find.byIcon(AppIcons.notePencil), findsNothing);

    // Add bookmark to first Ayah
    await tester.runAsync(() async {
      await UserDataStore.instance.toggleBookmark(firstAyah);
    });
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsOneWidget);
    expect(find.byIcon(AppIcons.notePencil), findsNothing);

    // Add note to first Ayah
    await tester.runAsync(() async {
      await UserDataStore.instance.saveNote(
        type: NoteType.ayah,
        content: 'ملاحظة تدبرية على البسملة',
        ayahId: firstAyah.id,
        surahNumber: firstAyah.surahNumber,
        ayahNumber: firstAyah.ayahNumber,
        page: firstAyah.page,
        ayahText: firstAyah.text,
      );
    });
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsOneWidget);
    expect(find.byIcon(AppIcons.notePencil), findsOneWidget);
  });
}

