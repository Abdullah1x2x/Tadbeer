import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_page_body.dart';

/// The box the [text]'s ink covers, drawn at [size] in [family].
Future<Rect> inkOf(String text, String family, double size) async {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: family, fontSize: size, color: Colors.black),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Offset(50, 50));
  final w = (painter.width + 100).ceil();
  final h = (painter.height + 100).ceil();
  painter.dispose();
  final image = await recorder.endRecording().toImage(w, h);
  final bytes = (await image.toByteData())!;
  var left = w, top = h, right = 0, bottom = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bytes.getUint8((y * w + x) * 4 + 3) > 60) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right.toDouble(),
    bottom.toDouble(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the basmala is as large as the same words in an ayah', () async {
    await QcfFonts.instance.ensurePage(1);
    await QcfFonts.instance.ensurePage(379);
    const size = 100.0;
    final basmala = await inkOf(
      QcfPageBody.basmalaGlyphs,
      QcfFonts.familyFor(1),
      size * QcfPageBody.basmalaScale,
    );
    // «بسم الله الرحمن الرحيم» inside An-Naml 30.
    final inAyah = await inkOf('ﮪﮫﮬﮭ', QcfFonts.familyFor(379), size);
    expect(basmala.height / inAyah.height, closeTo(1, 0.05));
    expect(basmala.width / inAyah.width, closeTo(1, 0.05));
  });
}
