import 'package:flutter/material.dart';

import 'qcf_layout.dart';
import 'qcf_page_body.dart';

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

  final Future<void> _ready = QcfLayout.instance.init();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 90);
        }
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
            fontFamily: QcfPageBody.digitalKhattFamily,
            fontSize: 22 * widget.zoom,
            height: 1.9,
            color: widget.color,
          ),
        );
      },
    );
  }
}
