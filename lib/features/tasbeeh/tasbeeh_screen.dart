import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import 'tasbeeh_model.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/ornaments.dart';
import '../onboarding/tour/section_guide.dart';

part 'tasbeeh_widgets.dart';
part 'tasbeeh_screen_sections.dart';

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
            GuideButton(topic: GuideTopic.tasbeeh),
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
}
