import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/quran_models.dart';
import '../data/quran_repository.dart';
import '../widgets/surah_header_banner.dart';
import 'qcf_fonts.dart';
import 'qcf_layout.dart';

/// متن صفحة مصحف المدينة بخط مجمع الملك فهد.
///
/// At [zoom] 1 the page is laid out line for line as printed, sized so the
/// whole page fits the space it is given on any screen. Below 1 the page
/// shrinks; above 1 the same glyphs flow as wrapped paragraphs that scroll,
/// so enlarging never clips a line or needs sideways scrolling.
class QcfPageBody extends StatefulWidget {
  final int pageNumber;
  final double zoom;
  final Color textColor;

  /// Colour of ayah-number markers on ayahs with a bookmark, note or
  /// reflection.
  final Color markerColor;

  /// Background for an ayah (selection or highlight), or null.
  final Color? Function(int surah, int ayah) backgroundFor;

  /// Whether the ayah has a bookmark, note, reflection or is memorised.
  final bool Function(int surah, int ayah) isMarked;

  final GestureRecognizer Function(Ayah ayah) recognizerFor;

  /// Shown until the page's font is ready, or if it cannot be loaded.
  final Widget fallback;

  const QcfPageBody({
    super.key,
    required this.pageNumber,
    required this.zoom,
    required this.textColor,
    required this.markerColor,
    required this.backgroundFor,
    required this.isMarked,
    required this.recognizerFor,
    required this.fallback,
  });

  @override
  State<QcfPageBody> createState() => _QcfPageBodyState();
}

class _QcfPageBodyState extends State<QcfPageBody> {
  /// Size used to measure lines; layouts scale from it.
  static const _probe = 100.0;

  /// Line box height relative to the font size.
  static const _lineHeight = 1.9;

  /// Widest line of an ordinary page at [_probe] size (the median across
  /// the Mushaf), used to size the opening pages like the rest.
  static const _typicalWidest = 1450.0;

  /// The fonts of the first two pages draw words smaller for the same font
  /// size: their median word height is 0.889 and 0.834 of the size, against
  /// 1.036 elsewhere (measured from the glyph outlines). These factors make
  /// their letters as tall as on every other page.
  static const _openingScale = {1: 1.165, 2: 1.241};

  /// The basmala as printed: the words of Al-Fatiha's first ayah in the
  /// first page's font, without its ayah number. Basmala lines carry no
  /// glyphs of their own.
  static const _basmalaGlyphs = '\uFB51\uFB52\uFB53\uFB54';

  /// Size of the basmala against the page's font size: the first page's
  /// glyphs are drawn small, and at this size the basmala's letters match
  /// the page's and it spans about half the line, as printed.
  static const _basmalaScale = 1.6;

  late Future<bool> _ready;
  Timer? _neighbours;

  @override
  void dispose() {
    _neighbours?.cancel();
    super.dispose();
  }

  int? _measuredPage;
  double _widestLine = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(QcfPageBody old) {
    super.didUpdateWidget(old);
    if (old.pageNumber != widget.pageNumber) _prepare();
  }

  void _prepare() {
    final page = widget.pageNumber;
    _ready = Future.wait([
      QcfLayout.instance.init().then((_) => true),
      QcfFonts.instance.ensurePage(page),
      // Holds the basmala glyphs drawn at the top of most surahs.
      QcfFonts.instance.ensurePage(1),
    ]).then((r) => r.every((ok) => ok));
    // Neighbouring pages load in the background so swiping stays smooth,
    // once the swipe that brought this page has settled: registering a
    // font blocks the UI thread for a moment.
    _neighbours?.cancel();
    _neighbours = Timer(const Duration(milliseconds: 600), () {
      for (final p in [page - 1, page + 1]) {
        if (p >= 1 && p <= QcfFonts.pageCount) QcfFonts.instance.ensurePage(p);
      }
    });
  }

  String get _family => QcfFonts.familyFor(widget.pageNumber);

  /// Widest line of the page at [_probe] size, measured once per page.
  double _measure(List<QcfLine> lines) {
    if (_measuredPage == widget.pageNumber) return _widestLine;
    var widest = 1.0;
    for (final line in lines) {
      if (line.kind != QcfLineKind.words) continue;
      final painter = TextPainter(
        text: TextSpan(
          text: line.words.map((w) => w.code).join(' '),
          style: TextStyle(fontFamily: _family, fontSize: _probe),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    _measuredPage = widget.pageNumber;
    return _widestLine = widest;
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.pageNumber;
    final loaded =
        QcfLayout.instance.isReady &&
        QcfFonts.instance.isPageLoaded(page) &&
        QcfFonts.instance.isPageLoaded(1);
    if (loaded) return _page(context);
    return FutureBuilder<bool>(
      future: _ready,
      builder: (context, snap) {
        if (snap.data == true) return _page(context);
        // Blank for the moment the font takes to load, so the page never
        // flashes in the plain text font; that view is only for a failure.
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.expand();
        }
        return widget.fallback;
      },
    );
  }

  Widget _page(BuildContext context) {
    final lines = QcfLayout.instance.page(widget.pageNumber);
    if (lines.isEmpty) return widget.fallback;
    final widest = _measure(lines);
    final openingScale = _openingScale[widget.pageNumber];
    return LayoutBuilder(
      builder: (context, box) {
        final byWidth = _probe * box.maxWidth / widest;
        final byHeight = box.maxHeight / (lines.length * _lineHeight);
        var fit = math.min(byWidth, byHeight);
        if (openingScale != null) {
          // Sized like an ordinary 15-line page on this screen, then
          // corrected for the smaller glyphs, keeping the short lines a
          // centred block no wider than 85% of the page.
          final ordinary = math.min(
            _probe * box.maxWidth / _typicalWidest,
            box.maxHeight / (15 * _lineHeight),
          );
          fit = math.min(
            ordinary * openingScale,
            math.min(byWidth * 0.85, byHeight),
          );
        }
        if (widget.zoom <= 1.0) {
          return _printed(lines, fit * widget.zoom, box.maxHeight);
        }
        return _flowing(lines, fit * widget.zoom);
      },
    );
  }

  /// The page as printed: every line on its own, centred, evenly spaced.
  Widget _printed(List<QcfLine> lines, double size, double height) {
    final slot = math.max(size * _lineHeight, height / lines.length);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final line in lines)
          SizedBox(
            height: math.min(slot, size * _lineHeight * 1.25),
            child: Center(child: _line(line, size)),
          ),
      ],
    );
  }

  /// The page enlarged: word lines merge into paragraphs that wrap.
  Widget _flowing(List<QcfLine> lines, double size) {
    final children = <Widget>[];
    var words = <QcfWord>[];
    void flush() {
      if (words.isEmpty) return;
      children.add(
        Text.rich(
          _spans(words, size),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      );
      words = [];
    }

    for (final line in lines) {
      if (line.kind == QcfLineKind.words) {
        words.addAll(line.words);
      } else {
        flush();
        children.add(
          SizedBox(height: size * _lineHeight, child: _line(line, size)),
        );
      }
    }
    flush();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _line(QcfLine line, double size) {
    switch (line.kind) {
      case QcfLineKind.surahHeader:
        // Fills the line; the banner scales itself to the line's height.
        return SurahHeaderBanner(
          surah: QuranRepository.instance.getSurah(line.surah),
        );
      case QcfLineKind.basmala:
        return Text(
          _basmalaGlyphs,
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: QcfFonts.familyFor(1),
            // The opening pages' size is raised for their own small glyphs,
            // which the basmala does not share.
            fontSize:
                size * _basmalaScale / (_openingScale[widget.pageNumber] ?? 1),
            height:
                _lineHeight *
                (_openingScale[widget.pageNumber] ?? 1) /
                _basmalaScale,
            color: widget.textColor,
          ),
        );
      case QcfLineKind.words:
        return Text.rich(
          _spans(line.words, size),
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.rtl,
        );
    }
  }

  /// One span per ayah run, so a tap anywhere on an ayah selects it.
  TextSpan _spans(List<QcfWord> words, double size) {
    final runs = <TextSpan>[];
    var i = 0;
    while (i < words.length) {
      final first = words[i];
      final text = StringBuffer();
      String? end;
      while (i < words.length &&
          words[i].surah == first.surah &&
          words[i].ayah == first.ayah) {
        if (words[i].isEnd) {
          end = words[i].code;
        } else {
          text.write('${words[i].code} ');
        }
        i++;
      }
      final ayah = QuranRepository.instance.getAyah(first.surah, first.ayah);
      final recognizer = ayah == null ? null : widget.recognizerFor(ayah);
      final background = widget.backgroundFor(first.surah, first.ayah);
      if (text.isNotEmpty) {
        runs.add(
          TextSpan(
            text: text.toString(),
            recognizer: recognizer,
            style: TextStyle(backgroundColor: background),
          ),
        );
      }
      if (end != null) {
        // The ayah-number marker turns gold on ayahs the reader marked.
        final marked = widget.isMarked(first.surah, first.ayah);
        runs.add(
          TextSpan(
            text: '$end ',
            recognizer: recognizer,
            style: TextStyle(
              backgroundColor: background,
              color: marked ? widget.markerColor : null,
            ),
          ),
        );
      }
    }
    return TextSpan(
      style: TextStyle(
        fontFamily: _family,
        fontSize: size,
        height: _lineHeight,
        color: widget.textColor,
      ),
      children: runs,
    );
  }
}
