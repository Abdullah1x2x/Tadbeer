import 'package:flutter/material.dart';

import 'qcf_fonts.dart';
import 'qcf_layout.dart';

/// معاينة صغيرة لخط مصحف المدينة في الإعدادات.
///
/// أول البقرة (الصفحة ٢) بخطها بتكبير [zoom]، تلتف كما تلتف الصفحة المكبّرة،
/// فيرى القارئ أثر الحجم قبل اختياره.
class MadinahPreview extends StatefulWidget {
  final double zoom;
  final Color color;

  const MadinahPreview({super.key, required this.zoom, required this.color});

  @override
  State<MadinahPreview> createState() => _MadinahPreviewState();
}

class _MadinahPreviewState extends State<MadinahPreview> {
  static const _page = 2;

  late final Future<bool> _ready = Future.wait([
    QcfLayout.instance.init().then((_) => true),
    QcfFonts.instance.ensurePage(_page),
  ]).then((r) => r.every((ok) => ok));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _ready,
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox(height: 90);
        // البقرة 1-3: أول ثلاثة أسطر كلمات في الصفحة.
        final words = QcfLayout.instance
            .page(_page)
            .where((l) => l.kind == QcfLineKind.words)
            .take(3)
            .expand((l) => l.words)
            .map((w) => w.code)
            .join(' ');
        return Text(
          words,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: QcfFonts.familyFor(_page),
            fontSize: 22 * widget.zoom,
            height: 1.9,
            color: widget.color,
          ),
        );
      },
    );
  }
}
