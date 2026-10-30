import 'dart:async';
import 'dart:math' as math;

import '../../../core/utils/arabic_search_normalizer.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../widgets/surah_header_banner.dart';
import 'qcf_fonts.dart';
import 'qcf_layout.dart';

/// متن صفحة مصحف المدينة بخط مجمع الملك فهد.
///
/// عند [zoom] = 1 تُرصف الصفحة سطراً بسطر كالمطبوع، بحجم تتسع به كاملة في أي
/// شاشة. وتحت 1 تصغر، وفوقه تنساب نفس الرموز فقرات ملتفة تُمرّر، فلا يُقص سطر
/// ولا يُحتاج تمرير أفقي.
class QcfPageBody extends StatefulWidget {
  final int pageNumber;
  final double zoom;
  final Color textColor;

  /// لون علامة رقم الآية على الآيات التي عليها فاصل أو خاطرة أو تدبر.
  final Color markerColor;

  /// خلفية الآية (تحديد أو تظليل)، أو null.
  final Color? Function(int surah, int ayah) backgroundFor;

  /// أيقونات ما على الآية (فاصل، خاطرة، تدبر، حفظ) بألوانها؛ فارغة إن لم يكن
  /// عليها شيء.
  final List<(IconData, Color)> Function(int surah, int ayah) markersFor;

  final GestureRecognizer Function(Ayah ayah) recognizerFor;

  /// يظهر حتى يجهز خط الصفحة، أو إن تعذّر تحميله.
  final Widget fallback;

  /// البسملة كما في المطبوع: كلمات أول الفاتحة بخط الصفحة الأولى دون رقمها؛
  /// فسطور البسملة لا رموز لها.
  @visibleForTesting
  static const basmalaGlyphs = '\uFB51\uFB52\uFB53\uFB54';

  /// حجم البسملة نسبةً إلى خط الصفحة، لتكون حروفها بحجم حروف الآيات تماماً: نفس
  /// الكلمات في النمل 30 (صفحة 379) أطول 1.32 مرة وأعرض 1.38 مرة من بسملة
  /// الصفحة الأولى بنفس الحجم.
  @visibleForTesting
  static const basmalaScale = 1.35;

  /// خطا الصفحتين الأوليين يرسمان الكلمات أصغر بنفس الحجم: وسيط ارتفاع الكلمة
  /// 0.889 و0.834 من الحجم مقابل 1.036 في غيرهما (مقيساً من أشكال الرموز). هذه
  /// المعاملات تجعل حروفهما بارتفاع حروف سائر الصفحات.
  static const _openingScale = {1: 1.165, 2: 1.241};

  /// كم تُكبّر رموز [page] لتطابق باقي المصحف: أكثر من 1 لصفحتي البداية، و1
  /// لغيرهما.
  static double glyphScale(int page) => _openingScale[page] ?? 1;

  /// عرض المسافة لكل وحدة من حجم الخط، مقيساً من الخطوط: 0.04 في كل الصفحات إلا
  /// الأولى، فخطها يرسمها 0.293.
  static const _space = 0.04;
  static const _wideSpace = {1: 0.293};

  /// تباعد الكلمات الذي يعيد مسافات [page] إلى عرضها المعتاد بحجم [fontSize]،
  /// فلا تتباعد كلمات الصفحة الأولى.
  static double wordSpacingFor(int page, double fontSize) =>
      _space * fontSize - (_wideSpace[page] ?? _space) * fontSize;

  const QcfPageBody({
    super.key,
    required this.pageNumber,
    required this.zoom,
    required this.textColor,
    required this.markerColor,
    required this.backgroundFor,
    required this.markersFor,
    required this.recognizerFor,
    required this.fallback,
  });

  @override
  State<QcfPageBody> createState() => _QcfPageBodyState();
}

class _QcfPageBodyState extends State<QcfPageBody> {
  /// الحجم الذي تُقاس به الأسطر، وتُحسب منه المقاسات.
  static const _probe = 100.0;

  /// ارتفاع السطر نسبةً إلى حجم الخط.
  static const _lineHeight = 1.9;

  /// أعرض سطر في الصفحة العادية بحجم [_probe] (الوسيط عبر المصحف)، لتُقاس به
  /// صفحتا البداية.
  static const _typicalWidest = 1450.0;

  late Future<bool> _ready;
  Timer? _neighbours;

  @override
  void dispose() {
    _neighbours?.cancel();
    super.dispose();
  }

  /// أعرض سطر في كل صفحة بحجم [_probe]؛ لا يتغير، فيبقى عند الرجوع إليها.
  static final Map<int, double> _widestLines = {};

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
      // خط البسملة المرسومة أعلى أغلب السور.
      QcfFonts.instance.ensurePage(1),
    ]).then((r) => r.every((ok) => ok));
    // الصفحات المجاورة تُحمّل في الخلفية ليبقى التقليب سلساً، بعد أن يهدأ السحب
    // الذي جاء بهذه الصفحة: تسجيل الخط يحجز خيط الواجهة لحظة.
    _neighbours?.cancel();
    _neighbours = Timer(const Duration(milliseconds: 600), () {
      for (final p in [page - 1, page + 1]) {
        if (p >= 1 && p <= QcfFonts.pageCount) QcfFonts.instance.ensurePage(p);
      }
    });
  }

  String get _family => QcfFonts.familyFor(widget.pageNumber);

  /// أعرض سطر في الصفحة بحجم [_probe]، يُقاس مرة لكل صفحة.
  double _measure(List<QcfLine> lines) {
    final known = _widestLines[widget.pageNumber];
    if (known != null) return known;
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
    return _widestLines[widget.pageNumber] = widest;
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
        // فارغة لحظة تحميل الخط، فلا تومض الصفحة بخط النص العادي؛ ذلك العرض
        // للفشل فقط.
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
    final openingScale = QcfPageBody._openingScale[widget.pageNumber];
    return LayoutBuilder(
      builder: (context, box) {
        final byWidth = _probe * box.maxWidth / widest;
        final byHeight = box.maxHeight / (lines.length * _lineHeight);
        var fit = math.min(byWidth, byHeight);
        if (openingScale != null) {
          // بحجم صفحة عادية من ١٥ سطراً على هذه الشاشة، مصحّحاً لصغر رموز صفحتي
          // البداية، مع إبقاء أسطرهما القصيرة كتلة في الوسط لا يتجاوز عرضها 92%
          // من الصفحة (85% كانت تصغّر الصفحة الأولى على الهواتف الشائعة).
          final ordinary = math.min(
            _probe * box.maxWidth / _typicalWidest,
            box.maxHeight / (15 * _lineHeight),
          );
          fit = math.min(
            ordinary * openingScale,
            math.min(byWidth * 0.92, byHeight),
          );
        }
        if (widget.zoom <= 1.0) {
          return _printed(lines, fit * widget.zoom, box.maxHeight);
        }
        return _flowing(lines, fit * widget.zoom);
      },
    );
  }

  /// الصفحة كالمطبوع: كل سطر وحده، في الوسط، بتباعد متساوٍ.
  Widget _printed(List<QcfLine> lines, double size, double height) {
    // أسطر الصفحة العادية الـ١٥ تتوزع لتملأها؛ أما أسطر صفحتي البداية القليلة
    // فتحتفظ بارتفاعها وتتجمع في الوسط كالمطبوع.
    final opening = QcfPageBody._openingScale.containsKey(widget.pageNumber);
    final slot = opening
        ? size * _lineHeight
        : math.min(
            math.max(size * _lineHeight, height / lines.length),
            size * _lineHeight * 1.25,
          );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final line in lines)
          SizedBox(
            height: slot,
            child: Center(child: _line(line, size)),
          ),
      ],
    );
  }

  /// الصفحة مكبّرة: أسطر الكلمات تندمج فقرات ملتفة.
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
        // تملأ السطر، والترويسة تتحجّم بارتفاعه.
        return SurahHeaderBanner(
          surah: QuranRepository.instance.getSurah(line.surah),
        );
      case QcfLineKind.basmala:
        return Text(
          QcfPageBody.basmalaGlyphs,
          semanticsLabel: QuranRepository.instance.getAyah(1, 1)?.text,
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: QcfFonts.familyFor(1),
            // حجم صفحتي البداية مكبّر لصغر رموزهما، والبسملة لا تشاركهما ذلك.
            fontSize:
                size *
                QcfPageBody.basmalaScale /
                QcfPageBody.glyphScale(widget.pageNumber),
            height:
                _lineHeight *
                QcfPageBody.glyphScale(widget.pageNumber) /
                QcfPageBody.basmalaScale,
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

  /// نص كلمات [run] من [ayah]: الرموز لا تعني شيئاً لقارئ الشاشة.
  ///
  /// علامات الوقف المنفصلة لا تقابلها كلمة في تخطيط الصفحة. وإن اختلف العددان
  /// قُرئت الآية كاملة عند أول أجزائها.
  String? _spokenWords(Ayah ayah, List<QcfWord> run) {
    final layout = [
      for (final line in QcfLayout.instance.page(widget.pageNumber))
        for (final word in line.words)
          if (word.surah == ayah.surahNumber &&
              word.ayah == ayah.ayahNumber &&
              !word.isEnd)
            word,
    ];
    final spoken = [
      for (final word in ayah.text.split(' '))
        if (ArabicSearchNormalizer.normalize(word).isNotEmpty) word,
    ];
    final at = layout.indexOf(run.first);
    if (at < 0) return null;
    if (spoken.length != layout.length) return at == 0 ? ayah.text : '';
    final length = run.where((w) => !w.isEnd).length;
    return spoken.sublist(at, at + length).join(' ');
  }

  /// مقطع لكل آية، فالنقر في أي موضع منها يختارها.
  TextSpan _spans(List<QcfWord> words, double size) {
    final runs = <InlineSpan>[];
    var i = 0;
    while (i < words.length) {
      final first = words[i];
      final start = i;
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
            semanticsLabel: ayah == null
                ? null
                : _spokenWords(ayah, words.sublist(start, i)),
            recognizer: recognizer,
            style: TextStyle(backgroundColor: background),
          ),
        );
      }
      if (end != null) {
        // علامة رقم الآية تصير ذهبية على الآيات التي علّمها القارئ، وفوقها
        // أيقونات ما عليها.
        final markers = widget.markersFor(first.surah, first.ayah);
        runs.add(
          TextSpan(
            text: end,
            semanticsLabel: ArabicSearchNormalizer.toArabicDigits(first.ayah),
            recognizer: recognizer,
            style: TextStyle(
              backgroundColor: background,
              color: markers.isEmpty ? null : widget.markerColor,
            ),
          ),
        );
        if (markers.isNotEmpty) {
          runs.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _AyahMarkers(markers: markers, fontSize: size),
            ),
          );
        }
        runs.add(
          TextSpan(
            text: ' ',
            recognizer: recognizer,
            style: TextStyle(backgroundColor: background),
          ),
        );
      }
    }
    return TextSpan(
      style: TextStyle(
        fontFamily: _family,
        fontSize: size,
        height: _lineHeight,
        wordSpacing: QcfPageBody.wordSpacingFor(widget.pageNumber, size),
        color: widget.textColor,
      ),
      children: runs,
    );
  }
}

/// أيقونات صغيرة فوق علامة رقم الآية.
///
/// أسطر المصحف المطبوع بعرض ثابت، فلا تأخذ الأيقونات من السطر شيئاً: مكانها
/// بلا عرض ولا ارتفاع، وتُرسم فوق العلامة التي قبلها.
class _AyahMarkers extends StatelessWidget {
  final List<(IconData, Color)> markers;
  final double fontSize;

  const _AyahMarkers({required this.markers, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final iconSize = (fontSize * 0.34).clamp(7.0, 14.0);
    return SizedBox.shrink(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.translate(
          // في السطر من اليمين إلى اليسار تقع العلامة يمين هذا المكان.
          offset: Offset(fontSize * 0.42, -fontSize * 0.78),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (icon, color) in markers)
                Icon(icon, size: iconSize, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
