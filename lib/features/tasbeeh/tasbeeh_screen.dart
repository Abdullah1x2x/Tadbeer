import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import 'tasbeeh_model.dart';
import 'tasbeeh_repository.dart';

/// شاشة الاستغفار والتسبيح (السبحة الإلكترونية ومحراب الذكر اليومي).
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  final TasbeehRepository _repo = TasbeehRepository.instance;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  String _selectedCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    _repo.init();
    _repo.addListener(_onRepoChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  List<TasbeehDhikr> get _filteredDhikrs {
    if (_selectedCategory == 'الكل') {
      return TasbeehDhikr.defaultDhikrs;
    }
    return TasbeehDhikr.defaultDhikrs
        .where((d) => d.category == _selectedCategory)
        .toList();
  }

  void _nextDhikr() {
    HapticFeedback.selectionClick();
    _repo.nextDhikr(pool: _filteredDhikrs);
  }

  void _previousDhikr() {
    HapticFeedback.selectionClick();
    _repo.previousDhikr(pool: _filteredDhikrs);
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
    });
    final pool = _filteredDhikrs;
    if (pool.isNotEmpty && pool.every((d) => d.id != _repo.activeDhikr.id)) {
      _repo.setActiveDhikr(pool.first);
    }
  }

  void _handleTap() {
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });

    final targetReached = _repo.increment();
    if (targetReached) {
      HapticFeedback.heavyImpact();
      final finishedTarget = _repo.targetCount;
      if (_repo.autoAdvanceEnabled) {
        _repo.nextDhikr(pool: _filteredDhikrs);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ما شاء الله! أتممت الورد ($finishedTarget). تم الانتقال تلقائياً إلى الذكر التالي.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ما شاء الله! أتممت الورد المستهدف ($finishedTarget) بنجاح.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 15),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _confirmReset() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'تصفير عداد الدورة؟',
            style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'سيتم إعادة عداد الدورة الحالية إلى الصفر مع الحفاظ التام على مجموعك الإجمالي المحفوظ.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.oliveDark,
              ),
              onPressed: () {
                _repo.resetCurrentCount();
                Navigator.pop(ctx);
              },
              child: const Text('تصفير الدورة'),
            ),
          ],
        );
      },
    );
  }

  void _showDhikrPickerSheet() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        String sheetSearchQuery = '';
        String sheetCategory = _selectedCategory;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = TasbeehDhikr.defaultDhikrs.where((item) {
              final matchesCat =
                  sheetCategory == 'الكل' || item.category == sheetCategory;
              final matchesQuery = sheetSearchQuery.isEmpty ||
                  item.arabicText.contains(sheetSearchQuery) ||
                  item.virtue.contains(sheetSearchQuery) ||
                  item.category.contains(sheetSearchQuery);
              return matchesCat && matchesQuery;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.format_list_bulleted_rounded,
                                color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'صيغ الاستغفار والتسبيح (31 صيغة)',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (val) {
                            setSheetState(() {
                              sheetSearchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث في الصيغ والفضائل...',
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: TasbeehDhikr.categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, idx) {
                              final cat = TasbeehDhikr.categories[idx];
                              final isSelected = cat == sheetCategory;
                              return FilterChip(
                                label: Text(cat,
                                    style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (_) {
                                  setSheetState(() {
                                    sheetCategory = cat;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text('لا توجد نتائج مطابقة'),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    final isSelected =
                                        item.id == _repo.activeDhikr.id;

                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                      title: Text(
                                        item.arabicText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? primaryColor
                                              : (isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary),
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${item.category} • الهدف: ${item.defaultTarget}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(Icons.check_circle_rounded,
                                              color: primaryColor)
                                          : null,
                                      onTap: () {
                                        _repo.setActiveDhikr(item);
                                        setState(() {
                                          _selectedCategory = item.category;
                                        });
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final dhikr = _repo.activeDhikr;

    final progress = _repo.targetCount > 0
        ? (_repo.currentCount / _repo.targetCount).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          l10n.tasbeehAndIstighfar,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _repo.autoAdvanceEnabled
                ? 'التبديل التلقائي: مفعّل'
                : 'التبديل التلقائي: معطّل',
            icon: Icon(
              _repo.autoAdvanceEnabled
                  ? Icons.auto_mode_rounded
                  : Icons.sync_disabled_rounded,
              color: _repo.autoAdvanceEnabled
                  ? (isDark ? AppColors.darkAccentGold : AppColors.oliveDark)
                  : null,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              _repo.toggleAutoAdvance();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _repo.autoAdvanceEnabled
                        ? 'تم تفعيل التبديل التلقائي عند اكتمال الورد'
                        : 'تم إيقاف التبديل التلقائي',
                    textAlign: TextAlign.center,
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'تغيير صيغة الذكر',
            icon: const Icon(Icons.format_list_bulleted_rounded),
            onPressed: _showDhikrPickerSheet,
          ),
          IconButton(
            tooltip: 'تصفير عداد الدورة',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 680;
            final circleSize = isCompact ? 180.0 : 220.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // شريط تصنيفات الأذكار (تبديل سريع)
                      _buildCategoryFilterBar(isDark, primaryColor),
                      const SizedBox(height: 10),

                      // بطاقة الذكر الفعال مع أزرار التنقل السريع وإيماءة السحب
                      _buildDhikrCard(dhikr, isDark, primaryColor, isCompact),
                      SizedBox(height: isCompact ? 14 : 20),

                      // الدائرة التفاعلية للتسبيح
                      Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: GestureDetector(
                            onTap: _handleTap,
                            child: Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.comsilk,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? AppColors.darkAccentGold
                                            : AppColors.olive)
                                        .withValues(alpha: 0.12),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // مؤشر التقدم الدائري
                                  SizedBox(
                                    width: circleSize - 16,
                                    height: circleSize - 16,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 6,
                                      backgroundColor: isDark
                                          ? AppColors.darkBorder
                                              .withValues(alpha: 0.3)
                                          : AppColors.lightBorder
                                              .withValues(alpha: 0.5),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        isDark
                                            ? AppColors.darkAccentGold
                                            : primaryColor,
                                      ),
                                    ),
                                  ),
                                  // الرقم والهدف
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_repo.currentCount}',
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: isCompact ? 48 : 60,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightPrimary,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _repo.targetCount > 0
                                            ? 'الهدف: ${_repo.targetCount}'
                                            : 'عدّ حر',
                                        style: TextStyle(
                                          fontSize: isCompact ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'انقر في أي مكان للعدّ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 16 : 22),

                      // بطاقة التحكم في الهدف + مفتاح التبديل التلقائي
                      _buildControlsCard(isDark, primaryColor),
                      const SizedBox(height: 12),

                      // شريط الإحصائيات (اليوم والإجمالي)
                      _buildStatsRow(isDark, primaryColor),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar(bool isDark, Color primaryColor) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: TasbeehDhikr.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = TasbeehDhikr.categories[index];
          final isSelected = cat == _selectedCategory;

          return InkWell(
            onTap: () => _onCategorySelected(cat),
            borderRadius: BorderRadius.circular(19),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark)
                    : (isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDhikrCard(
    TasbeehDhikr dhikr,
    bool isDark,
    Color primaryColor,
    bool isCompact,
  ) {
    final pool = _filteredDhikrs;
    final currentIndex = pool.indexWhere((d) => d.id == dhikr.id);
    final positionText = currentIndex >= 0
        ? 'صيغة ${currentIndex + 1} من ${pool.length}'
        : '${pool.length} صيغة';

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        // في الاتجاه العربي (RTL): السحب لليسار يعني التالي والسحب لليمين يعني السابق
        if (velocity < -200) {
          _nextDhikr();
        } else if (velocity > 200) {
          _previousDhikr();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCompact ? 12 : 15,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkAccentGold
                                : AppColors.olive)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dhikr.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkAccentGold
                              : AppColors.oliveDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      positionText,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _showDhikrPickerSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          'كل الصيغ (31)',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'الذكر السابق',
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  onPressed: _previousDhikr,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      dhikr.arabicText,
                      key: ValueKey<String>(dhikr.id),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: isCompact ? 19 : 22,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightPrimaryDark,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'الذكر التالي',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  onPressed: _nextDhikr,
                ),
              ],
            ),
            if (dhikr.virtue.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground.withValues(alpha: 0.6)
                      : AppColors.comsilk,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: isDark
                          ? AppColors.darkAccentGold
                          : AppColors.oliveDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dhikr.virtue,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_rounded,
                  size: 13,
                  color: (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary)
                      .withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'اسحب أفقياً أو انقر للتبديل السريع',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard(bool isDark, Color primaryColor) {
    const targets = [33, 100, 0];
    final current = _repo.targetCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: targets.map((t) {
              final isSelected = current == t;
              final label = t == 0 ? 'عدّ حر (مفتوح)' : '$t مرة';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _repo.setTarget(t);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkAccentGold.withValues(alpha: 0.2)
                                : primaryColor.withValues(alpha: 0.12))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.darkAccentGold
                                  : primaryColor)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? (isDark
                                  ? AppColors.darkAccentGold
                                  : primaryColor)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _repo.toggleAutoAdvance();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _repo.autoAdvanceEnabled
                        ? Icons.auto_mode_rounded
                        : Icons.sync_disabled_rounded,
                    size: 18,
                    color: _repo.autoAdvanceEnabled
                        ? (isDark
                            ? AppColors.darkAccentGold
                            : AppColors.oliveDark)
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'التبديل التلقائي عند اكتمال الورد',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _repo.autoAdvanceEnabled,
                    activeThumbColor: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      _repo.setAutoAdvance(val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'استغفار وتسبيح اليوم',
            count: _repo.todayTotalCount,
            icon: Icons.today_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'المجموع الكلي المحفوظ',
            count: _repo.lifetimeTotalCount,
            icon: Icons.all_inclusive_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark
                ? AppColors.darkAccentGold
                : AppColors.oliveDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
