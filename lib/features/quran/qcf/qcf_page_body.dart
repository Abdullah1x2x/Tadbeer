import 'dart:math' as math;

import '../../../core/utils/arabic_search_normalizer.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../widgets/surah_header_banner.dart';
import 'kashida.dart';
import 'qcf_layout.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/storage/user_data_store.dart';

/// متن صفحة مصحف المدينة بخط Digital Khatt، خط واحد تُمدّ أسطره بالكشيدة.
///
/// عند [zoom] = 1 تُرصف الصفحة سطراً بسطر كالمطبوع، بحجم تتسع به كاملة في أي
/// شاشة. وتحت 1 تصغر، وفوقه تنساب نفس الكلمات فقرات ملتفة تُمرّر، فلا يُقص سطر
/// ولا يُحتاج تمرير أفقي.
class QcfPageBody extends StatefulWidget {
  final int pageNumber;
  final double zoom;
  final Color textColor;

  /// لون رقم الآية وإطاره، من لون الثيم.
  final Color numberColor;

  /// لون علامة رقم الآية على الآيات التي عليها فاصل أو خاطرة أو تدبر.
  final Color markerColor;

  /// خلفية الآية (تحديد أو تظليل)، أو null.
  final Color? Function(int surah, int ayah) backgroundFor;

  /// أيقونات ما على الآية (فاصل، خاطرة، تدبر، حفظ) بألوانها؛ فارغة إن لم يكن
  /// عليها شيء.
  final List<(IconData, Color)> Function(int surah, int ayah) markersFor;

  final GestureRecognizer Function(Ayah ayah) recognizerFor;

  /// يظهر حتى يجهز التخطيط، أو إن خلا من الصفحة.
  final Widget fallback;

  /// البسملة بنص Digital Khatt، بترتيب علاماته كما في مصدره (الشدة قبل الفتحة).
  static const digitalKhattBasmala =
      '\u0628\u0650\u0633\u0652\u0645\u0650 '
      '\u0671\u0644\u0644\u0651\u064E\u0647\u0650 '
      '\u0671\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0670\u0646\u0650 '
      '\u0671\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650';

  /// عائلة خط Digital Khatt في pubspec.
  static const digitalKhattFamily = 'DigitalKhatt';

  /// خط المصحف المعروض، لنصوص تُكتب به كالأذكار والأدعية: Digital Khatt مع
  /// مصحف المدينة، وإلا الخط الذي اختاره القارئ للنص المتدفق.
  static String get scriptFamily {
    final store = UserDataStore.instance;
    return store.settings.mushafStyle == MushafStyle.madinah
        ? digitalKhattFamily
        : store.quranFontFamily;
  }

  /// نمط نص بخط المصحف المعروض ([scriptFamily]). مسافة Digital Khatt ضيقة
  /// تُوسَّع بالتطويل في الصفحة، فتُوسَّع هنا بنفسها، وما ليس فيه من علامات
  /// الترقيم (، .) يُرسم بخط أميري.
  static TextStyle scriptStyle({
    required double fontSize,
    double? height,
    Color? color,
    FontWeight? fontWeight,
  }) {
    final family = scriptFamily;
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: const ['Amiri'],
      fontSize: fontSize,
      height: height,
      color: color,
      fontWeight: fontWeight,
      wordSpacing: family == digitalKhattFamily ? fontSize * 0.3 : null,
    );
  }

  const QcfPageBody({
    super.key,
    required this.pageNumber,
    required this.zoom,
    required this.textColor,
    required this.numberColor,
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

  /// أعرض سطر في الصفحة العادية بحجم [_probe] (الوسيط عبر المصحف): كل الصفحات
  /// بحجم واحد يملأ به هذا السطر العرض.
  static const _typicalWidest = 1723.0;

  /// كم يُضغط السطر أفقياً قبل أن تصغر الصفحة كلها.
  static const _squeeze = 1.08;

  /// نصيب الكشيدة من نقص السطر؛ والباقي تباعد بين الكلمات.
  static const _kashidaShare = 0.7;

  static const _family = QcfPageBody.digitalKhattFamily;

  late Future<void> _ready;

  QcfLayout get _layout => QcfLayout.instance;

  /// مدّ كل سطر بحسب رقمه وحجم الخط وعرض الصفحة.
  final Map<(int, double, double), _LineFit> _fits = {};

  /// عرض حرف التطويل بكل حجم خط.
  final Map<double, double> _tatweelWidths = {};

  @override
  void dispose() {
    SemanticsBinding.instance.removeSemanticsEnabledListener(_onSemantics);
    super.dispose();
  }

  void _onSemantics() {
    if (mounted) setState(() {});
  }

  /// أعرض سطر في كل صفحة بحجم [_probe]؛ لا يتغير، فيبقى عند الرجوع إليها.
  static final Map<int, double> _widestLines = {};

  @override
  void initState() {
    super.initState();
    SemanticsBinding.instance.addSemanticsEnabledListener(_onSemantics);
    _ready = _layout.init();
  }

  @override
  void didUpdateWidget(QcfPageBody old) {
    super.didUpdateWidget(old);
    if (old.pageNumber != widget.pageNumber) _fits.clear();
  }

  /// أعرض سطر في الصفحة بحجم [_probe].
  double _measure(List<QcfLine> lines) {
    final known = _widestLines[widget.pageNumber];
    if (known != null) return known;
    var widest = 1.0;
    for (final line in lines) {
      if (line.kind != QcfLineKind.words) continue;
      widest = math.max(
        widest,
        _textWidth(line.words.map((w) => w.code).join(' '), _probe),
      );
    }
    return _widestLines[widget.pageNumber] = widest;
  }

  @override
  Widget build(BuildContext context) {
    if (_layout.isReady) return _page(context);
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) return _page(context);
        // فارغة لحظة فك التخطيط، فلا تومض الصفحة بخط النص العادي.
        return const SizedBox.expand();
      },
    );
  }

  Widget _page(BuildContext context) {
    final lines = _layout.page(widget.pageNumber);
    if (lines.isEmpty) return widget.fallback;
    final widest = _measure(lines);
    return LayoutBuilder(
      builder: (context, box) {
        // حجم واحد لكل الصفحات؛ والصفحة ذات السطر الأعرض تُضغط أسطرها قليلاً،
        // ولا تصغر إلا إن زاد الضغط على [_squeeze].
        final fit = math.min(
          math.min(
            _probe * box.maxWidth / _typicalWidest,
            _probe * box.maxWidth / widest * _squeeze,
          ),
          box.maxHeight / (lines.length * _lineHeight),
        );
        if (widget.zoom <= 1.0) {
          return _printed(lines, fit * widget.zoom, box);
        }
        return _flowing(lines, fit * widget.zoom);
      },
    );
  }

  /// الصفحة كالمطبوع: كل سطر وحده، في الوسط، بتباعد متساوٍ.
  Widget _printed(List<QcfLine> lines, double size, BoxConstraints box) {
    // أسطر الصفحة العادية الـ١٥ تتوزع لتملأها؛ أما أسطر صفحتي البداية القليلة
    // فتحتفظ بارتفاعها وتتجمع في الوسط كالمطبوع.
    final slot = lines.length < 15
        ? size * _lineHeight
        : math.min(
            math.max(size * _lineHeight, box.maxHeight / lines.length),
            size * _lineHeight * 1.25,
          );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, line) in lines.indexed)
          SizedBox(
            height: slot,
            child: Center(
              child: line.kind == QcfLineKind.words
                  ? _justified(i, line, size, box.maxWidth)
                  : _line(line, size),
            ),
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

  /// سطر عنوان السورة أو البسملة.
  Widget _line(QcfLine line, double size) {
    if (line.kind == QcfLineKind.surahHeader) {
      // تملأ السطر، والترويسة تتحجّم بارتفاعه.
      return SurahHeaderBanner(
        surah: QuranRepository.instance.getSurah(line.surah),
      );
    }
    return Text(
      QcfPageBody.digitalKhattBasmala,
      semanticsLabel: QuranRepository.instance.getAyah(1, 1)?.text,
      maxLines: 1,
      softWrap: false,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: _family,
        fontSize: size,
        height: _lineHeight,
        color: widget.textColor,
      ),
    );
  }

  /// سطر Digital Khatt رقم [index] يملأ [width]: كشيدة لأغلب نقصه وتباعد للباقي،
  /// أو ضغط أفقي خفيف إن زاد. وآخر سطر في السورة يبقى في الوسط كالمطبوع.
  Widget _justified(int index, QcfLine line, double size, double width) {
    final fit = _fits[(index, size, width)] ??= _fitLine(
      index,
      line,
      size,
      width,
    );
    final text = Text.rich(
      _spans(line.words, size, fit: fit),
      maxLines: 1,
      softWrap: false,
      textDirection: TextDirection.rtl,
    );
    // يُرصف السطر بعرضه كاملاً ثم يُضغط، فلا يُقص طرفه؛ والقياس قد يخطئ بنقطة.
    final unclipped = OverflowBox(maxWidth: double.infinity, child: text);
    if (fit.squeeze >= 1) return unclipped;
    return Transform.scale(scaleX: fit.squeeze, child: unclipped);
  }

  _LineFit _fitLine(int index, QcfLine line, double size, double width) {
    // النص المرسوم لا ما يقرؤه قارئ الشاشة، فلكل آية تسمية منطوقة.
    double measure(_LineFit fit) => _textWidth(
      _spans(
        line.words,
        size,
        fit: fit,
      ).toPlainText(includeSemanticsLabels: false, includePlaceholders: false),
      size,
    );
    final natural = measure(_LineFit.centred);
    if (natural >= width) return _LineFit(const {}, 0, width / natural);
    if (widget.pageNumber <= 2 || _endsSurah(index)) return _LineFit.centred;
    final codes = [for (final w in line.words) w.code];
    final gaps = codes.length - 1;
    final tatweelWidth = _tatweelWidths[size] ??=
        (_textWidth('ب${tatweel * 10}ب', size) - _textWidth('بب', size)) / 10;
    var count = ((width - natural) * _kashidaShare / tatweelWidth).floor();
    while (true) {
      final stretched = stretchWords(codes, count);
      final fit = _LineFit(
        {
          for (final (i, w) in line.words.indexed)
            if (stretched[i] != w.code) w: stretched[i],
        },
        0,
        1,
      );
      final used = measure(fit);
      // الكشيدة تغيّر أشكال الحروف قليلاً، فقد تزيد على المحسوب.
      if (used <= width || count == 0) {
        final spacing = gaps > 0 ? math.max(0.0, (width - used) / gaps) : 0.0;
        return _LineFit(fit.stretched, spacing, 1);
      }
      count = count * 3 ~/ 4;
    }
  }

  /// هل سطر الكلمات [index] آخر سطر في سورته: يليه عنوان سورة، أو هو آخر
  /// الصفحة والتالية تبدأ بعنوان، أو آخر المصحف.
  bool _endsSurah(int index) {
    final lines = _layout.page(widget.pageNumber);
    if (index + 1 < lines.length) {
      return lines[index + 1].kind == QcfLineKind.surahHeader;
    }
    final next = _layout.page(widget.pageNumber + 1);
    return next.isEmpty || next.first.kind == QcfLineKind.surahHeader;
  }

  double _textWidth(String text, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _family,
          fontSize: size,
          height: _lineHeight,
        ),
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// نص كلمات [run] من [ayah]: الرموز لا تعني شيئاً لقارئ الشاشة.
  ///
  /// علامات الوقف المنفصلة لا تقابلها كلمة في تخطيط الصفحة. وإن اختلف العددان
  /// قُرئت الآية كاملة عند أول أجزائها.
  String? _spokenWords(Ayah ayah, List<QcfWord> run) {
    final layout = [
      for (final line in _layout.page(widget.pageNumber))
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
  ///
  /// [fit] يمدّ سطر Digital Khatt: كلماته بالكشيدة وتباعده، دون فراغ في آخره.
  TextSpan _spans(List<QcfWord> words, double size, {_LineFit? fit}) {
    final runs = <InlineSpan>[];
    String codeOf(QcfWord w) => fit?.stretched[w] ?? w.code;
    // الفراغ بعد آخر كلمة يزيح السطر الممدود عن حافته.
    String after(QcfWord w) =>
        fit != null && identical(w, words.last) ? '' : ' ';
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
          end = codeOf(words[i]);
        } else {
          text.write('${codeOf(words[i])}${after(words[i])}');
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
            // مكلف، فلا يُحسب إلا إن كان هناك من يقرؤه.
            semanticsLabel:
                ayah == null || !SemanticsBinding.instance.semanticsEnabled
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
              color: markers.isEmpty ? widget.numberColor : widget.markerColor,
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
        if (after(words[i - 1]).isNotEmpty) {
          runs.add(
            TextSpan(
              text: ' ',
              recognizer: recognizer,
              style: TextStyle(backgroundColor: background),
            ),
          );
        }
      }
    }
    return TextSpan(
      style: TextStyle(
        fontFamily: _family,
        fontSize: size,
        height: _lineHeight,
        wordSpacing: fit?.spacing ?? 0,
        color: widget.textColor,
      ),
      children: runs,
    );
  }
}

/// كيف يُمدّ سطر Digital Khatt ليملأ عرض الصفحة.
class _LineFit {
  /// نص الكلمات التي دخلتها الكشيدة.
  final Map<QcfWord, String> stretched;

  /// التباعد المضاف بين الكلمات.
  final double spacing;

  /// الضغط الأفقي للسطر الأعرض من الصفحة؛ 1 بلا ضغط.
  final double squeeze;

  const _LineFit(this.stretched, this.spacing, this.squeeze);

  static const centred = _LineFit({}, 0, 1);
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
