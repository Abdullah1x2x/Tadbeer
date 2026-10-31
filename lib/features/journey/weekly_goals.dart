import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../core/design_system/app_icons.dart';

/// أهداف الأسبوع: عدد صفحات وعدد وقفات تدبر.
class WeeklyGoals {
  final int pages;
  final int reflections;

  const WeeklyGoals({this.pages = 50, this.reflections = 3});

  static const _key = 'weekly_goals';

  /// الأهداف المحفوظة، أو الافتراضية.
  static WeeklyGoals load() {
    final s = UserDataStore.instance.featureState(_key);
    return WeeklyGoals(
      pages: (s['pages'] as num?)?.toInt() ?? 50,
      reflections: (s['reflections'] as num?)?.toInt() ?? 3,
    );
  }

  Future<void> save() => UserDataStore.instance.saveFeatureState(_key, {
    'pages': pages,
    'reflections': reflections,
  });

  /// بداية الأسبوع (السبت) لـ[now].
  static DateTime weekStart(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    // DateTime.weekday: الإثنين = 1 … السبت = 6، والأحد = 7.
    final sinceSaturday = (today.weekday - DateTime.saturday + 7) % 7;
    return today.subtract(Duration(days: sinceSaturday));
  }

  static int pagesThisWeek(UserDataStore store, DateTime now) {
    final start = weekStart(now);
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      if (day.isAfter(now)) break;
      total += store.journey.pagesOn(day);
    }
    return total;
  }

  static int reflectionsThisWeek(UserDataStore store, DateTime now) {
    final start = weekStart(now);
    return store.tadbeerItems
        .where((t) => !t.isEmpty && !t.updatedAt.isBefore(start))
        .length;
  }
}

/// بطاقة أهداف الأسبوع في «رحلتي».
class WeeklyGoalsCard extends StatelessWidget {
  final DateTime now;

  const WeeklyGoalsCard({super.key, required this.now});

  Future<void> _edit(BuildContext context, WeeklyGoals goals) async {
    final updated = await showDialog<WeeklyGoals>(
      context: context,
      builder: (ctx) => _EditWeeklyGoalsDialog(goals: goals),
    );
    if (updated == null) return;
    unawaited(HapticFeedback.selectionClick());
    await updated.save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = UserDataStore.instance;
    final goals = WeeklyGoals.load();
    final pages = WeeklyGoals.pagesThisWeek(store, now);
    final reflections = WeeklyGoals.reflectionsThisWeek(store, now);

    Widget bar(IconData icon, String label, int value, int goal, Color color) {
      final done = goal == 0 || value >= goal;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  done ? AppIcons.checkCircleFill : icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(label)),
                Text(
                  l10n.versesOfTotal(value, goal),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal == 0 ? 1 : (value / goal).clamp(0, 1),
                minHeight: 8,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.weeklyGoals,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.editGoals,
                  icon: const Icon(AppIcons.slidersHorizontal),
                  onPressed: () => _edit(context, goals),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 8),
              child: Column(
                children: [
                  bar(
                    AppIcons.bookOpenTextFill,
                    l10n.pagesGoal,
                    pages,
                    goals.pages,
                    AppColors.accentGold(context),
                  ),
                  bar(
                    AppIcons.flowerLotusFill,
                    l10n.reflectionsGoal,
                    reflections,
                    goals.reflections,
                    AppColors.statusSuccess,
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

/// حوار تعديل الأهداف الأسبوعية مع دورة حياة منضبطة للمتحكمات النصية.
class _EditWeeklyGoalsDialog extends StatefulWidget {
  final WeeklyGoals goals;

  const _EditWeeklyGoalsDialog({required this.goals});

  @override
  State<_EditWeeklyGoalsDialog> createState() => _EditWeeklyGoalsDialogState();
}

class _EditWeeklyGoalsDialogState extends State<_EditWeeklyGoalsDialog> {
  late final TextEditingController _pages;
  late final TextEditingController _reflections;

  @override
  void initState() {
    super.initState();
    _pages = TextEditingController(text: '${widget.goals.pages}');
    _reflections = TextEditingController(text: '${widget.goals.reflections}');
  }

  @override
  void dispose() {
    _pages.dispose();
    _reflections.dispose();
    super.dispose();
  }

  int? _parse(TextEditingController c) =>
      int.tryParse(ArabicSearchNormalizer.toEnglishDigits(c.text.trim()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.weeklyGoals),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pages,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.pagesGoal),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reflections,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.reflectionsGoal),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final targetPages =
                (_parse(_pages) ?? widget.goals.pages).clamp(1, 604);
            final targetReflections =
                (_parse(_reflections) ?? widget.goals.reflections)
                    .clamp(0, 100);
            Navigator.pop(
              context,
              WeeklyGoals(pages: targetPages, reflections: targetReflections),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

