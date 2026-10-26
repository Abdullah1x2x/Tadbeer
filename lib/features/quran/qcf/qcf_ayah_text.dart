import 'package:flutter/material.dart';

import '../data/quran_models.dart';
import 'qcf_fonts.dart';
import 'qcf_layout.dart';
import 'qcf_page_body.dart';

/// آية واحدة بخط مصحف المدينة، تلتف أسطرها حسب المساحة.
///
/// The ayah's words are its glyphs in the Madinah Mushaf, ending with the
/// printed ayah-number marker; every page there ends on a whole ayah, so
/// they all come from the ayah's page. Until the layout and that page's
/// font are ready, and if they cannot be loaded, [fallback] shows instead.
class QcfAyahText extends StatefulWidget {
  final Ayah ayah;

  /// Font size of an ordinary page's glyphs; opening pages are scaled to
  /// match.
  final double fontSize;

  final Color color;

  /// Line height relative to [fontSize].
  final double height;

  /// Shown while the glyphs load, or if they cannot be drawn.
  final Widget fallback;

  /// ينشئ نص الآية بخط مصحف المدينة.
  const QcfAyahText({
    super.key,
    required this.ayah,
    required this.fontSize,
    required this.color,
    required this.fallback,
    this.height = 1.9,
  });

  @override
  State<QcfAyahText> createState() => _QcfAyahTextState();
}

class _QcfAyahTextState extends State<QcfAyahText> {
  late Future<bool> _ready;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(QcfAyahText old) {
    super.didUpdateWidget(old);
    if (old.ayah.id != widget.ayah.id) _prepare();
  }

  int get _page => widget.ayah.page;

  void _prepare() {
    _ready = QcfLayout.instance.init().then(
      (_) async =>
          _words().isNotEmpty && await QcfFonts.instance.ensurePage(_page),
    );
  }

  /// The ayah's glyphs, in reading order.
  List<QcfWord> _words() => [
    for (final line in QcfLayout.instance.page(_page))
      for (final word in line.words)
        if (word.surah == widget.ayah.surahNumber &&
            word.ayah == widget.ayah.ayahNumber)
          word,
  ];

  Widget _text() {
    final scale = QcfPageBody.glyphScale(_page);
    return Text(
      '${_words().map((w) => w.code).join(' ')} ',
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: QcfFonts.familyFor(_page),
        fontSize: widget.fontSize * scale,
        height: widget.height / scale,
        color: widget.color,
      ),
    );
  }

  /// Whether the glyphs can be drawn right now, as when the ayah is opened
  /// from its page in the Mushaf.
  bool get _loaded =>
      QcfLayout.instance.isReady &&
      QcfFonts.instance.isPageLoaded(_page) &&
      _words().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_loaded) return _text();
    return FutureBuilder<bool>(
      future: _ready,
      builder: (context, snap) => snap.data == true ? _text() : widget.fallback,
    );
  }
}
