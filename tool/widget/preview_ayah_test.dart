// Draws the sample ayah of the widget picker's preview in the Mushaf script.
//
// Launchers draw a widget preview with the system font, ignoring the app's own
// fonts, so the ayah is an image drawn the way the live widget draws its ayah.
//
// Run from the repo root: flutter test tool/widget/preview_ayah_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/qcf/qcf_page_body.dart';

const _out = 'android/app/src/main/res/drawable-nodpi/widget_preview_ayah.png';

void main() {
  testWidgets('draw the preview ayah', (tester) async {
    late QcfGlyphs glyphs;
    await tester.runAsync(() async {
      await (FontLoader(QcfPageBody.digitalKhattFamily)
            ..addFont(rootBundle.load('assets/fonts/DigitalKhattV2.otf')))
          .load();
      await QuranRepository.instance.init();
      final ayah = QuranRepository.instance.getAyah(13, 28)!;
      await QcfGlyphs.prepare(ayah);
      glyphs = QcfGlyphs.ofExcerpt(
        ayah,
        'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
      )!;
    });

    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              glyphs.text.trim(),
              textDirection: TextDirection.rtl,
              style: glyphs.style(
                fontSize: 22,
                height: 1.9,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x66000000), blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File(_out).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
