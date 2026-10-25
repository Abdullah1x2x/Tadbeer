import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../quran/screens/quran_screen.dart';
import 'reading_journey.dart';

/// شاشة «رحلتي مع القرآن»: خطة الختمة، ورد اليوم، والإحصاءات.
class JourneyScreen extends StatelessWidget {
  /// ينشئ شاشة رحلة القراءة.
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.myJourney)),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final journey = UserDataStore.instance.journey;
            final now = DateTime.now();
            final plan = journey.plan;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (plan == null)
                  _StartKhatmaCard(completed: journey.completedKhatmas)
                else ...[
                  _KhatmaProgressCard(plan: plan, now: now),
                  const SizedBox(height: 12),
                  _TodayPortionCard(plan: plan, journey: journey, now: now),
                ],
                const SizedBox(height: 12),
                _StatsRow(journey: journey, now: now),
                const SizedBox(height: 12),
                _WeekChartCard(days: journey.lastSevenDays(now), now: now),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// بطاقة بدء ختمة جديدة باختيار المدة.
class _StartKhatmaCard extends StatefulWidget {
  final int completed;

  const _StartKhatmaCard({required this.completed});

  @override
  State<_StartKhatmaCard> createState() => _StartKhatmaCardState();
}

class _StartKhatmaCardState extends State<_StartKhatmaCard> {
  static const _options = [7, 15, 30, 60, 90];
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.flag_rounded, size: 40, color: gold),
            const SizedBox(height: 10),
            Text(
              l10n.startKhatmaTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.startKhatmaHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _options)
                  ChoiceChip(
                    label: Text(l10n.daysCount(d)),
                    selected: _days == d,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _days = d);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.pagesPerDayHint((mushafPageCount / _days).ceil()),
              textAlign: TextAlign.center,
              style: TextStyle(color: gold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                UserDataStore.instance.startKhatma(_days);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.startKhatma),
            ),
            if (widget.completed > 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.completedKhatmas(widget.completed),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// حلقة تقدم الختمة مع حالة الالتزام بالخطة.
class _KhatmaProgressCard extends StatelessWidget {
  final KhatmaPlan plan;
  final DateTime now;

  const _KhatmaProgressCard({required this.plan, required this.now});

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelKhatma),
        content: Text(l10n.cancelKhatmaConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cancelKhatma),
          ),
        ],
      ),
    );
    if (ok == true) await UserDataStore.instance.cancelKhatma();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final read = plan.readPages.length;
    final diff = read - plan.expectedPagesBefore(now);
    final (statusText, statusColor) = diff >= 0
        ? (l10n.onTrack, AppColors.statusSuccess)
        : (l10n.behindBy(-diff), AppColors.statusWarning);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.khatmaInDays(plan.days),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<void>(
                  tooltip: l10n.options,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: () => _confirmCancel(context),
                      child: Text(l10n.cancelKhatma),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: plan.progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => SizedBox.square(
                dimension: 190,
                child: CustomPaint(
                  painter: _RingPainter(
                    value: value,
                    track: AppColors.border(context),
                    gold: gold,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${l10n.digits((value * 100).round())}٪',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        Text(
                          l10n.pagesOfMushaf(read),
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.dayOfPlan(plan.dayNumber(now), plan.days),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة ورد اليوم وزر المتابعة من أول صفحة غير مقروءة.
class _TodayPortionCard extends StatelessWidget {
  final KhatmaPlan plan;
  final ReadingJourney journey;
  final DateTime now;

  const _TodayPortionCard({
    required this.plan,
    required this.journey,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final today = journey.pagesOn(now);
    final target = plan.pagesPerDay;
    final done = today >= target;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.today_rounded,
                  color: done ? AppColors.statusSuccess : gold,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.todayPortion,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.pagesOfTarget(today, target),
                  style: TextStyle(color: gold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (today / target).clamp(0, 1)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) =>
                    LinearProgressIndicator(value: v, minHeight: 10),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuranScreen(initialPage: plan.nextUnreadPage),
                ),
              ),
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(
                done
                    ? l10n.keepReading
                    : l10n.continueFromPage(plan.nextUnreadPage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف الإحصاءات: الأيام المتتالية، إجمالي الصفحات، الختمات المكتملة.
class _StatsRow extends StatelessWidget {
  final ReadingJourney journey;
  final DateTime now;

  const _StatsRow({required this.journey, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFE07A3F),
            value: l10n.digits(journey.streak(now)),
            label: l10n.streakDays,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.auto_stories_rounded,
            color: AppColors.accentGold(context),
            value: l10n.digits(journey.totalPages),
            label: l10n.totalPagesRead,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.workspace_premium_rounded,
            color: AppColors.primary(context),
            value: l10n.digits(journey.completedKhatmas),
            label: l10n.khatmasLabel,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

/// مخطط أعمدة لصفحات آخر سبعة أيام.
class _WeekChartCard extends StatelessWidget {
  final List<int> days;
  final DateTime now;

  const _WeekChartCard({required this.days, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final maxPages = days.fold(1, math.max);
    final today = DateTime(now.year, now.month, now.day);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lastSevenDays,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (days[i] > 0)
                              Text(
                                l10n.digits(days[i]),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: days[i] / maxPages),
                              duration: Duration(milliseconds: 500 + i * 70),
                              curve: Curves.easeOutBack,
                              builder: (context, v, _) => Container(
                                height: math.max(4, 100 * v),
                                decoration: BoxDecoration(
                                  gradient: i == days.length - 1
                                      ? AppColors.goldGradient
                                      : null,
                                  color: i == days.length - 1
                                      ? null
                                      : AppColors.primary(context)
                                            .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.weekdayShort(
                                today
                                    .subtract(
                                      Duration(days: days.length - 1 - i),
                                    )
                                    .weekday,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == days.length - 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: i == days.length - 1
                                    ? gold
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حلقة تقدم بتدرج ذهبي.
class _RingPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color gold;

  _RingPainter({required this.value, required this.track, required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [gold.withValues(alpha: 0.6), gold, const Color(0xFFE8C878)],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.track != track || old.gold != gold;
}
