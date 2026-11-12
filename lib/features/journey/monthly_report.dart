import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_logo.dart';
import '../../data/storage/user_data_store.dart';
import '../memorization/memorization_model.dart';
import '../../core/design_system/app_icons.dart';
import '../share/ayah_share_sheet.dart' show AyahCardFormat;
import '../share/export_actions.dart';

/// إحصاءات شهر لتقرير الشهر.
class MonthStats {
  final int pages;
  final int activeDays;
  final int reflections;
  final int memorized;
  final int khatmas;

  const MonthStats({
    required this.pages,
    required this.activeDays,
    required this.reflections,
    required this.memorized,
    required this.khatmas,
  });

  /// إحصاءات الشهر الذي يقع فيه [month].
  factory MonthStats.of(UserDataStore store, DateTime month) {
    final prefix =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-';
    final journey = store.journey;
    final pages = journey.dailyPages.entries
        .where((e) => e.key.startsWith(prefix))
        .fold(0, (sum, e) => sum + e.value.length);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    var active = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      if (journey.isActiveOn(DateTime(month.year, month.month, d))) active++;
    }
    final reflections = store.tadbeerItems
        .where(
          (t) =>
              !t.isEmpty &&
              t.updatedAt.year == month.year &&
              t.updatedAt.month == month.month,
        )
        .length;
    return MonthStats(
      pages: pages,
      activeDays: active,
      reflections: reflections,
      memorized: HifzStore.memorizedCount(),
      khatmas: journey.completedKhatmas,
    );
  }
}

/// لوحة تقرير الشهر: معاينة البطاقة ومشاركتها صورةً.
class MonthlyReportSheet extends StatefulWidget {
  const MonthlyReportSheet._();

  /// يفتح تقرير الشهر الحالي.
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const MonthlyReportSheet._(),
  );

  @override
  State<MonthlyReportSheet> createState() => _MonthlyReportSheetState();
}

class _MonthlyReportSheetState extends State<MonthlyReportSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;
  AyahCardFormat _format = AyahCardFormat.square;

  /// نتيجة آخر حفظ في المعرض، أو null قبله؛ و[_saving] أثناءه.
  PhotoSaveResult? _saved;
  bool _saving = false;

  static const double _width = 360;
  static const _fileName = 'tadbeer_month_report';

  /// البطاقة كما تظهر، بعرض 1080 بكسل.
  Future<Uint8List?> _capture() async {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return null;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final image = await renderObject.toImage(pixelRatio: 1080 / _width);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _saveToPhotos() async {
    setState(() => _saving = true);
    var result = PhotoSaveResult.failed;
    try {
      final bytes = await _capture();
      if (bytes != null) {
        result = await saveImageToPhotos(bytes, _fileName);
      }
    } catch (_) {
      result = PhotoSaveResult.failed;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = result;
        });
      }
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileName.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await shareOrSaveFile(
        context,
        file: file,
        fileName: '$_fileName.png',
        mimeType: 'image/png',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final stats = MonthStats.of(UserDataStore.instance, now);
    final height = _format == AyahCardFormat.square ? _width : _width * 16 / 9;
    final message = switch (_saved) {
      PhotoSaveResult.saved => l10n.cardSaved,
      PhotoSaveResult.denied => l10n.cardSaveDenied,
      PhotoSaveResult.failed => l10n.cardSaveFailed,
      null => null,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: FittedBox(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: MonthlyReportCard(
                    stats: stats,
                    monthTitle: l10n.monthTitle(now.month, now.year),
                    width: _width,
                    height: height,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<AyahCardFormat>(
              segments: [
                ButtonSegment(
                  value: AyahCardFormat.square,
                  icon: const Icon(AppIcons.square),
                  label: Text(l10n.cardSquare),
                ),
                ButtonSegment(
                  value: AyahCardFormat.story,
                  icon: const RotatedBox(
                    quarterTurns: 1,
                    child: Icon(AppIcons.rectangle),
                  ),
                  label: Text(l10n.cardStory),
                ),
              ],
              selected: {_format},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                setState(() {
                  _format = s.first;
                  _saved = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: const Icon(AppIcons.export),
                    label: Text(l10n.shareImage),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _saveToPhotos,
                    icon: Icon(
                      _saved == PhotoSaveResult.saved
                          ? AppIcons.checkCircleFill
                          : AppIcons.downloadSimple,
                    ),
                    label: Text(l10n.saveToPhotos),
                  ),
                ),
              ],
            ),
            // نتيجة الحفظ تحت الأزرار، لا في رسالة تختفي خلف اللوحة.
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _saved == PhotoSaveResult.saved
                        ? AppColors.primary(context)
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة تقرير الشهر بألوان الثيم المختار وذهبه، كبطاقة مشاركة الآية.
class MonthlyReportCard extends StatelessWidget {
  final MonthStats stats;
  final String monthTitle;
  final double width;

  /// مربعة (بارتفاع [width]) أو طولية للقصص.
  final double height;

  /// الثيم الذي تأخذ البطاقة ألوانه؛ المختار إن لم يُحدَّد.
  final AppColorTheme? colorTheme;

  const MonthlyReportCard({
    super.key,
    required this.stats,
    required this.monthTitle,
    required this.width,
    required this.height,
    this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = ThemePalette.of(colorTheme ?? AppColors.theme);
    const gold = Color(0xFFD9B566);
    const text = Color(0xFFF2EEE4);
    // المربعة أقصر، فتصطف إحصاءاتها الأربع في صف واحد أصغر.
    final square = height <= width;
    Widget stat(IconData icon, String value, String label) => Column(
      children: [
        Icon(icon, color: gold, size: square ? 22 : 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: square ? 24 : 30,
            fontWeight: FontWeight.bold,
            color: text,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: square ? 11 : 13, color: Colors.white70),
        ),
      ],
    );
    final tiles = [
      stat(
        AppIcons.bookOpenTextFill,
        l10n.digits(stats.pages),
        l10n.totalPagesRead,
      ),
      stat(
        AppIcons.fire,
        l10n.digits(stats.activeDays),
        l10n.activeDaysLabel,
      ),
      stat(
        AppIcons.flowerLotusFill,
        l10n.digits(stats.reflections),
        l10n.reflectionsLabel,
      ),
      stat(
        AppIcons.brainFill,
        l10n.digits(stats.memorized),
        l10n.memorizedLabel,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          // لون الثيم يتوهج من خلفيته الليلية.
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [p.heroLightStart, p.darkBackground],
          ),
          border: Border.all(color: gold.withValues(alpha: 0.7), width: 1.4),
        ),
        child: Column(
          children: [
            Text(
              l10n.monthlyReport,
              style: const TextStyle(
                fontFamily: AppTheme.appFontFamily,
                color: gold,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              monthTitle,
              style: const TextStyle(
                fontFamily: AppTheme.appFontFamily,
                color: text,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (square)
              Row(children: [for (final s in tiles) Expanded(child: s)])
            else ...[
              Row(
                children: [for (final s in tiles.take(2)) Expanded(child: s)],
              ),
              const SizedBox(height: 22),
              Row(
                children: [for (final s in tiles.skip(2)) Expanded(child: s)],
              ),
            ],
            const Spacer(),
            if (stats.khatmas > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  l10n.completedKhatmas(stats.khatmas),
                  style: const TextStyle(color: gold, fontSize: 14),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 22, elevated: false),
                const SizedBox(width: 8),
                const Text(
                  'تَدبِير',
                  style: TextStyle(
                    fontFamily: AppTheme.appFontFamily,
                    color: text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
