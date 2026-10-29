import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import 'ahlulbayt_dua_reader_screen.dart';
import '../data/ahlulbayt_duas_repository.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_search_field.dart';

/// أدعية أهل البيت (عليهم السلام) والصحيفة السجادية، مع بحث وتصنيفات.
class AhlulbaytDuasScreen extends StatefulWidget {
  const AhlulbaytDuasScreen({super.key});

  @override
  State<AhlulbaytDuasScreen> createState() => _AhlulbaytDuasScreenState();
}

class _AhlulbaytDuasScreenState extends State<AhlulbaytDuasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final allCats = AhlulbaytDuasRepository.defaultDuas
        .map((d) => d.category.split(' ')[0])
        .toSet()
        .toList();
    return ['الكل', ...allCats];
  }

  List<AhlulbaytDua> get _filteredDuas {
    var list = AhlulbaytDuasRepository.defaultDuas;

    if (_selectedCategory != 'الكل') {
      list = list.where((d) => d.category.contains(_selectedCategory)).toList();
    }

    if (_searchQuery.trim().isEmpty) {
      return list;
    }

    final normQuery = ArabicSearchNormalizer.normalize(_searchQuery);
    return list.where((d) {
      final normTitle = ArabicSearchNormalizer.normalize(d.title);
      final normAuthor = ArabicSearchNormalizer.normalize(d.attributedTo);
      final normSummary = ArabicSearchNormalizer.normalize(d.summary);
      final normText = ArabicSearchNormalizer.normalize(d.content);

      return normTitle.contains(normQuery) ||
          normAuthor.contains(normQuery) ||
          normSummary.contains(normQuery) ||
          normText.contains(normQuery);
    }).toList();
  }

  void _copyDua(AhlulbaytDua dua) {
    Clipboard.setData(
      ClipboardData(
        text:
            '${dua.title}\n(${dua.attributedTo})\n\n${dua.content}\n\n— تطبيق تَدْبِير',
      ),
    );
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.itemCopied(dua.title),
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
    final filtered = _filteredDuas;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            l10n.ahlulbaytDuasScreenTitle,
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
                  hintText: l10n.searchAhlulbaytHint,
                  clearTooltip: l10n.clearText,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    final labelText = cat == 'الكل' ? l10n.allDuasFilter : cat;

                    return ChoiceChip(
                      label: Text(
                        labelText,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: isDark
                          ? AppColors.darkAccentGold
                          : primaryColor,
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.ahlulbaytDuasCountBadge(
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
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.magnifyingGlassMinus,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.noDuasFound,
                              style: const TextStyle(
                                fontFamily: 'IBMPlexSansArabic',
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final dua = filtered[index];
                          return _DuaCard(
                            dua: dua,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AhlulbaytDuaReaderScreen(dua: dua),
                                ),
                              );
                            },
                            onCopy: () => _copyDua(dua),
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

class _DuaCard extends StatelessWidget {
  final AhlulbaytDua dua;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _DuaCard({
    required this.dua,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dua.title,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dua.attributedTo,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isDark
                              ? AppColors.darkAccentGold
                              : primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.copyDuaTooltip,
                  icon: const Icon(AppIcons.copy, size: 17),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onCopy,
                ),
                const SizedBox(width: 4),
                Icon(
                  AppIcons.caretRight,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              dua.summary,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 12.5,
                height: 1.45,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // شارة التصنيف وعدد المقاطع.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkAccentGold : AppColors.olive)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dua.category,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkAccentGold
                          : AppColors.oliveDark,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  context.l10n.fullAuthenticText,
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
      ),
    );
  }
}
