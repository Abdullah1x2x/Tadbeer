import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import 'tasbeeh_model.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/ornaments.dart';

part 'tasbeeh_widgets.dart';

/// الاستغفار والتسبيح: سبحة بسيطة بقسمين.
///
/// مربع الذكر ثابت الحجم، فلا تقفز الشاشة عند تقليب الأذكار.
class TasbeehScreen extends StatefulWidget {
  /// القسم الذي تُفتح عليه.
  final DhikrSection? initialSection;

  const TasbeehScreen({super.key, this.initialSection});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  final TasbeehRepository _repo = TasbeehRepository.instance;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  /// هل العدّ التلقائي يعمل.
  bool _isAutoCounting = false;

  /// مؤقت العدّ التلقائي، بإيقاع الذكر.
  Timer? _autoCountTimer;

  /// تعديل القارئ على الإيقاع بالثواني، زيادة أو نقصاً.
  double _paceOffsetSeconds = 0.0;

  @override
  void initState() {
    super.initState();
    _repo.init();
    if (widget.initialSection != null) {
      _repo.setActiveSection(widget.initialSection!);
    }
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
    _autoCountTimer?.cancel();
    _repo.removeListener(_onRepoChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  /// إيقاع كل عَدّة بالثواني بعد تعديل القارئ.
  double get _currentPaceSeconds {
    final basePace = _repo.activeDhikr.estimatedPaceSeconds;
    final total = basePace + _paceOffsetSeconds;
    return double.parse(total.clamp(0.8, 10.0).toStringAsFixed(1));
  }

  /// يبدأ مؤقت العدّ التلقائي بالإيقاع الحالي، أو يعيد ضبطه.
  void _startAutoCountTimer() {
    _autoCountTimer?.cancel();
    final duration = Duration(
      milliseconds: (_currentPaceSeconds * 1000).round(),
    );
    _autoCountTimer = Timer.periodic(duration, (_) {
      if (!mounted) return;
      _handleTap();
    });
  }

  void _stopAutoCount() {
    _autoCountTimer?.cancel();
    _autoCountTimer = null;
    if (_isAutoCounting && mounted) {
      setState(() {
        _isAutoCounting = false;
      });
    }
  }

  void _toggleAutoCount() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAutoCounting = !_isAutoCounting;
      if (_isAutoCounting) {
        _startAutoCountTimer();
      } else {
        _autoCountTimer?.cancel();
        _autoCountTimer = null;
      }
    });
  }

  /// يسرّع العدّ التلقائي 0.2 ثانية.
  void _speedUpPace() {
    HapticFeedback.selectionClick();
    setState(() {
      _paceOffsetSeconds = double.parse(
        (_paceOffsetSeconds - 0.2).toStringAsFixed(1),
      );
      if (_isAutoCounting) {
        _startAutoCountTimer();
      }
    });
  }

  /// يبطئ العدّ التلقائي 0.2 ثانية.
  void _slowDownPace() {
    HapticFeedback.selectionClick();
    setState(() {
      _paceOffsetSeconds = double.parse(
        (_paceOffsetSeconds + 0.2).toStringAsFixed(1),
      );
      if (_isAutoCounting) {
        _startAutoCountTimer();
      }
    });
  }

  DhikrSection get _currentSection => _repo.activeSection;

  /// أذكار القسم الجاري.
  List<TasbeehDhikr> get _filteredDhikrs {
    return _currentSection == DhikrSection.istighfar
        ? TasbeehDhikr.istighfarDhikrs
        : TasbeehDhikr.tasbeehDhikrs;
  }

  void _onSectionSelected(DhikrSection section) {
    if (_repo.activeSection == section) return;
    HapticFeedback.selectionClick();
    _repo.setActiveSection(section);
    _paceOffsetSeconds = 0.0;
    if (_isAutoCounting) {
      _startAutoCountTimer();
    }
  }

  void _nextDhikr() {
    HapticFeedback.selectionClick();
    _repo.nextDhikr(pool: _filteredDhikrs);
    _paceOffsetSeconds = 0.0;
    if (_isAutoCounting) {
      _startAutoCountTimer();
    }
  }

  void _previousDhikr() {
    HapticFeedback.selectionClick();
    _repo.previousDhikr(pool: _filteredDhikrs);
    _paceOffsetSeconds = 0.0;
    if (_isAutoCounting) {
      _startAutoCountTimer();
    }
  }

  /// نقرة التسبيح، مع أثرها الحركي والاهتزاز.
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
        _paceOffsetSeconds = 0.0;
        if (_isAutoCounting) {
          _startAutoCountTimer();
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.targetReachedAuto(finishedTarget),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
              ),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        if (_isAutoCounting) {
          _stopAutoCount();
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.targetReached(finishedTarget),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
              ),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _copyDhikrText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.dhikrCopied,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// يطلب التأكيد قبل تصفير الدورة.
  void _confirmReset() {
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            l10n.resetCycleCounterTitle,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.resetCycleCounterConfirm,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.oliveDark,
              ),
              onPressed: () {
                _repo.resetCurrentCount();
                if (_isAutoCounting) {
                  _stopAutoCount();
                }
                Navigator.pop(ctx);
              },
              child: Text(l10n.resetCycleAction),
            ),
          ],
        );
      },
    );
  }

  /// لوحة لاستعراض الأذكار واختيار أحدها.
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
        DhikrSection? sheetSection = _currentSection;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allDhikrs = TasbeehDhikr.defaultDhikrs;
            final filtered = allDhikrs.where((item) {
              final matchesSection =
                  sheetSection == null || item.section == sheetSection;
              final matchesQuery =
                  sheetSearchQuery.isEmpty ||
                  item.arabicText.contains(sheetSearchQuery) ||
                  item.virtue.contains(sheetSearchQuery);
              return matchesSection && matchesQuery;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                            Icon(
                              AppIcons.listBullets,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${context.l10n.tasbeehAndIstighfarFormulas} (${context.l10n.digits(allDhikrs.length)})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // التبديل بين القسمين.
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              _SheetSectionTab(
                                title:
                                    '${context.l10n.istighfar} (${context.l10n.digits(TasbeehDhikr.istighfarDhikrs.length)})',
                                isSelected:
                                    sheetSection == DhikrSection.istighfar,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                onTap: () {
                                  setSheetState(() {
                                    sheetSection = DhikrSection.istighfar;
                                  });
                                },
                              ),
                              _SheetSectionTab(
                                title:
                                    '${context.l10n.tasbeeh} (${context.l10n.digits(TasbeehDhikr.tasbeehDhikrs.length)})',
                                isSelected:
                                    sheetSection == DhikrSection.tasbeeh,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                onTap: () {
                                  setSheetState(() {
                                    sheetSection = DhikrSection.tasbeeh;
                                  });
                                },
                              ),
                              _SheetSectionTab(
                                title:
                                    '${context.l10n.allCategories} (${context.l10n.digits(allDhikrs.length)})',
                                isSelected: sheetSection == null,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                onTap: () {
                                  setSheetState(() {
                                    sheetSection = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          onChanged: (val) {
                            setSheetState(() {
                              sheetSearchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: context.l10n.searchDhikrHint,
                            prefixIcon: const Icon(
                              AppIcons.magnifyingGlass,
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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

                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(context.l10n.noMatchingFormulas),
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
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                      title: Text(
                                        item.arabicText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'IBMPlexSansArabic',
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? primaryColor
                                              : (isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors
                                                          .lightTextPrimary),
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${item.category} • ${context.l10n.targetCount(item.defaultTarget)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              AppIcons.checkCircleFill,
                                              color: primaryColor,
                                            )
                                          : null,
                                      onTap: () {
                                        _repo.setActiveDhikr(item);
                                        _paceOffsetSeconds = 0.0;
                                        if (_isAutoCounting) {
                                          _startAutoCountTimer();
                                        }
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

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(
            l10n.tasbeehAndIstighfar,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: l10n.countSettings,
              icon: const Icon(AppIcons.slidersHorizontal),
              onPressed: () => _showCountSettingsSheet(isDark, primaryColor),
            ),
            IconButton(
              tooltip: l10n.browseAllFormulas,
              icon: const Icon(AppIcons.listBullets),
              onPressed: _showDhikrPickerSheet,
            ),
            IconButton(
              tooltip: l10n.resetCycleCounter,
              icon: const Icon(AppIcons.arrowCounterClockwise),
              onPressed: _confirmReset,
            ),
          ],
        ),
        body: PatternBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 680;
                // العدّاد هو الإجراء الأساسي، فيأخذ أكبر مساحة.
                final circleSize = isCompact ? 205.0 : 250.0;
                // ارتفاع ثابت لمربع الذكر، فلا يقفز.
                final cardHeight = isCompact ? 180.0 : 205.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 14 : 18,
                    vertical: isCompact ? 8 : 12,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ١. التبديل بين الاستغفار والتسبيح.
                          _buildSectionSwitcher(isDark, primaryColor),
                          const SizedBox(height: 12),

                          // ٢. مربع الذكر الثابت.
                          _buildFixedDhikrCard(
                            dhikr,
                            isDark,
                            primaryColor,
                            cardHeight,
                          ),
                          SizedBox(height: isCompact ? 14 : 18),

                          // ٣. دائرة العدّ.
                          Center(
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _handleTap,
                                onLongPress: _toggleAutoCount,
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
                                        color:
                                            (isDark
                                                    ? AppColors.darkAccentGold
                                                    : AppColors.olive)
                                                .withValues(alpha: 0.12),
                                        blurRadius: 26,
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
                                      // حلقة التقدم.
                                      SizedBox(
                                        width: circleSize - 16,
                                        height: circleSize - 16,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 6,
                                          backgroundColor: isDark
                                              ? AppColors.darkBorder.withValues(
                                                  alpha: 0.3,
                                                )
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
                                      // الرقم والهدف وتلميح النقر.
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            context.l10n.digits(
                                              _repo.currentCount,
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Amiri',
                                              fontSize: isCompact ? 46 : 56,
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
                                                ? l10n.targetCount(
                                                    _repo.targetCount,
                                                  )
                                                : l10n.freeCount,
                                            style: TextStyle(
                                              fontSize: isCompact ? 13 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                        .lightTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              l10n.tapAnywhereToCount,
                                              style: TextStyle(
                                                fontSize: 12,
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
                          SizedBox(height: isCompact ? 10 : 14),

                          // ٤. العدّ التلقائي والتحكم بإيقاعه.
                          _buildAutoCountBar(isDark, primaryColor),
                          SizedBox(height: isCompact ? 10 : 14),

                          // ٥. إحصاءات اليوم والإجمالي.
                          _buildStatsRow(isDark, primaryColor),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// شريط العدّ التلقائي مع التحكم بإيقاعه.
  Widget _buildAutoCountBar(bool isDark, Color primaryColor) {
    final l10n = context.l10n;
    final pace = _currentPaceSeconds;
    final activeColor = isDark ? AppColors.darkAccentGold : primaryColor;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isAutoCounting
                ? activeColor.withValues(alpha: 0.6)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: _isAutoCounting ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isAutoCounting
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _toggleAutoCount,
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isAutoCounting
                      ? activeColor
                      : activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAutoCounting ? AppIcons.pause : AppIcons.play,
                      size: 18,
                      color: _isAutoCounting
                          ? (isDark ? Colors.black : Colors.white)
                          : activeColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isAutoCounting ? l10n.stopAutoCount : l10n.autoCount,
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isAutoCounting
                            ? (isDark ? Colors.black : Colors.white)
                            : activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            Container(
              height: 18,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(width: 6),

            // تسريع (-).
            IconButton(
              tooltip: l10n.decreasePace,
              icon: const Icon(AppIcons.minus, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              onPressed: _speedUpPace,
            ),

            // الإيقاع الحالي بالثواني.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.timer,
                    size: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l10n.smartPaceSeconds(pace),
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // إبطاء (+).
            IconButton(
              tooltip: l10n.increasePace,
              icon: const Icon(AppIcons.plus, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              onPressed: _slowDownPace,
            ),
          ],
        ),
      ),
    );
  }

  /// التبديل بين الاستغفار والتسبيح.
  Widget _buildSectionSwitcher(bool isDark, Color primaryColor) {
    final activeSection = _repo.activeSection;
    final istighfarCount = TasbeehDhikr.istighfarDhikrs.length;
    final tasbeehCount = TasbeehDhikr.tasbeehDhikrs.length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SectionTab(
              title: context.l10n.istighfar,
              count: istighfarCount,
              icon: AppIcons.flowerLotusFill,
              isSelected: activeSection == DhikrSection.istighfar,
              isDark: isDark,
              primaryColor: primaryColor,
              onTap: () => _onSectionSelected(DhikrSection.istighfar),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SectionTab(
              title: context.l10n.tasbeeh,
              count: tasbeehCount,
              icon: AppIcons.arrowsClockwise,
              isSelected: activeSection == DhikrSection.tasbeeh,
              isDark: isDark,
              primaryColor: primaryColor,
              onTap: () => _onSectionSelected(DhikrSection.tasbeeh),
            ),
          ),
        ],
      ),
    );
  }

  /// مربع الذكر بحجم ثابت لا يتغير بطول النص.
  Widget _buildFixedDhikrCard(
    TasbeehDhikr dhikr,
    bool isDark,
    Color primaryColor,
    double cardHeight,
  ) {
    final pool = _filteredDhikrs;
    final currentIndex = pool.indexWhere((d) => d.id == dhikr.id);
    final positionText = currentIndex >= 0
        ? context.l10n.formulaXOfY(currentIndex + 1, pool.length)
        : context.l10n.allFormulasCount(pool.length);

    // حجم الخط بحسب طول النص، ليتسع في المساحة الثابتة.
    final textLength = dhikr.arabicText.length;
    final double textFontSize = textLength > 120
        ? 15.5
        : textLength > 60
        ? 17.5
        : 21.0;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        // في RTL: السحب لليسار للتالي، ولليمين للسابق.
        if (velocity < -200) {
          _nextDhikr();
        } else if (velocity > 200) {
          _previousDhikr();
        }
      },
      child: SizedBox(
        height: cardHeight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              // ١. الرأس بارتفاع ثابت.
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.olive)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
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
                    Expanded(
                      child: Text(
                        positionText,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.copyDhikrTooltip,
                      icon: const Icon(AppIcons.copy, size: 16),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 28,
                      ),
                      onPressed: () => _copyDhikrText(dhikr.arabicText),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: _showDhikrPickerSheet,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.allFormulasCount(pool.length),
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              AppIcons.caretDown,
                              size: 16,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ٢. النص، ويملأ الارتفاع الباقي.
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: context.l10n.nextDhikr,
                      icon: const Directionality(
                        textDirection: TextDirection.ltr,
                        child: Icon(AppIcons.caretRight, size: 24),
                      ),
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      onPressed: _nextDhikr,
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            width: double.infinity,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                );
                              },
                              child: Container(
                                key: ValueKey<String>(dhikr.id),
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Text(
                                  dhikr.arabicText,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: textFontSize,
                                    fontWeight: FontWeight.bold,
                                    height: 1.45,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightPrimaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.previousDhikr,
                      icon: const Directionality(
                        textDirection: TextDirection.ltr,
                        child: Icon(AppIcons.caretLeft, size: 24),
                      ),
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      onPressed: _previousDhikr,
                    ),
                  ],
                ),
              ),

              // ٣. الفضل، كاملاً دون قص.
              if (dhikr.virtue.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground.withValues(alpha: 0.6)
                        : AppColors.comsilk,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.sparkleFill,
                        size: 13,
                        color: isDark
                            ? AppColors.darkAccentGold
                            : AppColors.oliveDark,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dhikr.virtue,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.handSwipeRight,
                        size: 13,
                        color:
                            (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary)
                                .withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.swipeOrTapToChange,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// لوحة لضبط الهدف والانتقال التلقائي، بعيداً عن شاشة العدّ.
  void _showCountSettingsSheet(bool isDark, Color primaryColor) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => ListenableBuilder(
        listenable: _repo,
        builder: (sheetContext, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.countSettings,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _buildControlsCard(isDark, primaryColor),
              ],
            ),
          ),
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
              final label = t == 0
                  ? context.l10n.freeCountOpen
                  : context.l10n.countTimes(t);

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
                                  ? AppColors.darkAccentGold.withValues(
                                      alpha: 0.2,
                                    )
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
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
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
                        ? AppIcons.arrowsClockwise
                        : AppIcons.prohibit,
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
                      context.l10n.autoAdvanceUponCompletion,
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

  /// إحصاءات اليوم والإجمالي.
  Widget _buildStatsRow(bool isDark, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: context.l10n.todayCount,
            count: _repo.todayTotalCount,
            icon: AppIcons.calendarCheck,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: context.l10n.lifetimeTotalCount,
            count: _repo.lifetimeTotalCount,
            icon: AppIcons.infinity,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
