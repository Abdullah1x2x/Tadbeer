import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../core/design_system/app_icons.dart';
import 'word_details_sheet.dart';
import '../../../app/localization.dart';

/// لوحة معاني كلمات الصفحة الحالية، تطفو فوق المصحف دون أن تغيّر تخطيطه.
///
/// تتحدث مع تقليب الصفحات، وتبدّل بين «المعنى المعجمي» و«البيان السياقي»، وتقول
/// إن خلت الصفحة من كلمات تحتاج شرحاً.
class WordMeaningsPanel extends StatefulWidget {
  final int pageNumber;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final VoidCallback? onDismiss;

  const WordMeaningsPanel({
    super.key,
    required this.pageNumber,
    required this.isExpanded,
    required this.onToggle,
    required this.onClose,
    this.onDismiss,
  });

  @override
  State<WordMeaningsPanel> createState() => _WordMeaningsPanelState();
}

class _WordMeaningsPanelState extends State<WordMeaningsPanel> {
  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    final meanings = repo.getWordMeaningsForPage(widget.pageNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageDigits = context.l10n.digits(widget.pageNumber);

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

  /// الشريط المطوي: عدد الكلمات المشروحة في الصفحة.
  Widget _buildCollapsedBar(
    BuildContext context,
    List<QuranWordMeaning> meanings,
    bool isDark,
  ) {
    final countDigits = context.l10n.digits(meanings.length);

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
                    AppIcons.bookOpenTextFill,
                    size: 18,
                    color: isDark ? AppColors.oliveLight : AppColors.olive,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.wordMeaningsCount(countDigits),
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    AppIcons.caretUp,
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
              icon: const Icon(AppIcons.x, size: 18),
              tooltip: context.l10n.hideBar,
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

  /// اللوحة الموسّعة: قائمة الكلمات أو الحالة الفارغة.
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
                  AppIcons.bookOpenTextFill,
                  size: 20,
                  color: isDark ? AppColors.oliveLight : AppColors.olive,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.pageWordMeanings(pageDigits),
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
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
                          context.l10n.wordsCount(
                            context.l10n.digits(meanings.length),
                          ),
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
                  icon: const Icon(AppIcons.x, size: 22),
                  tooltip: context.l10n.closePanel,
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

  /// الحالة الفارغة حين لا كلمات تحتاج شرحاً في الصفحة.
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.checkCircle,
              size: 32,
              color: isDark ? AppColors.nightSubtitle : AppColors.oliveDark,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.noPageMeanings,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
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

/// الكلمة ومعناها المختصر في لوحة الصفحة.
class _WordMeaningTile extends StatelessWidget {
  final QuranWordMeaning item;
  final String surahName;
  final bool isDark;

  const _WordMeaningTile({
    required this.item,
    required this.surahName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showWordDetailsSheet(context, item, surahName, isDark),
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
                Text(
                  context.l10n.ayahReference(surahName, item.ayah),
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
            // المعنى وحده، دون اسم المصدر.
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
