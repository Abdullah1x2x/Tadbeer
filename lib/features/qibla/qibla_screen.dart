import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/ornaments.dart';
import 'qibla.dart';
import 'qibla_location.dart';
import '../onboarding/tour/section_guide.dart';

/// اتجاه القبلة: بوصلة تدور مع الجهاز وعليها علامة الكعبة.
///
/// يُحسب الاتجاه من موقع القارئ، ويُحفظ الموقع فتجيب الشاشة فوراً في المرة
/// القادمة ولو دون اتصال. ودون مستشعر بوصلة يبقى الشمال أعلى، ويُذكر الاتجاه
/// بالدرجات.
class QiblaScreen extends StatefulWidget {
  /// مصدر الموقع؛ يُستبدل في الاختبارات.
  final QiblaLocator locator;

  /// اتجاهات البوصلة بالدرجات من الشمال؛ null لجهاز بلا بوصلة. الافتراضي بوصلة
  /// الجهاز.
  final Stream<double>? headings;

  /// هل مُرّرت [headings]؛ وإلا تُستخدم بوصلة الجهاز.
  final bool hasHeadings;

  const QiblaScreen({super.key, this.locator = const QiblaLocator()})
    : headings = null,
      hasHeadings = false;

  /// للاختبارات: مصدر موقع واتجاهات معطاة.
  const QiblaScreen.withSources({
    super.key,
    required this.locator,
    required this.headings,
  }) : hasHeadings = true;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  /// يُعدّ القارئ مستقبلاً القبلة ضمن هذه الدرجات.
  static const _aligned = 3.0;

  /// يجب أن يبتعد هذا القدر قبل أن يُعدّ قد انحرف، فلا يرتعش التأكيد عند الحد.
  static const _lost = 6.0;

  QiblaLocated? _location;
  QiblaFix? _problem;
  bool _locating = false;

  StreamSubscription<double>? _compass;
  Timer? _noCompassTimer;

  /// هل وصل اتجاه ولو مرة؛ وإلا تُعرض البوصلة والشمال أعلى.
  bool _hasCompass = false;

  /// زاوية البوصلة دون التفاف، فلا تدور الطريق الأطول أبداً.
  double _dial = 0;
  bool _facing = false;

  @override
  void initState() {
    super.initState();
    _location = widget.locator.saved();
    _listenToCompass();
    _locate();
  }

  @override
  void dispose() {
    _compass?.cancel();
    _noCompassTimer?.cancel();
    super.dispose();
  }

  void _listenToCompass() {
    final stream = widget.hasHeadings
        ? widget.headings
        : FlutterCompass.events
              ?.map((e) => e.heading)
              .where((h) => h != null)
              .cast<double>();
    if (stream == null) return;
    _compass = stream.listen(_onHeading, onError: (_) {});
  }

  void _onHeading(double heading) {
    if (!mounted) return;
    setState(() {
      _hasCompass = true;
      // تقترب من الاتجاه الجديد بأقصر دوران، وهذا يهدّئ ارتعاش المستشعر أيضاً.
      final current = _dial % 360;
      _dial += turnTo(heading, current) * 0.35;
      final location = _location;
      if (location != null) {
        final off = turnTo(
          qiblaBearing(location.latitude, location.longitude),
          _dial % 360,
        ).abs();
        final facing = _facing ? off <= _lost : off <= _aligned;
        if (facing && !_facing) HapticFeedback.mediumImpact();
        _facing = facing;
      }
    });
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final fix = await widget.locator.locate();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (fix is QiblaLocated) {
        _location = fix;
        _problem = null;
      } else {
        _problem = fix;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = _location;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.qibla),
          actions: [
            const GuideButton(topic: GuideTopic.qibla),
            IconButton(
              tooltip: l10n.qiblaUpdateLocation,
              onPressed: _locating ? null : _locate,
              icon: const Icon(AppIcons.crosshair),
            ),
          ],
        ),
        body: PatternBackground(
          child: SafeArea(
            child: location == null
                ? _NoLocation(
                    locating: _locating,
                    problem: _problem,
                    locator: widget.locator,
                    onRetry: _locate,
                  )
                : _buildQibla(context, location),
          ),
        ),
      ),
    );
  }

  Widget _buildQibla(BuildContext context, QiblaLocated location) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final bearing = qiblaBearing(location.latitude, location.longitude);
    final km = distanceToKaabaKm(location.latitude, location.longitude);
    final heading = _hasCompass ? _dial % 360 : 0.0;
    final turn = turnTo(bearing, heading);
    final String status;
    if (!_hasCompass) {
      status = l10n.qiblaNoCompass;
    } else if (_facing) {
      status = l10n.qiblaFacing;
    } else if (turn > 0) {
      status = l10n.qiblaTurnRight(turn.round());
    } else {
      status = l10n.qiblaTurnLeft(-turn.round());
    }

    return LayoutBuilder(
      builder: (context, box) {
        final dial = math.min(box.maxWidth - 48, 340.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // الدوران المطلوب، بالكلمات أيضاً لا بالرسم وحده.
            Semantics(
              liveRegion: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _facing
                      ? gold.withValues(alpha: 0.18)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _facing ? gold : AppColors.border(context),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _facing ? AppIcons.checkCircleFill : AppIcons.compass,
                      color: _facing ? gold : AppColors.primary(context),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: dial,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // البوصلة تدور عكس الجهاز، فيبقى شمالها شمالاً في الواقع.
                      Transform.rotate(
                        angle: -heading * math.pi / 180,
                        child: CustomPaint(
                          size: Size.square(dial),
                          painter: _DialPainter(
                            bearing: bearing,
                            face: AppColors.surface(context),
                            ring: AppColors.primary(context),
                            ticks: AppColors.textSecondary(context),
                            gold: gold,
                            facing: _facing,
                            labels: [
                              l10n.qiblaNorth,
                              l10n.qiblaEast,
                              l10n.qiblaSouth,
                              l10n.qiblaWest,
                            ],
                            labelStyle: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // الكعبة على الحلقة حيث تقع القبلة.
                      Transform.rotate(
                        angle: (bearing - heading) * math.pi / 180,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: dial * 0.06),
                            child: Transform.rotate(
                              angle: -(bearing - heading) * math.pi / 180,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _facing ? gold : Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: gold, width: 2),
                                ),
                                child: Icon(
                                  FlutterIslamicIcons.kaaba,
                                  size: dial * 0.09,
                                  color: _facing ? Colors.black : gold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // حيث يشير أعلى الجهاز.
                      Align(
                        alignment: Alignment.topCenter,
                        child: CustomPaint(
                          size: const Size(22, 16),
                          painter: _PointerPainter(
                            color: _facing ? gold : AppColors.primary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _Fact(
                    icon: AppIcons.compass,
                    value: '${l10n.digits(bearing.round())}°',
                    label: l10n.qiblaFromNorth,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Fact(
                    icon: AppIcons.mosque,
                    value: l10n.digits(km.round()),
                    label: l10n.qiblaKmToMakkah,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              location.saved ? l10n.qiblaFromLastLocation : l10n.qiblaFromHere,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
            if (_hasCompass) ...[
              const SizedBox(height: 6),
              Text(
                l10n.qiblaCalibrate,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// ما يظهر قبل معرفة الموقع: انتظار، أو سبب وما يُفعل.
class _NoLocation extends StatelessWidget {
  final bool locating;
  final QiblaFix? problem;
  final QiblaLocator locator;
  final VoidCallback onRetry;

  const _NoLocation({
    required this.locating,
    required this.problem,
    required this.locator,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final (
      String message,
      String action,
      VoidCallback onAction,
    ) = switch (problem) {
      QiblaLocationOff() => (
        l10n.qiblaLocationOff,
        l10n.qiblaTurnOnLocation,
        () => locator.openLocationSettings(),
      ),
      QiblaPermissionDenied(forever: true) => (
        l10n.qiblaNeedsLocation,
        l10n.qiblaOpenSettings,
        () => locator.openAppSettings(),
      ),
      QiblaPermissionDenied() => (
        l10n.qiblaNeedsLocation,
        l10n.qiblaAllowLocation,
        onRetry,
      ),
      _ => (l10n.qiblaLocationFailed, l10n.retry, onRetry),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FlutterIslamicIcons.qibla2, size: 64, color: gold),
            const SizedBox(height: 18),
            if (locating || problem == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(l10n.qiblaLocating, textAlign: TextAlign.center),
            ] else ...[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(action)),
              if (problem is! QiblaLocationFailed) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: Text(l10n.retry)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Fact({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentGold(context)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// وجه البوصلة: حلقة الدرجات والجهات الأربع وخط نحو القبلة.
class _DialPainter extends CustomPainter {
  final double bearing;
  final Color face;
  final Color ring;
  final Color ticks;
  final Color gold;
  final bool facing;
  final List<String> labels;
  final TextStyle labelStyle;

  _DialPainter({
    required this.bearing,
    required this.face,
    required this.ring,
    required this.ticks,
    required this.gold,
    required this.facing,
    required this.labels,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = face);
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // علامات الدرجات، وأطول كل 30°.
    for (var d = 0; d < 360; d += 5) {
      final a = (d - 90) * math.pi / 180;
      final long = d % 30 == 0;
      final inner = r - (long ? 18 : 10);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * (r - 5),
        Paint()
          ..color = ticks.withValues(alpha: long ? 0.9 : 0.45)
          ..strokeWidth = long ? 2 : 1,
      );
    }
    // الجهات الأربع، والشمال بالذهبي.
    for (var i = 0; i < 4; i++) {
      final a = (i * 90 - 90) * math.pi / 180;
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: i == 0 ? labelStyle.copyWith(color: gold) : labelStyle,
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final p = c + Offset(math.cos(a), math.sin(a)) * (r - 34);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(i * math.pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
      painter.dispose();
    }
    // الخط من المركز نحو الكعبة.
    final q = (bearing - 90) * math.pi / 180;
    canvas.drawLine(
      c,
      c + Offset(math.cos(q), math.sin(q)) * (r * 0.62),
      Paint()
        ..color = gold.withValues(alpha: facing ? 1 : 0.8)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 7, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.bearing != bearing ||
      old.facing != facing ||
      old.face != face ||
      old.ring != ring ||
      old.gold != gold;
}

/// السهم الثابت أعلى البوصلة: حيث يشير أعلى الجهاز.
class _PointerPainter extends CustomPainter {
  final Color color;

  _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => old.color != color;
}
