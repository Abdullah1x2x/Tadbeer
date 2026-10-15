import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../features/quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';

/// شاشة عرض الآيات المميزة بالألوان مع دعم البحث الفوري.
///
/// Screen displaying all user-highlighted ayahs.
///
/// Supports instant local search filtering by Surah name, Ayah number, or verse text.
class HighlightsScreen extends StatefulWidget {
  /// ينشئ شاشة الآيات المميزة.
  const HighlightsScreen({super.key});

  /// ينشئ حالة شاشة التظليلات.
  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

/// الحالة الداخلية لشاشة الآيات المميزة وإدارة تصفية البحث.
class _HighlightsScreenState extends State<HighlightsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// يحرر موارد متحكم حقل البحث عند إغلاق الشاشة.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// يبني واجهة شاشة الآيات المميزة وقائمة النتائج القابلة للنقر.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.highlights,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final allHighlights = UserDataStore.instance.highlights;

            if (allHighlights.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 64,
                      color: AppColors.border(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noHighlightsYet,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                    ),
                  ],
                ),
              );
            }

            final normalizedQuery = ArabicSearchNormalizer.normalize(
              _searchQuery,
            );
            final highlights = allHighlights.where((item) {
              if (normalizedQuery.isEmpty) return true;
              final surah = QuranRepository.instance.getSurah(item.surahNumber);
              final ayah = QuranRepository.instance.getAyah(
                item.surahNumber,
                item.ayahNumber,
              );
              final surahNorm = ArabicSearchNormalizer.normalize(surah.name);
              final ayahTextNorm = ayah != null
                  ? ArabicSearchNormalizer.normalize(ayah.text)
                  : '';
              final ayahNumStr = item.ayahNumber.toString();

              return surahNorm.contains(normalizedQuery) ||
                  ayahTextNorm.contains(normalizedQuery) ||
                  ayahNumStr.contains(normalizedQuery);
            }).toList();

            return Column(
              children: [
                // Search Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: l10n.searchHighlightsHint,
                      hintStyle: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.daySubtitle,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.olive,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          isDark ? AppColors.darkSurface : AppColors.comsilk,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Highlights List / Empty Search State
                Expanded(
                  child: highlights.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noSearchResults,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: highlights.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = highlights[index];
                            final surah = QuranRepository.instance.getSurah(
                              item.surahNumber,
                            );
                            final ayah = QuranRepository.instance.getAyah(
                              item.surahNumber,
                              item.ayahNumber,
                            );
                            final color =
                                AppColors.highlightColors[item.colorIndex.clamp(
                              0,
                              AppColors.highlightColors.length - 1,
                            )];

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuranScreen(
                                      initialPage: item.page,
                                      targetSurahNumber: item.surahNumber,
                                      targetAyahNumber: item.ayahNumber,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.comsilk,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.8),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.oliveDark
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                context.l10n.ayahReference(
                                                  surah.name,
                                                  context.currentLanguage == AppLanguage.arabic
                                                      ? ArabicSearchNormalizer.toArabicDigits(item.ayahNumber)
                                                      : item.ayahNumber,
                                                ),
                                                style: TextStyle(
                                                  fontFamily: context.currentLanguage == AppLanguage.arabic ? 'Amiri' : null,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? AppColors.darkTextPrimary
                                                      : AppColors
                                                          .lightPrimaryDark,
                                                ),
                                              ),
                                              Text(
                                                context.l10n.pageAbbr(
                                                  context.currentLanguage == AppLanguage.arabic
                                                      ? ArabicSearchNormalizer.toArabicDigits(item.page)
                                                      : item.page,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (ayah != null)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '﴿ ${ayah.text} ﴾',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textDirection: TextDirection.rtl,
                                                style: TextStyle(
                                                  fontFamily: 'AmiriQuran',
                                                  fontSize: 14,
                                                  color: isDark
                                                      ? AppColors.nightQuranText
                                                      : AppColors.dayQuranText,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 20,
                                      ),
                                      tooltip: l10n.removeHighlight,
                                      onSelected: (val) {
                                        if (val == 'delete') {
                                          UserDataStore.instance.removeHighlight(
                                            item.surahNumber,
                                            item.ayahNumber,
                                          );
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.removeHighlight,
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
