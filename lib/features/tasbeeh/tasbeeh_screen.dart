import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import 'tasbeeh_model.dart';
import 'tasbeeh_repository.dart';

/// شاشة الاستغفار والتسبيح (سبحة إلكترونية مبسطة ومحراب هادئ للذكر).
///
/// تفصل ببساطة ودون مبالغة بين قسمي "الاستغفار" و"التسبيح"
/// مع تثبيت تام لحجم مربع عرض الذكر لمنع اهتزاز أو قفز الشاشة أثناء التقليب.
class TasbeehScreen extends StatefulWidget {
  /// القسم المبدئي المراد فتحه عند الدخول (اختياري).
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
    _repo.removeListener(_onRepoChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  /// القسم الفعال حالياً في السبحة.
  DhikrSection get _currentSection => _repo.activeSection;

  /// الأذكار المفلترة بحسب القسم النشط فقط (استغفار أو تسبيح).
  List<TasbeehDhikr> get _filteredDhikrs {
    return _currentSection == DhikrSection.istighfar
        ? TasbeehDhikr.istighfarDhikrs
        : TasbeehDhikr.tasbeehDhikrs;
  }

  /// التبديل المباشر بين الاستغفار والتسبيح.
  void _onSectionSelected(DhikrSection section) {
    if (_repo.activeSection == section) return;
    HapticFeedback.selectionClick();
    _repo.setActiveSection(section);
  }

  /// الانتقال إلى الذكر التالي ضمن باقة القسم الفعال.
  void _nextDhikr() {
    HapticFeedback.selectionClick();
    _repo.nextDhikr(pool: _filteredDhikrs);
  }

  /// الانتقال إلى الذكر السابق ضمن باقة القسم الفعال.
  void _previousDhikr() {
    HapticFeedback.selectionClick();
    _repo.previousDhikr(pool: _filteredDhikrs);
  }

  /// معالجة نقرة التسبيح وتشغيل الأثر الحركي والحسي.
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

  /// نسخ نص الذكر الشريف إلى الحافظة.
  void _copyDhikrText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ نص الذكر إلى الحافظة بنجاح.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Amiri', fontSize: 13),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// حوار تأكيد تصفير عداد الدورة الحالية.
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

  /// فتح نافذة استعراض واختيار الصيغ المبسطة.
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
              final matchesQuery = sheetSearchQuery.isEmpty ||
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
                            Expanded(
                              child: Text(
                                'صيغ الاستغفار والتسبيح (${allDhikrs.length})',
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

                        // مفتاح تبديل الأقسام داخل النافذة
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
                                    'الاستغفار (${TasbeehDhikr.istighfarDhikrs.length})',
                                isSelected: sheetSection == DhikrSection.istighfar,
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
                                    'التسبيح (${TasbeehDhikr.tasbeehDhikrs.length})',
                                isSelected: sheetSection == DhikrSection.tasbeeh,
                                isDark: isDark,
                                primaryColor: primaryColor,
                                onTap: () {
                                  setSheetState(() {
                                    sheetSection = DhikrSection.tasbeeh;
                                  });
                                },
                              ),
                              _SheetSectionTab(
                                title: 'الكل (${allDhikrs.length})',
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

                        // حقل البحث
                        TextField(
                          onChanged: (val) {
                            setSheetState(() {
                              sheetSearchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث في نصوص الأذكار...',
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

                        // قائمة النتائج
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text('لا توجد صيغ مطابقة للبحث'),
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
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
              tooltip: 'استعراض كل الصيغ',
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
            final circleSize = isCompact ? 175.0 : 215.0;
            // تثبيت صارم لارتفاع مربع عرض الذكر لمنع أي قفز أو تغير في حجمه
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
                      // 1. مفتاح التبديل المباشر بين الاستغفار والتسبيح (بدون مبالغة)
                      _buildSectionSwitcher(isDark, primaryColor),
                      const SizedBox(height: 12),

                      // 2. مربع عرض الذكر ذو الحجم الثابت تماماً
                      _buildFixedDhikrCard(
                        dhikr,
                        isDark,
                        primaryColor,
                        cardHeight,
                      ),
                      SizedBox(height: isCompact ? 14 : 18),

                      // 3. الدائرة التفاعلية للتسبيح والعدّ
                      Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
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
                                  // الرقم والهدف ورسالة النقر
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_repo.currentCount}',
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
                      SizedBox(height: isCompact ? 14 : 18),

                      // 4. بطاقة ضبط الهدف + مفتاح التبديل التلقائي
                      _buildControlsCard(isDark, primaryColor),
                      const SizedBox(height: 12),

                      // 5. شريط الإحصائيات (اليوم والإجمالي)
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
  );
}

  /// مفتاح التبديل المباشر بين الاستغفار والتسبيح.
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
              title: 'الاستغفار',
              count: istighfarCount,
              icon: Icons.spa_rounded,
              isSelected: activeSection == DhikrSection.istighfar,
              isDark: isDark,
              primaryColor: primaryColor,
              onTap: () => _onSectionSelected(DhikrSection.istighfar),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SectionTab(
              title: 'التسبيح',
              count: tasbeehCount,
              icon: Icons.motion_photos_on_rounded,
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

  /// مربع عرض الذكر ذو الحجم الثابت تماماً (لا يكبر ولا يصغر بتغير النص).
  Widget _buildFixedDhikrCard(
    TasbeehDhikr dhikr,
    bool isDark,
    Color primaryColor,
    double cardHeight,
  ) {
    final pool = _filteredDhikrs;
    final currentIndex = pool.indexWhere((d) => d.id == dhikr.id);
    final positionText = currentIndex >= 0
        ? 'صيغة ${currentIndex + 1} من ${pool.length}'
        : '${pool.length} صيغة';

    // ضبط حجم الخط العربي ليتناسب مع طول النص ضمن المساحة الثابتة
    final textLength = dhikr.arabicText.length;
    final double textFontSize = textLength > 120
        ? 15.5
        : textLength > 60
            ? 17.5
            : 21.0;

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
              // 1. شريط الرأس ذو الارتفاع الثابت (28 بكسل)
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkAccentGold
                                : AppColors.olive)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dhikr.category,
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
                        positionText,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'نسخ نص الذكر',
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 28),
                      onPressed: () => _copyDhikrText(dhikr.arabicText),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: _showDhikrPickerSheet,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'كل الصيغ (${pool.length})',
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. منطقة النص المتمددة رأسياً ذات الارتفاع الثابت
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'الذكر السابق',
                      icon: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 18),
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      onPressed: _previousDhikr,
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
                      tooltip: 'الذكر التالي',
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      onPressed: _nextDhikr,
                    ),
                  ],
                ),
              ),

              // 3. شريط الفضيلة ذو الارتفاع الثابت (34 بكسل)
              SizedBox(
                height: 34,
                child: dhikr.virtue.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                                  .withValues(alpha: 0.6)
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
                                dhikr.virtue,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
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
                          Text(
                            'اسحب أفقياً أو انقر للتبديل',
                            style: TextStyle(
                              fontSize: 11,
                              color: (isDark
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

  /// بطاقة ضبط الهدف المطلوب وتفعيل التبديل التلقائي.
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

  /// شريط إحصائيات الاستغفار والتسبيح اليومي والإجمالي.
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

/// زر تبويب أنيق ومباشر للاختيار بين الاستغفار والتسبيح.
class _SectionTab extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const _SectionTab({
    required this.title,
    required this.count,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkAccentGold : AppColors.oliveDark)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$title ($count)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تبويب فرعي داخل نافذة استعراض الصيغ.
class _SheetSectionTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const _SheetSectionTab({
    required this.title,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.darkAccentGold
                    : AppColors.oliveDark)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  }
}

/// بطاقة إحصاءات مصغرة ذات تصميم هادئ.
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
