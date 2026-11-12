import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../data/adhkar_reminders.dart';
import '../data/adhkar_repository.dart';
import '../../continue/last_activity.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/storage/user_data_store.dart';
import '../../quran/qcf/qcf_ayah_text.dart';
import '../../quran/qcf/qcf_layout.dart';
import '../../../core/design_system/app_icons.dart';
import '../../quran/qcf/qcf_page_body.dart';

/// أذكار الصباح والمساء، مع عدّاد لكل ذكر.
class MorningEveningAdhkarScreen extends StatefulWidget {
  /// الفئة المفتوحة أولاً.
  final AdhkarCategory initialCategory;

  const MorningEveningAdhkarScreen({
    super.key,
    this.initialCategory = AdhkarCategory.morning,
  });

  @override
  State<MorningEveningAdhkarScreen> createState() =>
      _MorningEveningAdhkarScreenState();
}

class _MorningEveningAdhkarScreenState
    extends State<MorningEveningAdhkarScreen> {
  static const _countsKey = 'adhkar_counts';
  late AdhkarCategory _currentCategory;
  final Map<String, int> _counts = {};

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  void _loadSavedCounts() {
    final saved = UserDataStore.instance.featureState(_countsKey);
    if (saved['date'] != _todayKey()) return;
    final raw = saved['counts'];
    if (raw is! Map) return;
    for (final e in raw.entries) {
      final v = e.value;
      if (e.key is String && v is num && v > 0) {
        _counts[e.key as String] = v.toInt();
      }
    }
  }

  void _persistCounts() {
    if (!UserDataStore.instance.isInitialized) return;
    unawaited(
      UserDataStore.instance.saveFeatureState(_countsKey, {
        'date': _todayKey(),
        'counts': Map<String, int>.from(_counts),
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.initialCategory;
    if (UserDataStore.instance.isInitialized) {
      _loadSavedCounts();
    }
    // الحفظ يُعلم المخزن، فلا يكون أثناء بناء الشاشة.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordActivity());
  }

  void _recordActivity() {
    LastActivityStore.record(
      ActivityKind.adhkar,
      ref: _currentCategory.name,
      title: _currentCategory.name,
    );
  }

  void _switchCategory(AdhkarCategory cat) {
    if (_currentCategory == cat) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentCategory = cat;
      _recordActivity();
    });
  }

  int _getRemainingCount(AdhkarItem item) {
    final done = _counts[item.id] ?? 0;
    final remaining = item.repeatCount - done;
    return remaining < 0 ? 0 : remaining;
  }

  void _incrementCount(AdhkarItem item) {
    final currentDone = _counts[item.id] ?? 0;
    if (currentDone < item.repeatCount) {
      HapticFeedback.lightImpact();
      setState(() {
        _counts[item.id] = currentDone + 1;
      });
      _persistCounts();
      if (currentDone + 1 == item.repeatCount) {
        HapticFeedback.mediumImpact();
        _onItemCompleted();
      }
    }
  }

  /// إتمام كل الأذكار يحتسب اليوم في سلسلة القراءة.
  void _onItemCompleted() {
    final items = AdhkarRepository.instance.getAdhkar(_currentCategory);
    if (items.any((i) => _getRemainingCount(i) > 0)) return;
    HapticFeedback.heavyImpact();
    UserDataStore.instance.markActiveDay();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.adhkarSetCompleted,
            textAlign: TextAlign.center,
          ),
        ),
      );
  }

  void _resetAllCounts() {
    HapticFeedback.selectionClick();
    setState(() {
      _counts.clear();
    });
    _persistCounts();
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.adhkarCountersResetSuccess,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: l10n.isArabic ? 'IBMPlexSansArabic' : null,
            fontSize: 13,
          ),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyDhikr(AdhkarItem item) {
    Clipboard.setData(ClipboardData(text: '${item.text}\n\n— ${item.source}'));
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.dhikrCopiedSuccess,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: l10n.isArabic ? 'IBMPlexSansArabic' : null,
            fontSize: 13,
          ),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final adhkarList = AdhkarRepository.instance.getAdhkar(_currentCategory);

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            l10n.adhkarKind,
            style: TextStyle(
              fontFamily: l10n.isArabic ? 'IBMPlexSansArabic' : null,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: l10n.adhkarReminders,
              icon: const Icon(AppIcons.bellRinging),
              onPressed: () => AdhkarReminders.showSettingsSheet(context),
            ),
            IconButton(
              tooltip: l10n.resetCounters,
              icon: const Icon(AppIcons.arrowCounterClockwise),
              onPressed: _resetAllCounts,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // التبديل بين الصباح والمساء.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (category, title, icon) in [
                          (
                            AdhkarCategory.morning,
                            l10n.morningAdhkar,
                            AppIcons.sunFill,
                          ),
                          (
                            AdhkarCategory.evening,
                            l10n.eveningAdhkar,
                            AppIcons.moon,
                          ),
                          (
                            AdhkarCategory.sleep,
                            l10n.sleepAdhkar,
                            AppIcons.moonStars,
                          ),
                          (
                            AdhkarCategory.waking,
                            l10n.wakingAdhkar,
                            AppIcons.sunFill,
                          ),
                          (
                            AdhkarCategory.afterPrayer,
                            l10n.afterPrayerAdhkar,
                            AppIcons.handHeart,
                          ),
                          (
                            AdhkarCategory.mosque,
                            l10n.mosqueAdhkar,
                            AppIcons.bookOpen,
                          ),
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _TabButton(
                              title: title,
                              icon: icon,
                              count: AdhkarRepository.instance
                                  .getAdhkar(category)
                                  .length,
                              isSelected: _currentCategory == category,
                              isDark: isDark,
                              primaryColor: primaryColor,
                              onTap: () => _switchCategory(category),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: adhkarList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = adhkarList[index];
                    final remaining = _getRemainingCount(item);
                    final isComplete = remaining == 0;

                    return _AdhkarCard(
                      item: item,
                      index: index,
                      remaining: remaining,
                      isComplete: isComplete,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      onTapCount: () => _incrementCount(item),
                      onCopy: () => _copyDhikr(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark
        ? AppColors.darkAccentGold.withValues(alpha: 0.18)
        : primaryColor.withValues(alpha: 0.12);
    final activeTextColor = isDark ? AppColors.darkAccentGold : primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? AppColors.darkAccentGold.withValues(alpha: 0.5)
                      : primaryColor.withValues(alpha: 0.4),
                  width: 1.2,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? activeTextColor
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              '$title (${context.l10n.digits(count)})',
              style: TextStyle(
                fontFamily: context.l10n.isArabic ? 'IBMPlexSansArabic' : null,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeTextColor
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdhkarCard extends StatelessWidget {
  final AdhkarItem item;
  final int index;
  final int remaining;
  final bool isComplete;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTapCount;
  final VoidCallback onCopy;

  const _AdhkarCard({
    required this.item,
    required this.index,
    required this.remaining,
    required this.isComplete,
    required this.isDark,
    required this.primaryColor,
    required this.onTapCount,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? (isDark
                    ? AppColors.darkAccentGold.withValues(alpha: 0.4)
                    : primaryColor.withValues(alpha: 0.35))
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الرأس: رقم الذكر ومصدره والنسخ وعدّاد التكرار.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkAccentGold : AppColors.olive)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.dhikrIndex(l10n.digits(index + 1)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.copyDhikr,
                icon: const Icon(AppIcons.copy, size: 17),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onCopy,
              ),
              const SizedBox(width: 4),
              // العدّاد.
              InkWell(
                onTap: isComplete ? null : onTapCount,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? (isDark
                              ? AppColors.darkAccentGold.withValues(alpha: 0.2)
                              : AppColors.lightAccentGold.withValues(
                                  alpha: 0.15,
                                ))
                        : primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isComplete
                          ? (isDark
                                ? AppColors.darkAccentGold
                                : AppColors.lightAccentGold)
                          : primaryColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isComplete
                            ? AppIcons.checkCircleFill
                            : AppIcons.handTap,
                        size: 14,
                        color: isComplete
                            ? (isDark
                                  ? AppColors.darkAccentGold
                                  : AppColors.lightAccentGold)
                            : primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isComplete
                            ? l10n.completed
                            : (item.repeatCount > 1
                                  ? l10n.remainingCount(l10n.digits(remaining))
                                  : l10n.once),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isComplete
                              ? (isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.lightAccentGold)
                              : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _AdhkarText(
            item: item,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ],
      ),
    );
  }
}

/// نص الذكر؛ والقرآني منه برسم المصحف حين يكون مصحف المدينة هو المختار.
class _AdhkarText extends StatefulWidget {
  final AdhkarItem item;
  final Color color;

  const _AdhkarText({required this.item, required this.color});

  @override
  State<_AdhkarText> createState() => _AdhkarTextState();
}

class _AdhkarTextState extends State<_AdhkarText> {
  Future<void>? _initFuture;

  bool get _needsMadinahQcf =>
      widget.item.quran.isNotEmpty &&
      QuranRepository.instance.isLoaded &&
      UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah;

  @override
  void initState() {
    super.initState();
    if (_needsMadinahQcf) {
      _initFuture = QcfLayout.instance.init();
    }
  }

  @override
  void didUpdateWidget(covariant _AdhkarText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_needsMadinahQcf) {
      _initFuture ??= QcfLayout.instance.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plain = Text(
      widget.item.text,
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: QcfPageBody.scriptStyle(
        fontSize: 20,
        height: 1.9,
        color: widget.color,
      ),
    );
    if (!_needsMadinahQcf) {
      return plain;
    }
    _initFuture ??= QcfLayout.instance.init();
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, _) {
        final repo = QuranRepository.instance;
        // سورة لكل فقرة، كما في نص الذكر.
        final parts = [
          for (final (surah, from, to) in widget.item.quran)
            [
              for (var a = from; a <= to; a++)
                switch (repo.getAyah(surah, a)) {
                  final ayah? => QcfGlyphs.of(ayah),
                  null => null,
                },
            ],
        ];
        if (parts.any((p) => p.contains(null))) return plain;
        return Column(
          children: [
            for (final (i, part) in parts.indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              Text(
                part.map((g) => g!.text).join(),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: part.first!.style(
                  fontSize: 21,
                  height: 1.9,
                  color: widget.color,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
