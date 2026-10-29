import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_logo.dart';
import '../../data/storage/user_data_store.dart';
import '../memorization/memorization_model.dart';
import '../../core/design_system/app_icons.dart';

/// إحصاءات شهر واحد لتقرير الشهر.
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

  /// يحسب إحصاءات الشهر الذي يقع فيه [month].
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

  /// يفتح لوحة تقرير الشهر الحالي.
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

  static const double _width = 360;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1080 / _width);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tadbeer_month_report.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
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
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: const Icon(AppIcons.export),
              label: Text(l10n.shareImage),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة تقرير الشهر بألوان السمة المختارة وذهبها، كبطاقة مشاركة الآية.
class MonthlyReportCard extends StatelessWidget {
  final MonthStats stats;
  final String monthTitle;
  final double width;

  /// السمة التي تأخذ البطاقة ألوانها منها؛ السمة المختارة إن لم تُحدَّد.
  final AppColorTheme? colorTheme;

  /// ينشئ بطاقة تقرير الشهر.
  const MonthlyReportCard({
    super.key,
    required this.stats,
    required this.monthTitle,
    required this.width,
    this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = ThemePalette.of(colorTheme ?? AppColors.theme);
    const gold = Color(0xFFD9B566);
    const text = Color(0xFFF2EEE4);
    Widget stat(IconData icon, String value, String label) => Column(
      children: [
        Icon(icon, color: gold, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: text,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: width,
        height: width * 1.25,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          // The theme's hero colour glowing out of its night background.
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
            Row(
              children: [
                Expanded(
                  child: stat(
                    AppIcons.bookOpenTextFill,
                    l10n.digits(stats.pages),
                    l10n.totalPagesRead,
                  ),
                ),
                Expanded(
                  child: stat(
                    AppIcons.fire,
                    l10n.digits(stats.activeDays),
                    l10n.activeDaysLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: stat(
                    AppIcons.flowerLotusFill,
                    l10n.digits(stats.reflections),
                    l10n.reflectionsLabel,
                  ),
                ),
                Expanded(
                  child: stat(
                    AppIcons.brainFill,
                    l10n.digits(stats.memorized),
                    l10n.memorizedLabel,
                  ),
                ),
              ],
            ),
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
                  'تَدْبِير',
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
