import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'adhkar_model.dart';
import 'adhkar_repository.dart';

/// شاشة أذكار الصباح والمساء المأثورة بتصميم هادئ ومريح مع عداد تفاعلي لكل ذكر.
class MorningEveningAdhkarScreen extends StatefulWidget {
  /// القسم المبدئي (صباح أو مساء).
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
  late AdhkarCategory _currentCategory;
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.initialCategory;
  }

  void _switchCategory(AdhkarCategory cat) {
    if (_currentCategory == cat) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentCategory = cat;
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
      if (currentDone + 1 == item.repeatCount) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _resetAllCounts() {
    HapticFeedback.selectionClick();
    setState(() {
      _counts.clear();
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تمت إعادة ضبط عدادات الأذكار',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Amiri', fontSize: 13),
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ نص الذكر الشريف بنجاح',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Amiri', fontSize: 13),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final adhkarList = AdhkarRepository.instance.getAdhkar(_currentCategory);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text(
            'أذكار الصباح والمساء',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'إعادة ضبط العدادات',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: _resetAllCounts,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // مفتاح التبديل بين الصباح والمساء
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          title: 'أذكار الصباح',
                          icon: Icons.wb_sunny_rounded,
                          count: AdhkarRepository.morningAdhkar.length,
                          isSelected:
                              _currentCategory == AdhkarCategory.morning,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          onTap: () =>
                              _switchCategory(AdhkarCategory.morning),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TabButton(
                          title: 'أذكار المساء',
                          icon: Icons.nightlight_round,
                          count: AdhkarRepository.eveningAdhkar.length,
                          isSelected:
                              _currentCategory == AdhkarCategory.evening,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          onTap: () =>
                              _switchCategory(AdhkarCategory.evening),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // قائمة الأذكار
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
    final activeTextColor =
        isDark ? AppColors.darkAccentGold : primaryColor;

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
              '$title (${ArabicSearchNormalizer.toArabicDigits(count)})',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
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
          // شريط الرأس: رقم الذكر، المصدر، زر النسخ، وعداد التكرار
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.olive)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ذكر ${ArabicSearchNormalizer.toArabicDigits(index + 1)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.source,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'نسخ نص الذكر',
                icon: const Icon(Icons.copy_rounded, size: 17),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onCopy,
              ),
              const SizedBox(width: 4),
              // زر العداد التفاعلي
              InkWell(
                onTap: isComplete ? null : onTapCount,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? (isDark
                            ? AppColors.darkAccentGold.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.15))
                        : primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isComplete
                          ? (isDark
                              ? AppColors.darkAccentGold
                              : Colors.green)
                          : primaryColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isComplete
                            ? Icons.check_circle_rounded
                            : Icons.touch_app_rounded,
                        size: 14,
                        color: isComplete
                            ? (isDark
                                ? AppColors.darkAccentGold
                                : Colors.green.shade800)
                            : primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isComplete
                            ? 'اكتمل'
                            : (item.repeatCount > 1
                                ? 'باقٍ ${ArabicSearchNormalizer.toArabicDigits(remaining)}'
                                : 'مرة واحدة'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isComplete
                              ? (isDark
                                  ? AppColors.darkAccentGold
                                  : Colors.green.shade800)
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

          // نص الذكر الشريف
          Text(
            item.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18.5,
              fontWeight: FontWeight.w600,
              height: 1.65,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),

          if (item.virtue.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground.withValues(alpha: 0.5)
                    : AppColors.comsilk,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.virtue,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
