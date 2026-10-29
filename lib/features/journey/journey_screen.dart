import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../reminders/local_reminder_service.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../quran/screens/quran_screen.dart';
import '../../data/models/reminder_model.dart';
import 'monthly_report.dart';
import 'mushaf_map_screen.dart';
import '../../data/models/reading_journey.dart';
import 'weekly_goals.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/app_menu.dart';
import '../../core/design_system/ornaments.dart';
import 'portion_reminder.dart';
import 'streak_reminder.dart';
import '../onboarding/tour/section_guide.dart';

/// «رحلتي مع القرآن»: خطة الختمة، وورد اليوم، والإحصاءات.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myJourney),
          actions: [
            GuideButton(topic: GuideTopic.journey),
            IconButton(
              tooltip: l10n.monthlyReport,
              icon: const Icon(AppIcons.chartLineUp),
              onPressed: () => MonthlyReportSheet.show(context),
            ),
            IconButton(
              tooltip: l10n.mushafMap,
              icon: const Icon(AppIcons.gridFour),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MushafMapScreen()),
              ),
            ),
          ],
        ),
        body: PatternBackground(
          child: ListenableBuilder(
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
                  WeeklyGoalsCard(now: now),
                  const SizedBox(height: 12),
                  _StatsRow(journey: journey, now: now),
                  const SizedBox(height: 12),
                  const _StreakReminderCard(),
                  const SizedBox(height: 12),
                  _WeekChartCard(days: journey.lastSevenDays(now), now: now),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// بطاقة بدء ختمة باختيار مدتها.
class _StartKhatmaCard extends StatefulWidget {
  final int completed;

  const _StartKhatmaCard({required this.completed});

  @override
  State<_StartKhatmaCard> createState() => _StartKhatmaCardState();
}

class _StartKhatmaCardState extends State<_StartKhatmaCard> {
  /// يعرض تذكيراً يومياً بالورد بعد البدء مباشرة.
  ///
  /// بدء الختمة يستبدل هذه البطاقة بالخطة، فيُؤخذ الـ navigator والـ messenger
  /// من الشاشة قبل البدء.
  static Future<void> _offerPortionReminder(
    NavigatorState navigator,
    ScaffoldMessengerState messenger,
    AppStrings l10n,
    int days,
  ) async {
    if (!navigator.mounted) return;
    final time = await showTimePicker(
      context: navigator.context,
      helpText: l10n.portionReminderPrompt,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (time == null) return;
    final pages = (mushafPageCount / days).ceil();
    final reminder = ReminderItem(
      id: portionReminderId,
      title: l10n.portionReminderTitle(pages),
      hour: time.hour,
      minute: time.minute,
      repeatMode: ReminderRepeatMode.daily,
      alertType: ReminderAlertType.notification,
      createdAt: DateTime.now(),
    );
    await UserDataStore.instance.putReminder(reminder);
    await LocalReminderService.instance.scheduleReminder(reminder);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.portionReminderSet, textAlign: TextAlign.center),
      ),
    );
  }

  static const _options = [7, 15, 30, 60, 90];
  int _days = 30;
  bool _fromCurrent = false;

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
            Icon(AppIcons.flag, size: 40, color: gold),
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
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.fromMushafStart)),
                ButtonSegment(
                  value: true,
                  label: Text(
                    l10n.fromMyPosition(
                      UserDataStore.instance.readingPosition.page,
                    ),
                  ),
                ),
              ],
              selected: {_fromCurrent},
              showSelectedIcon: false,
              onSelectionChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _fromCurrent = v.first);
              },
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final l10n = context.l10n;
                final days = _days;
                await UserDataStore.instance.startKhatma(
                  days,
                  startPage: _fromCurrent
                      ? UserDataStore.instance.readingPosition.page
                      : 1,
                );
                await _offerPortionReminder(navigator, messenger, l10n, days);
              },
              icon: const Icon(AppIcons.play),
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

/// حلقة تقدم الختمة، ومدى الالتزام بالخطة.
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

  Future<void> _askMoveTo(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: '${plan.currentPage}');
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.setKhatmaPosition),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.pageNumberLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              int.tryParse(
                ArabicSearchNormalizer.toEnglishDigits(controller.text.trim()),
              ),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (page != null && page >= 1 && page <= mushafPageCount) {
      await UserDataStore.instance.moveKhatmaTo(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final diff = plan.advanced - plan.expectedPagesBefore(now);
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
                  icon: appMenuIcon,
                  itemBuilder: (_) => [
                    appMenuItem(
                      onTap: UserDataStore.instance.completeTodayPortion,
                      icon: AppIcons.checkCircle,
                      label: l10n.markPortionDone,
                    ),
                    appMenuItem(
                      onTap: () => _askMoveTo(context),
                      icon: AppIcons.crosshair,
                      label: l10n.setKhatmaPosition,
                    ),
                    appMenuItem(
                      onTap: () => _confirmCancel(context),
                      icon: AppIcons.x,
                      label: l10n.cancelKhatma,
                      destructive: true,
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
                        // نفس صفحة زر "أكمل" تحتها.
                        Text(
                          l10n.reachedPage(plan.currentPage),
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

/// ورد اليوم، وزر المتابعة من أول صفحة لم تُقرأ.
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
    final today = journey.portionPagesOn(now);
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
                  done ? AppIcons.checkCircleFill : AppIcons.calendarCheck,
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
                  builder: (_) => QuranScreen(initialPage: plan.currentPage),
                ),
              ),
              icon: const Icon(AppIcons.bookOpenFill),
              label: Text(
                done
                    ? l10n.keepReading
                    // لم يُقرأ شيء بعد: لا شيء يُكمل.
                    : plan.advanced == 0
                    ? l10n.khatmaStartNow
                    : l10n.continueFromPage(plan.currentPage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف الإحصاءات: السلسلة، وإجمالي الصفحات، والختمات المكتملة.
class _StatsRow extends StatelessWidget {
  final ReadingJourney journey;
  final DateTime now;

  const _StatsRow({required this.journey, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reflections = UserDataStore.instance.tadbeerItems
        .where(
          (t) =>
              !t.isEmpty &&
              t.updatedAt.year == now.year &&
              t.updatedAt.month == now.month,
        )
        .length;
    Widget pair(Widget a, Widget b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
    return Column(
      children: [
        pair(
          _StatTile(
            icon: AppIcons.fire,
            color: const Color(0xFFE07A3F),
            value: l10n.digits(journey.streak(now)),
            label: l10n.streakDays,
          ),
          _StatTile(
            icon: AppIcons.bookOpenTextFill,
            color: AppColors.accentGold(context),
            value: l10n.digits(journey.totalPages),
            label: l10n.totalPagesRead,
          ),
        ),
        const SizedBox(height: 10),
        pair(
          _StatTile(
            icon: AppIcons.flowerLotusFill,
            color: AppColors.statusSuccess,
            value: l10n.digits(reflections),
            label: l10n.reflectionsThisMonth,
          ),
          _StatTile(
            icon: AppIcons.medal,
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

/// مفتاح تنبيه السلسلة: إشعار مسائي إن لم يكن في اليوم نشاط بعد.
class _StreakReminderCard extends StatelessWidget {
  const _StreakReminderCard();

  ReminderItem? get _reminder => UserDataStore.instance.reminders
      .where((r) => r.id == streakReminderId)
      .firstOrNull;

  /// يطلب الوقت، ثم يحفظ التذكير ويجدوله.
  Future<void> _pickTime(BuildContext context, ReminderItem? current) async {
    final l10n = context.l10n;
    final time = await showTimePicker(
      context: context,
      helpText: l10n.streakReminderPrompt,
      initialTime: current == null
          ? const TimeOfDay(hour: streakReminderDefaultHour, minute: 0)
          : TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null) return;
    final reminder =
        (current ??
                ReminderItem(
                  id: streakReminderId,
                  title: l10n.streakReminder,
                  hour: time.hour,
                  minute: time.minute,
                  repeatMode: ReminderRepeatMode.daily,
                  alertType: ReminderAlertType.notification,
                  createdAt: DateTime.now(),
                ))
            .copyWith(hour: time.hour, minute: time.minute, isEnabled: true);
    await UserDataStore.instance.putReminder(reminder);
    await LocalReminderService.instance.scheduleReminder(reminder);
  }

  Future<void> _turnOff(ReminderItem current) async {
    final off = current.copyWith(isEnabled: false);
    await UserDataStore.instance.putReminder(off);
    await LocalReminderService.instance.cancelReminder(off);
  }

  @override
  Widget build(BuildContext context) {
    // مستمع خاص: البطاقة ثابتة (const)، فإعادة بناء الشاشة وحدها لا تحدّثها عند
    // حفظ التذكير.
    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final reminder = _reminder;
    final on = reminder?.isEnabled ?? false;
    final time = reminder == null
        ? null
        : TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    return Card(
      margin: EdgeInsets.zero,
      // المفتاح يشغّله أو يطفئه؛ والنقر على الصف بعد تشغيله يغيّر الوقت.
      child: ListTile(
        onTap: on ? () => _pickTime(context, reminder) : null,
        leading: const Icon(AppIcons.bellRinging, color: Color(0xFFE07A3F)),
        title: Text(
          l10n.streakReminder,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          on && time != null
              ? l10n.streakReminderAt(time.format(context))
              : l10n.streakReminderOff,
        ),
        trailing: Switch(
          value: on,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            if (value) {
              _pickTime(context, reminder);
            } else if (reminder != null) {
              _turnOff(reminder);
            }
          },
        ),
      ),
    );
  }
}

/// أعمدة صفحات آخر سبعة أيام.
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
                                // easeOutBack يتجاوز الهدف، فلا يجوز أن يتخطى
                                // أطول عمود حدود المخطط أثناء ارتداده.
                                height: (100 * v).clamp(4.0, 100.0),
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
                                DateTime(
                                  today.year,
                                  today.month,
                                  today.day - (days.length - 1 - i),
                                ).weekday,
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
