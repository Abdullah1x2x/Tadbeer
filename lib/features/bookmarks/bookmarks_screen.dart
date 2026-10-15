import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../features/bookmarks/bookmark_model.dart';
import '../../features/quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';

/// شاشة عرض قائمة الإشارات المرجعية للانتقال السريع إلى مواضع الآيات في المصحف.
///
/// Screen listing all bookmarked ayahs for quick recitation navigation.
///
/// Supports instant local search filtering by Surah name, Ayah number, or verse text.
class BookmarksScreen extends StatefulWidget {
  /// ينشئ شاشة الإشارات المرجعية.
  const BookmarksScreen({super.key});

  /// ينشئ حالة شاشة الإشارات المرجعية.
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

/// الحالة الداخلية لشاشة الإشارات المرجعية المسؤولة عن البحث والتصفية الفورية.
class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// يحرر موارد متحكم حقل البحث عند إغلاق الشاشة.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// يبني واجهة شاشة الإشارات المرجعية مع حقل البحث وقائمة الفواصل.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.bookmarks,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final allBookmarks = UserDataStore.instance.bookmarks;

            if (allBookmarks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: AppColors.border(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noBookmarksYet,
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
            final bookmarks = allBookmarks.where((item) {
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
                      hintText: l10n.searchBookmarksHint,
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

                // Bookmarks List / Empty Query Results
                Expanded(
                  child: bookmarks.isEmpty
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
                          itemCount: bookmarks.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = bookmarks[index];
                            final surah = QuranRepository.instance.getSurah(
                              item.surahNumber,
                            );
                            final ayah = QuranRepository.instance.getAyah(
                              item.surahNumber,
                              item.ayahNumber,
                            );

                            return _BookmarkTile(
                              item: item,
                              surahName: surah.name,
                              ayahText: ayah?.text ?? '',
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
                              onDelete: () => UserDataStore.instance
                                  .removeBookmark(item.id),
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

/// عنصر واجهة يمثل بطاقة إشارة مرجعية واحدة مع اسم السورة ومقتطف الآية.
class _BookmarkTile extends StatelessWidget {
  final BookmarkItem item;
  final String surahName;
  final String ayahText;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// ينشئ بطاقة الإشارة المرجعية.
  const _BookmarkTile({
    required this.item,
    required this.surahName,
    required this.ayahText,
    required this.onTap,
    required this.onDelete,
  });

  /// يبني بطاقة الإشارة المرجعية مع زر الحذف والانتقال للمصحف.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilk,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.bookmark,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.ayahReference(
                          surahName,
                          context.currentLanguage == AppLanguage.arabic
                              ? ArabicSearchNormalizer.toArabicDigits(item.ayahNumber)
                              : item.ayahNumber,
                        ),
                        style: TextStyle(
                          fontFamily: context.currentLanguage == AppLanguage.arabic ? 'Amiri' : null,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.comsilk
                              : AppColors.oliveDark,
                        ),
                      ),
                      Text(
                        context.l10n.pageAbbr(
                          context.currentLanguage == AppLanguage.arabic
                              ? ArabicSearchNormalizer.toArabicDigits(item.page)
                              : item.page,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.olive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (ayahText.isNotEmpty)
                    Text(
                      '﴿ $ayahText ﴾',
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
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) {
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.removeBookmark,
                        style: const TextStyle(color: Colors.redAccent),
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
  }
}
