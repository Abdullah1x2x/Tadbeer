import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/sunnah_duas_repository.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_search_field.dart';

/// أدعية السنة النبوية أو جوامع الدعاء، مع بحث.
class GeneralDuasListScreen extends StatefulWidget {
  final String title;
  final List<GeneralDuaItem> items;

  const GeneralDuasListScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<GeneralDuasListScreen> createState() => _GeneralDuasListScreenState();
}

class _GeneralDuasListScreenState extends State<GeneralDuasListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GeneralDuaItem> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return widget.items;
    final normQuery = ArabicSearchNormalizer.normalize(_searchQuery);
    return widget.items.where((d) {
      final normTitle = ArabicSearchNormalizer.normalize(d.title);
      final normText = ArabicSearchNormalizer.normalize(d.text);
      final normOccasion = ArabicSearchNormalizer.normalize(d.occasion);
      return normTitle.contains(normQuery) ||
          normText.contains(normQuery) ||
          normOccasion.contains(normQuery);
    }).toList();
  }

  void _copyDua(GeneralDuaItem item) {
    Clipboard.setData(
      ClipboardData(text: '${item.title}\n\n${item.text}\n\n— ${item.source}'),
    );
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.itemCopied(item.title),
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
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final filtered = _filteredItems;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: l10n.searchGeneralDuasHint(widget.title),
                  clearTooltip: l10n.clearText,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.generalDuasCountBadge(
                        l10n.isArabic
                            ? ArabicSearchNormalizer.toArabicDigits(
                                filtered.length,
                              )
                            : filtered.length,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? AppColors.darkAccentGold
                                              : AppColors.olive)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.duaIndex(
                                    l10n.isArabic
                                        ? ArabicSearchNormalizer.toArabicDigits(
                                            index + 1,
                                          )
                                        : (index + 1),
                                  ),
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
                                  item.title,
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.copyDuaTooltip,
                                icon: const Icon(AppIcons.copy, size: 17),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () => _copyDua(item),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.occasion,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkAccentGold
                                      : primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.source,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
