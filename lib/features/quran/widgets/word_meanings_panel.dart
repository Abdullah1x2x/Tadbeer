import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_models.dart';
import '../data/quran_repository.dart';

/// لوحة معاني الكلمات القرآنية المصاحبة لقراءة المصحف الشريف.
///
/// الميزات:
/// 1. تعرض الكلمات الصعبة المعتمدة في الصفحة الحالية فقط.
/// 2. تتحدث تلقائياً عند تقليب الصفحات في المصحف.
/// 3. تدعم التبديل السلس بين «المعنى المعجمي» و«البيان السياقي».
/// 4. تتيح إغلاق اللوحة أو إخفاء الشريط السفلي بالكامل.
/// 5. تعرض رسالة تفيد بعدم وجود كلمات تحتاج إلى شرح إذا خلت الصفحة منها.
/// 6. تطفو فوق مساحة القراءة بانسيابية دون التأثير على تخطيط صفحات المصحف.
class WordMeaningsPanel extends StatefulWidget {
  final int pageNumber;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final VoidCallback? onDismiss;

  /// ينشئ لوحة معاني الكلمات القرآنية للصفحة المحددة.
  const WordMeaningsPanel({
    super.key,
    required this.pageNumber,
    required this.isExpanded,
    required this.onToggle,
    required this.onClose,
    this.onDismiss,
  });

  /// ينشئ الحالة التفاعلية للوحة معاني الكلمات.
  @override
  State<WordMeaningsPanel> createState() => _WordMeaningsPanelState();
}

/// الحالة التفاعلية للوحة معاني الكلمات القرآنية المصاحبة للمصحف.
class _WordMeaningsPanelState extends State<WordMeaningsPanel> {
  /// يبني واجهة اللوحة العائمة سواء في الوضع المطوي أو الموسع.
  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    final meanings = repo.getWordMeaningsForPage(widget.pageNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageDigits = ArabicSearchNormalizer.toArabicDigits(widget.pageNumber);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(
          left: widget.isExpanded ? 12 : 16,
          right: widget.isExpanded ? 12 : 16,
          bottom: widget.isExpanded ? 12 : 12,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.comsilkLight)
              .withValues(alpha: widget.isExpanded ? 0.98 : 0.92),
          borderRadius: BorderRadius.circular(widget.isExpanded ? 22 : 20),
          border: Border.all(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.8),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: widget.isExpanded
                ? _buildExpandedContent(
                    context,
                    repo,
                    meanings,
                    pageDigits,
                    isDark,
                  )
                : _buildCollapsedBar(context, meanings, isDark),
          ),
        ),
      ),
    );
  }

  /// يبني الشريط السفلي المصغر الذي يعرض عدد الكلمات المشروحة في الصفحة.
  Widget _buildCollapsedBar(
    BuildContext context,
    List<QuranWordMeaning> meanings,
    bool isDark,
  ) {
    final countDigits = ArabicSearchNormalizer.toArabicDigits(meanings.length);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 18,
                    color: isDark ? AppColors.oliveLight : AppColors.olive,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'معاني الكلمات ($countDigits)',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.oliveDark,
                  ),
                ],
              ),
            ),
          ),
          if (widget.onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'إخفاء الشريط',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              color: isDark ? AppColors.nightSubtitle : AppColors.oliveDark,
              onPressed: widget.onDismiss,
            ),
          ],
        ],
      ),
    );
  }

  /// يبني المحتوى الموسع للوحة معاني الكلمات مع قائمة الكلمات أو حالة الفراغ.
  Widget _buildExpandedContent(
    BuildContext context,
    QuranRepository repo,
    List<QuranWordMeaning> meanings,
    String pageDigits,
    bool isDark,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = (screenHeight * 0.44).clamp(280.0, 420.0);

    return SizedBox(
      height: panelHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 2),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.nightSubtitle : AppColors.oliveDark)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 16,
              top: 6,
              bottom: 8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 20,
                  color: isDark ? AppColors.oliveLight : AppColors.olive,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'معاني كلمات صفحة $pageDigits',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark ? AppColors.olive : AppColors.oliveLight)
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${ArabicSearchNormalizer.toArabicDigits(meanings.length)} كلمات',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.oliveLight
                                : AppColors.oliveDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'إغلاق اللوحة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.8,
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.6),
          ),

          // Content List or Empty State
          Expanded(
            child: meanings.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: meanings.length,
                    separatorBuilder: (_, index) => Divider(
                      height: 16,
                      thickness: 0.5,
                      color:
                          (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final item = meanings[index];
                      final surah = repo.getSurah(item.surah);
                      return _WordMeaningTile(
                        item: item,
                        surahName: surah.name,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// يبني واجهة الحالة الفارغة عند عدم وجود كلمات تحتاج إلى شرح في الصفحة الحالية.
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 32,
              color: isDark ? AppColors.nightSubtitle : AppColors.oliveDark,
            ),
            const SizedBox(height: 10),
            Text(
              'لا توجد كلمات تحتاج إلى شرح في هذه الصفحة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يعرض نافذة سفلية بتفاصيل معنى الكلمة القرآنية ومصدرها المعجمي المعتمد.
void _showWordDetailsModal(
  BuildContext context,
  QuranWordMeaning item,
  String surahName,
  bool isDark,
) {
  final ayahDigits = ArabicSearchNormalizer.toArabicDigits(item.ayah);
  final pageDigits = ArabicSearchNormalizer.toArabicDigits(item.page);

  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.word,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.olive,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.olive : AppColors.oliveLight)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'سورة $surahName · آية $ayahDigits · ص $pageDigits',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.oliveDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'المعنى اللغوي المعجمي:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.meaning,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: isDark ? AppColors.oliveLight : AppColors.olive,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.sourceName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    if (item.sourceUrl != null)
                      Text(
                        'توثيق معتمد',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.oliveLight
                              : AppColors.oliveDark,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// عنصر يعرض الكلمة القرآنية ومعناها المختصر داخل لوحة معاني الصفحة.
class _WordMeaningTile extends StatelessWidget {
  final QuranWordMeaning item;
  final String surahName;
  final bool isDark;

  /// ينشئ عنصر عرض الكلمة القرآنية ومعناها.
  const _WordMeaningTile({
    required this.item,
    required this.surahName,
    required this.isDark,
  });

  /// يبني واجهة عنصر الكلمة القرآنية ومعناها مع إمكانية النقر لعرض التفاصيل.
  @override
  Widget build(BuildContext context) {
    final ayahDigits = ArabicSearchNormalizer.toArabicDigits(item.ayah);

    return InkWell(
      onTap: () => _showWordDetailsModal(context, item, surahName, isDark),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Word
                Expanded(
                  child: Text(
                    item.word,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.oliveLight : AppColors.olive,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Surah and Ayah reference
                Text(
                  'سورة $surahName · آية $ayahDigits',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            // Arabic Meaning (strictly WITHOUT reference name in tile)
            Text(
              item.meaning,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
