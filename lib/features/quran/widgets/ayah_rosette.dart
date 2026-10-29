import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/ornaments.dart';
import '../../../core/motion/app_motion.dart';
import '../../../data/storage/user_data_store.dart';
import '../../ayah_links/widgets/ayah_link_picker_dialog.dart';
import '../../memorization/memorization_model.dart';
import '../../share/ayah_share_sheet.dart';
import '../../audio/quran_audio.dart';
import '../../tadbeer/tadbeer_pause_sheet.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/quran/quran_repository.dart';
import '../qcf/qcf_ayah_text.dart';
import 'ayah_action_sheet.dart';

/// الوردة الثمانية: إجراءات الآية تتفتح حول الإصبع على هيئة نجمة ثمانية.
///
/// الضغط المطوّل يفتحها تحت الإصبع؛ ودون رفعه ينزلق القارئ نحو إجراء (يظهر اسمه
/// في الوسط مع اهتزاز خفيف) ثم يرفع لينفّذه، والوسط هو التدبر. والرفع قبل
/// الاختيار يُبقيها مفتوحة بأسماء كل الإجراءات للنقر. حول الوسط ثمانية أماكن،
/// فيتسع المكان الفارغ لإجراء آخر. ومع قارئ الشاشة تُفتح نافذة الإجراءات
/// العادية بدلها.
///
/// هي طبقة فوق الشاشة لا مسار (route): فتح مسار يلغي اللمسات الحالية، فينهي
/// الضغطة التي توجّهها.
abstract final class AyahRosette {
  static _RosetteState? _open;

  /// يفتح الوردة للآية عند [at] (موضع الإصبع)، أو في وسط الشاشة، وينتهي عند
  /// إغلاقها.
  static Future<void> show(BuildContext context, Ayah ayah, {Offset? at}) {
    if (MediaQuery.accessibleNavigationOf(context)) {
      return AyahActionSheet.show(context, ayah);
    }
    _open?._dismiss();
    final closed = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      // الطبقة الجذرية فوق أي Material، والنص يحتاج Material.
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: _Rosette(
          ayah: ayah,
          anchor: at,
          dragging: at != null,
          host: context,
          onClosed: () {
            if (entry.mounted) entry.remove();
            if (!closed.isCompleted) closed.complete();
          },
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return closed.future;
  }

  /// يطوي الوردة إن كانت مفتوحة، ويعيد true حينها؛ لمعالج رجوع يسبق معالجها،
  /// كعودة الهيكل إلى الرئيسية.
  static bool dismissIfOpen() {
    final open = _open;
    if (open == null) return false;
    open._dismiss();
    return true;
  }

  /// يتابع حركة الإصبع الذي فتح الوردة.
  static void dragTo(Offset global) => _open?._dragTo(global);

  /// رفع الإصبع: ينفّذ الإجراء الذي تحته، أو يُبقي الوردة مفتوحة للنقر.
  static void releaseAt(Offset global) => _open?._releaseAt(global);
}

/// إجراء حول الوردة.
class _Petal {
  final IconData icon;
  final String label;

  /// يدل على شيء موجود على الآية، كخاطرة.
  final bool active;
  final Color? tint;
  final VoidCallback run;

  const _Petal({
    required this.icon,
    required this.label,
    required this.run,
    this.active = false,
    this.tint,
  });
}

class _Rosette extends StatefulWidget {
  final Ayah ayah;
  final Offset? anchor;
  final bool dragging;

  /// الشاشة التي فتحت الوردة، وهي التي تنفّذ الإجراء المختار.
  final BuildContext host;

  /// يزيل الوردة بعد إغلاقها.
  final VoidCallback onClosed;

  const _Rosette({
    required this.ayah,
    required this.anchor,
    required this.dragging,
    required this.host,
    required this.onClosed,
  });

  @override
  State<_Rosette> createState() => _RosetteState();
}

class _RosetteState extends State<_Rosette>
    with SingleTickerProviderStateMixin {
  static const _places = 8;
  static const _ring = 98.0;
  static const _petalSize = 52.0;
  static const _heartSize = 82.0;

  /// نصف قطر القرص الذي تقوم عليه الإجراءات.
  static const _medallion = _ring + 54;

  /// المساحة التي تحتاجها الوردة حول مركزها.
  static const _reach = _medallion + 6;

  /// أقل ارتفاع يبقى للآية فوق القرص.
  static const _minCardHeight = 140.0;

  /// الوسط رقمه -1، والإجراءات 0..7 مع عقارب الساعة من الأعلى.
  static const _heart = -1;

  late bool _dragging = widget.dragging;

  /// هل ابتعد الإصبع عن موضع الضغط، فلا يختار الرفع في المكان نفسه شيئاً ولو
  /// فُتحت الوردة بعيداً عن الوسط.
  bool _moved = false;
  LocalHistoryEntry? _back;
  bool _closing = false;
  int? _hovered;
  Offset _centre = Offset.zero;

  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 160),
  );

  @override
  void initState() {
    super.initState();
    AyahRosette._open = this;
    // زر الرجوع يُغلق الوردة قبل الشاشة تحتها.
    _back = LocalHistoryEntry(onRemove: _dismiss);
    ModalRoute.of(widget.host)?.addLocalHistoryEntry(_back!);
    _bloom.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.shouldAnimate(context)) _bloom.value = 1;
  }

  @override
  void dispose() {
    if (AyahRosette._open == this) AyahRosette._open = null;
    _bloom.dispose();
    super.dispose();
  }

  /// ينهي حجز زر الرجوع حين تذهب الوردة.
  void _releaseBack() {
    final back = _back;
    _back = null;
    back?.remove();
  }

  /// يطوي الوردة دون تنفيذ شيء.
  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _releaseBack();
    if (AyahRosette._open == this) AyahRosette._open = null;
    if (AppMotion.shouldAnimate(context)) await _bloom.reverse();
    widget.onClosed();
  }

  Ayah get _ayah => widget.ayah;

  List<_Petal?> _petals(AppStrings l10n) {
    final store = UserDataStore.instance;
    final s = _ayah.surahNumber, a = _ayah.ayahNumber;
    final bookmarked = store.isBookmarked(s, a);
    final highlight = store.getHighlight(s, a);
    final inHifz = HifzStore.contains(s, a);
    final host = widget.host;
    return [
      _Petal(
        icon: AppIcons.notePencil,
        label: l10n.addNote,
        active: store.getNotesForAyah(s, a).isNotEmpty,
        run: () => AyahActionSheet.show(host, _ayah, mode: AyahSheetMode.note),
      ),
      _Petal(
        icon: AppIcons.graphFill,
        label: l10n.ayahLink,
        run: () => AyahLinkPickerDialog.show(host, _ayah),
      ),
      _Petal(
        icon: bookmarked
            ? AppIcons.bookmarkSimpleFill
            : AppIcons.bookmarkSimple,
        label: bookmarked ? l10n.unmarkAyah : l10n.markAyah,
        active: bookmarked,
        run: () => store.toggleBookmark(_ayah),
      ),
      _Petal(
        icon: AppIcons.highlighterCircle,
        label: l10n.highlight,
        tint: highlight == null
            ? null
            : AppColors.highlightColors[highlight.colorIndex],
        run: () =>
            AyahActionSheet.show(host, _ayah, mode: AyahSheetMode.highlight),
      ),
      _Petal(
        icon: inHifz ? AppIcons.brainFill : AppIcons.brain,
        label: inHifz ? l10n.memorizedDone : l10n.addToMemorization,
        active: inHifz,
        run: () => HifzStore.toggle(s, a),
      ),
      _Petal(
        icon: AppIcons.export,
        label: l10n.share,
        run: () => AyahShareSheet.show(host, _ayah),
      ),
      _Petal(
        icon: AppIcons.copy,
        label: l10n.copy,
        run: () {
          final surah = QuranRepository.instance.getSurah(s);
          Clipboard.setData(
            ClipboardData(text: '﴿${_ayah.text}﴾ [سورة ${surah.name}: $a]'),
          );
          ScaffoldMessenger.maybeOf(host)?.showSnackBar(
            SnackBar(
              content: Text(
                l10n.copiedToClipboard,
                textAlign: TextAlign.center,
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      _Petal(
        icon: AppIcons.headphones,
        label: l10n.listen,
        active: QuranAudio.instance.current?.id == _ayah.id,
        run: () => QuranAudio.instance.playAyah(_ayah),
      ),
    ];
  }

  void _reflect() => TadbeerPauseSheet.show(widget.host, _ayah);

  /// ما تحت [global]: الوسط، أو إجراء، أو لا شيء.
  int? _hitTest(Offset global) {
    final d = global - _centre;
    final distance = d.distance;
    if (distance <= _heartSize / 2 + 6) return _heart;
    if (distance < _heartSize / 2 + 10 || distance > _ring + _petalSize) {
      return null;
    }
    // مع عقارب الساعة من الأعلى.
    final angle = math.atan2(d.dx, -d.dy);
    return (angle / (2 * math.pi / _places)).round() % _places;
  }

  void _dragTo(Offset global) {
    if (!_dragging || !mounted) return;
    final start = widget.anchor ?? _centre;
    if (!_moved && (global - start).distance > 18) _moved = true;
    var hit = _moved ? _hitTest(global) : null;
    if (hit != null && hit >= 0 && _petals(context.l10n)[hit] == null) {
      hit = null;
    }
    if (hit != _hovered) {
      if (hit != null) HapticFeedback.selectionClick();
      setState(() => _hovered = hit);
    }
  }

  void _releaseAt(Offset global) {
    if (!_dragging || !mounted) return;
    _dragTo(global);
    final chosen = _hovered;
    if (chosen == null) {
      // رُفع دون اختيار: تبقى مفتوحة بأسماء كل الإجراءات.
      setState(() => _dragging = false);
      return;
    }
    _run(chosen);
  }

  void _run(int index) {
    if (_closing) return;
    _closing = true;
    HapticFeedback.lightImpact();
    final action = index == _heart
        ? _reflect
        : _petals(context.l10n)[index]!.run;
    // تختفي فوراً، فلا تغطي ما يفتحه الإجراء.
    _releaseBack();
    if (AyahRosette._open == this) AyahRosette._open = null;
    widget.onClosed();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final petals = _petals(l10n);

    // دائماً في نفس المكان: في الوسط، في أسفل الشاشة في متناول الإبهام مع
    // ابتعاد عن حافتها، وفوقها مساحة للآية.
    final cardTop = padding.top + 12;
    final lowest = size.height - padding.bottom - _reach - 12;
    _centre = Offset(
      size.width / 2,
      math.max(
        math.min(size.height * 0.7, lowest),
        cardTop + _minCardHeight + 12 + _reach,
      ),
    );
    // الآية فوق القرص مباشرة وتمتد للأعلى إن طالت، فيُقرآن معاً مهما قصرت
    // الآية.
    final cardBottom = _centre.dy - _medallion - 14;
    final cardMaxHeight = cardBottom - cardTop;

    final p = ThemePalette.of(AppColors.theme);
    final night = isDark
        ? [p.heroDarkStart, p.heroDarkEnd]
        : [p.heroLightStart, p.heroLightEnd];
    final bloom = CurvedAnimation(parent: _bloom, curve: Curves.easeOutCubic);
    final hasReflection =
        UserDataStore.instance.getTadbeer(
          _ayah.surahNumber,
          _ayah.ayahNumber,
        ) !=
        null;
    final heartLabel = switch (_hovered) {
      null ||
      _heart => hasReflection ? l10n.continueReflection : l10n.tadbeerPause,
      final i => petals[i]!.label,
    };
    final surah = QuranRepository.instance.getSurah(_ayah.surahNumber);

    Offset placeOf(int i) {
      final angle = i * 2 * math.pi / _places;
      return Offset(math.sin(angle), -math.cos(angle)) * _ring;
    }

    return AnimatedBuilder(
      animation: bloom,
      builder: (context, _) {
        final t = bloom.value;
        return Stack(
          children: [
            // الصفحة تبقى ظاهرة وتخفت قليلاً فقط، لتتميز الآية دون إخفاء
            // الباقي؛ والنقر عليها يُغلق.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.2 * t, sigmaY: 1.2 * t),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.16 * t),
                  ),
                ),
              ),
            ),
            // الآية وحدها، كما في الصفحة.
            Positioned(
              bottom: size.height - cardBottom,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - t)),
                  child: Center(
                    child: _IsolatedAyah(
                      ayah: _ayah,
                      reference: l10n.ayahReference(
                        surah.name,
                        _ayah.ayahNumber,
                      ),
                      palette: MushafPalette.of(
                        isDark: isDark,
                        tone: UserDataStore.instance.settings.mushafPaperTone,
                      ),
                      maxHeight: cardMaxHeight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _centre.dx - _reach,
              top: _centre.dy - _reach,
              width: _reach * 2,
              height: _reach * 2,
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.86 + 0.14 * t,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // القرص، ونجمته تدور إلى مكانها.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _MedallionPainter(
                              colours: night,
                              turn: (1 - t) * -math.pi / 8,
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < _places; i++)
                        _at(
                          Offset(_reach, _reach) + placeOf(i) * t,
                          switch (petals[i]) {
                            final petal? => _PetalView(
                              petal: petal,
                              hovered: _hovered == i,
                              showLabel: !_dragging,
                              onTap: _dragging ? null : () => _run(i),
                            ),
                            null => const IgnorePointer(
                              child: CustomPaint(
                                size: Size.square(14),
                                painter: _SparkPainter(),
                              ),
                            ),
                          },
                        ),
                      _at(
                        Offset(_reach, _reach),
                        _Heart(
                          label: heartLabel,
                          icon: switch (_hovered) {
                            null || _heart => AppIcons.flowerLotusFill,
                            final i => petals[i]!.icon,
                          },
                          hovered: _hovered == _heart,
                          onTap: _dragging ? null : () => _run(_heart),
                          ink: p.lightPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// [child] متمركزاً على [centre]؛ واسم الإجراء معلّق تحته.
  Widget _at(Offset centre, Widget child) {
    const width = 96.0;
    return Positioned(
      left: centre.dx - width / 2,
      top: centre.dy - _petalSize / 2,
      width: width,
      child: Align(alignment: Alignment.topCenter, child: child),
    );
  }
}

/// ذهبي القرص وقشديّه، نفسهما في الوضعين.
const _gold = Color(0xFFD9B566);
const _cream = Color(0xFFF2EEE4);
const _onGold = Color(0xFF1A1405);
const _paper = Color(0xFFF7F1E3);

/// التدبر في قلب القرص؛ وأثناء انزلاق الإصبع يُظهر اسم الإجراء الذي تحته.
class _Heart extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hovered;
  final VoidCallback? onTap;

  /// اللون الداكن للثيم، للزهرة واسمها على الورق.
  final Color ink;

  const _Heart({
    required this.label,
    required this.icon,
    required this.hovered,
    required this.onTap,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    const size = _RosetteState._heartSize;
    return Transform.translate(
      // في وسط القرص لا معلّقاً من أعلاه.
      offset: const Offset(0, (_RosetteState._petalSize - size) / 2),
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: hovered ? 1.07 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                // ورق المصحف في حلقة ذهبية، كالآية أعلاه.
                color: _paper,
                shape: BoxShape.circle,
                border: Border.all(color: _gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: hovered ? 0.6 : 0.25),
                    blurRadius: hovered ? 14 : 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: ink),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// إجراء على القرص: أيقونة قشدية تصير ذهبية تحت الإصبع، واسمها تحتها حين تستقر
/// الوردة.
class _PetalView extends StatelessWidget {
  final _Petal petal;
  final bool hovered;
  final bool showLabel;
  final VoidCallback? onTap;

  const _PetalView({
    required this.petal,
    required this.hovered,
    required this.showLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = _RosetteState._petalSize;
    final iconColour = hovered
        ? _onGold
        : petal.tint ?? (petal.active ? _gold : _cream);
    return Semantics(
      button: true,
      label: petal.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: size,
              height: size,
              transform: Matrix4.diagonal3Values(
                hovered ? 1.14 : 1,
                hovered ? 1.14 : 1,
                1,
              ),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: hovered ? _gold : _cream.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hovered ? _gold : _gold.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(petal.icon, size: 24, color: iconColour),
                  // على الآية شيء من هذا النوع.
                  if ((petal.active || petal.tint != null) && !hovered)
                    Positioned(
                      bottom: 7,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: petal.tint ?? _gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: showLabel ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  petal.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: _cream.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الآية المختارة وحدها على قطعة من ورق المصحف: مرجعها فوقها، وهي بخط المدينة
/// (أو بخط القارئ في النص المتدفق)، وتُمرّر إن طالت.
class _IsolatedAyah extends StatelessWidget {
  final Ayah ayah;
  final String reference;
  final MushafPalette palette;
  final double maxHeight;

  const _IsolatedAyah({
    required this.ayah,
    required this.reference,
    required this.palette,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final store = UserDataStore.instance;
    final plain = Text(
      '﴿ ${ayah.text} ﴾',
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: store.quranFontFamily,
        fontSize: 20,
        height: 1.9,
        color: palette.text,
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.page,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.frame.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('❖', style: TextStyle(fontSize: 9, color: _gold)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      reference,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: palette.frame,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('❖', style: TextStyle(fontSize: 9, color: _gold)),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: SingleChildScrollView(
                  child: store.settings.mushafStyle == MushafStyle.madinah
                      ? QcfAyahText(
                          ayah: ayah,
                          fontSize: 24,
                          color: palette.text,
                          fallback: plain,
                        )
                      : plain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// القرص: دائرة بألوان الثيم تحت ظل خفيف، بإطار ذهبي مزدوج ونجمة ثمانية خافتة
/// وحبات ذهبية بين الإجراءات.
class _MedallionPainter extends CustomPainter {
  final List<Color> colours;

  /// كم بقي للنجمة لتدور إلى مكانها.
  final double turn;

  const _MedallionPainter({required this.colours, required this.turn});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = _RosetteState._medallion;
    const ring = _RosetteState._ring;

    canvas.drawCircle(
      c + const Offset(0, 6),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.9,
          colors: colours,
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..color = _gold
      ..strokeWidth = 1.6;
    canvas.drawCircle(c, r - 5, rim);
    canvas.drawCircle(
      c,
      r - 9,
      rim
        ..strokeWidth = 0.7
        ..color = _gold.withValues(alpha: 0.55),
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    // الأرضية: نجوم وصلبان، نقش البلاط الكلاسيكي، خافت وداخل الحزام المفصّص.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: c, radius: r - 16)),
    );
    const step = 30.0;
    line.color = _gold.withValues(alpha: 0.13);
    for (var y = -r; y <= r; y += step) {
      for (var x = -r; x <= r; x += step) {
        canvas.drawPath(eightPointStar(c + Offset(x, y), step * 0.5), line);
      }
    }
    canvas.restore();

    // تفصيص داخل الإطار، كقنديل المصحف المذهّب.
    line
      ..color = _gold.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    const scallops = 48;
    final band = r - 13;
    final arc = math.pi * band / scallops;
    for (var i = 0; i < scallops; i++) {
      final a = i * 2 * math.pi / scallops;
      final at = c + Offset(math.sin(a), -math.cos(a)) * band;
      canvas.drawArc(
        Rect.fromCircle(center: at, radius: arc * 0.55),
        // النصف المواجه للمركز.
        a,
        math.pi,
        false,
        line,
      );
    }

    // الشمسة: شمس بست عشرة شعلة حول القلب، تدور إلى مكانها عند فتح القرص.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(turn);
    final sun = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = _gold.withValues(alpha: 0.42);
    for (final spin in [0.0, math.pi / 8]) {
      canvas.save();
      canvas.rotate(spin);
      canvas.drawPath(eightPointStar(Offset.zero, ring * 0.64), sun);
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      ring * 0.5,
      sun..color = _gold.withValues(alpha: 0.3),
    );
    canvas.restore();

    final bead = Paint()..color = _gold.withValues(alpha: 0.7);
    for (var i = 0; i < _RosetteState._places; i++) {
      final a = (i + 0.5) * 2 * math.pi / _RosetteState._places;
      canvas.drawCircle(
        c + Offset(math.sin(a), -math.cos(a)) * ring,
        1.6,
        bead,
      );
    }
  }

  @override
  bool shouldRepaint(_MedallionPainter old) =>
      old.turn != turn ||
      old.colours.first != colours.first ||
      old.colours.last != colours.last;
}

/// نجمة ذهبية صغيرة في المكان الفارغ.
class _SparkPainter extends CustomPainter {
  const _SparkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      eightPointStar(size.center(Offset.zero), size.width / 2),
      Paint()..color = _gold.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}
