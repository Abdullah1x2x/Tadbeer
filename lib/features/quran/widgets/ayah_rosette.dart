import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/ornaments.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/storage/user_data_store.dart';
import '../../ayah_links/widgets/ayah_link_picker_dialog.dart';
import '../../memorization/memorization_model.dart';
import '../../share/ayah_share_sheet.dart';
import '../../tadbeer/tadbeer_pause_sheet.dart';
import '../data/quran_models.dart';
import '../data/quran_repository.dart';
import 'ayah_action_sheet.dart';

/// الوردة الثمانية: إجراءات الآية تتفتح حول الإصبع على هيئة نجمة ثمانية.
///
/// A long press opens it under the finger. Without lifting, the reader
/// slides toward an action (its name shows in the centre, with a tick of
/// haptics) and lifts to run it; the centre is the reflection. Lifting
/// before choosing leaves the rosette open with every action named, to tap.
/// Eight places surround the centre, so one more action fits in the empty
/// one. With a screen reader the plain action sheet opens instead.
///
/// It is an overlay rather than a route: pushing a route cancels the
/// pointers on screen, which would end the very press that steers it.
abstract final class AyahRosette {
  static _RosetteState? _open;

  /// يفتح الوردة للآية عند [at] (موضع الإصبع)، أو وسط الشاشة، وينتهي
  /// عند إغلاقها.
  static Future<void> show(BuildContext context, Ayah ayah, {Offset? at}) {
    if (MediaQuery.accessibleNavigationOf(context)) {
      return AyahActionSheet.show(context, ayah);
    }
    _open?._dismiss();
    final closed = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      // The root overlay sits above any Material, which text needs.
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

  /// يطوي الوردة إن كانت مفتوحة، ويعيد true حينها.
  ///
  /// For a back handler that runs before the rosette's own, such as the
  /// shell's return to Home.
  static bool dismissIfOpen() {
    final open = _open;
    if (open == null) return false;
    open._dismiss();
    return true;
  }

  /// يتابع حركة الإصبع الذي فتح الوردة.
  static void dragTo(Offset global) => _open?._dragTo(global);

  /// يرفع الإصبع: ينفذ الإجراء الذي تحته، أو يبقي الوردة مفتوحة للنقر.
  static void releaseAt(Offset global) => _open?._releaseAt(global);
}

/// One action around the rosette.
class _Petal {
  final IconData icon;
  final String label;

  /// Marks something the ayah already has, such as a note.
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

  /// The screen that opened the rosette, which runs the chosen action.
  final BuildContext host;

  /// Removes the rosette once it has closed.
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

  /// Radius of the medallion the petals sit on.
  static const _medallion = _ring + 54;

  /// Room the rosette needs around its centre.
  static const _reach = _medallion + 6;

  /// The heart is index -1; petals are 0 to 7, clockwise from the top.
  static const _heart = -1;

  late bool _dragging = widget.dragging;

  /// Whether the finger has left where it pressed, so lifting it in place
  /// chooses nothing even when the rosette had to open off-centre.
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
    // The back button takes the rosette away before the screen under it.
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

  /// Ends the back button's hold, once the rosette goes.
  void _releaseBack() {
    final back = _back;
    _back = null;
    back?.remove();
  }

  /// Folds the rosette away without doing anything.
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
        label: inHifz ? l10n.removeFromMemorization : l10n.addToMemorization,
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
      // Kept for the next action.
      null,
    ];
  }

  void _reflect() => TadbeerPauseSheet.show(widget.host, _ayah);

  /// What lies under [global]: the heart, a petal, or nothing.
  int? _hitTest(Offset global) {
    final d = global - _centre;
    final distance = d.distance;
    if (distance <= _heartSize / 2 + 6) return _heart;
    if (distance < _heartSize / 2 + 10 || distance > _ring + _petalSize) {
      return null;
    }
    // Clockwise from the top.
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
      // Lifted without choosing: stay open, with every action named.
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
    // Gone at once, so what the action opens is not covered.
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

    // Under the finger, kept whole on screen with the reference above it.
    final want = widget.anchor ?? size.center(Offset.zero);
    final minX = math.min(_reach + 4, size.width / 2);
    final minY = padding.top + _reach + 44;
    _centre = Offset(
      want.dx.clamp(minX, size.width - minX),
      want.dy.clamp(
        math.min(minY, size.height / 2),
        math.max(size.height - padding.bottom - _reach, size.height / 2),
      ),
    );

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
            // The page softens behind; a tap on it closes the rosette.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 3 * t, sigmaY: 3 * t),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.32 * t),
                  ),
                ),
              ),
            ),
            if (!_dragging)
              Positioned(
                left: 0,
                right: 0,
                top: _centre.dy - _medallion - 40,
                child: Center(
                  child: _Plate(
                    text: l10n.ayahReference(surah.name, _ayah.ayahNumber),
                    colour: night.last,
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
                      // The medallion, its star turning into place.
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

  /// [child] centred on [centre]; a petal's label hangs below it.
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

/// The medallion's gold and cream, the same in light and dark.
const _gold = Color(0xFFD9B566);
const _cream = Color(0xFFF2EEE4);
const _onGold = Color(0xFF1A1405);

/// The reflection at the heart of the medallion; while the finger slides
/// it names the action under it.
class _Heart extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hovered;
  final VoidCallback? onTap;

  const _Heart({
    required this.label,
    required this.icon,
    required this.hovered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = _RosetteState._heartSize;
    return Transform.translate(
      // Centred on the medallion rather than hung from its top.
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
                color: _gold,
                shape: BoxShape.circle,
                border: Border.all(color: _cream.withValues(alpha: 0.9)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: _onGold),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: _onGold,
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

/// An action on the medallion: a cream icon that turns gold under the
/// finger, its name below once the rosette settles.
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
                  // Something of this kind is already on the ayah.
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

/// The ayah's reference on a dark plate above the medallion.
class _Plate extends StatelessWidget {
  final String text;
  final Color colour;

  const _Plate({required this.text, required this.colour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: _cream,
        ),
      ),
    );
  }
}

/// The medallion: a disc in the theme's colours under a soft shadow, a
/// double gold rim, a faint eight-pointed star and gold beads between the
/// petals.
class _MedallionPainter extends CustomPainter {
  final List<Color> colours;

  /// How far the star still has to turn into place.
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

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(turn);
    canvas.drawPath(
      eightPointStar(Offset.zero, ring * 0.66),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = _gold.withValues(alpha: 0.28),
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

/// A small gold star keeping the empty place.
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
