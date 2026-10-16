import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'quran_dua_model.dart';
import 'quran_dua_card.dart';
import 'quran_duas_repository.dart';

/// شاشة عرض قائمة أدعية القرآن الكريم الموثقة مع البحث الفوري والتصفية الموضوعية.
///
/// Screen listing all authentic Quranic supplications (أدعية من القرآن) in vertical order.
///
/// EDUCATIONAL NOTE:
/// Quranic Fidelity & Presentation:
/// 1. Comprehensive Catalog: 88 verified Quranic supplications with titles and categories.
/// 2. Clean Architecture: Rendered in a vertical [ListView.separated] with instant search and category filtering.
/// 3. Search: Supports search by text, title, surah name, category and ayah number.
class QuranDuasScreen extends StatefulWidget {
  /// ينشئ شاشة أدعية القرآن الكريم.
  const QuranDuasScreen({super.key});

  /// ينشئ حالة شاشة أدعية القرآن الكريم.
  @override
  State<QuranDuasScreen> createState() => _QuranDuasScreenState();
}

/// الحالة الداخلية لشاشة أدعية القرآن الكريم المسؤولة عن البحث وتصفية التصنيفات.
class _QuranDuasScreenState extends State<QuranDuasScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QuranDua> _filteredDuas = const [];
  String _selectedCategory = 'الكل';

  /// يهيئ قائمة الأدعية الكاملة ويربط مستمع التغير بحقل البحث.
  @override
  void initState() {
    super.initState();
    _filteredDuas = QuranDuasRepository.instance.getDuas();
    _searchController.addListener(_onFilterChanged);
  }

  /// يزيل مستمع البحث ويحرر موارد المتحكم عند إغلاق الشاشة.
  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// يحدّث قائمة الأدعية المعروضة عند تغير نص البحث.
  void _onFilterChanged() {
    setState(() {
      _filteredDuas = QuranDuasRepository.instance.search(
        _searchController.text,
        categoryFilter: _selectedCategory,
      );
    });
  }

  /// يغيّر التصنيف الموضوعي النشط ويعيد تصفية قائمة الأدعية.
  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _filteredDuas = QuranDuasRepository.instance.search(
        _searchController.text,
        categoryFilter: _selectedCategory,
      );
    });
  }

  /// يبني واجهة شاشة أدعية القرآن الكريم مع شريط البحث ورقاقات التصنيفات.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          title: Text(
            l10n.quranDuasTitle,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(114),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      // Search Input Field
                      Expanded(
                        child: Container(
                          height: 46,
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
                          child: TextField(
                            controller: _searchController,
                            textDirection: context.currentLanguage.direction,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.isArabic
                                  ? 'ابحث في أدعية القرآن الكريم...'
                                  : 'Search Quranic supplications...',
                              hintStyle: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkAccentGold
                                    : AppColors.lightPrimary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Duas Count Badge
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimary.withValues(alpha: 0.25)
                              : AppColors.lightPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.duasCountBadge(
                            l10n.isArabic
                                ? ArabicSearchNormalizer.toArabicDigits(_filteredDuas.length)
                                : _filteredDuas.length,
                          ),
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkAccentGold
                                : AppColors.lightPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal Categories Filter Chips
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: QuranDuasRepository.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = QuranDuasRepository.categories[index];
                      final isSelected = _selectedCategory == category;

                      final labelText = category == 'الكل' ? l10n.allDuasFilter : category;

                      return ChoiceChip(
                        label: Text(
                          labelText,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
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
                        onSelected: (_) => _onCategorySelected(category),
                        selectedColor: isDark
                            ? AppColors.darkAccentGold
                            : AppColors.lightPrimary,
                        backgroundColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                          ),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
        body: _filteredDuas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noDuasFound,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _filteredDuas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return QuranDuaCard(dua: _filteredDuas[index]);
                },
              ),
      ),
    );
  }
}
