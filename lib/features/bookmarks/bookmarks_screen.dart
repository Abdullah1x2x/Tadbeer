import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/quran/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import '../../core/design_system/app_icons.dart';

/// الفواصل، للانتقال السريع إلى مواضعها، مع بحث فوري باسم السورة أو رقم الآية أو نصها.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final allBookmarks = UserDataStore.instance.bookmarks;

            if (allBookmarks.isEmpty) {
              return EmptyState(
                icon: AppIcons.bookmarkSimple,
                title: l10n.noBookmarksYet,
                hint: l10n.bookmarksEmptyHint,
                actionLabel: l10n.openMushaf,
                actionIcon: AppIcons.bookOpenFill,
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuranScreen(
                      initialPage: UserDataStore.instance.readingPosition.page,
                    ),
                  ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.comsilk,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: AppTokens.borderHairline,
                      ),
                      boxShadow: AppTokens.cardShadow(isDark: isDark),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: l10n.searchBookmarksHint,
                        hintStyle: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 14,
                          color: isDark
                              ? AppColors.nightSubtitle
                              : AppColors.daySubtitle,
                        ),
                        prefixIcon: Icon(
                          AppIcons.magnifyingGlass,
                          color: AppColors.cyberEmerald,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                tooltip: context.l10n.clearText,
                                icon: const Icon(AppIcons.x, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: bookmarks.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noSearchResults,
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
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
                              onDelete: () {
                                UserDataStore.instance.removeBookmark(item.id);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.isArabic
                                          ? 'تم حذف الفاصلة المرجعية'
                                          : 'Bookmark removed',
                                    ),
                                    action: SnackBarAction(
                                      label: l10n.isArabic ? 'تراجع' : 'Undo',
                                      onPressed: () {
                                        UserDataStore.instance.putBookmark(
                                          item,
                                        );
                                      },
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
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

/// بطاقة فاصل: اسم السورة ومقتطف من الآية.
class _BookmarkTile extends StatelessWidget {
  final BookmarkItem item;
  final String surahName;
  final String ayahText;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.item,
    required this.surahName,
    required this.ayahText,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FuturisticCard(
      onTap: onTap,
      accentColor: AppColors.cyberEmerald,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cyberEmerald.withValues(
                alpha: isDark ? 0.15 : 0.10,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(
                color: AppColors.cyberEmerald.withValues(alpha: 0.3),
                width: AppTokens.borderHairline,
              ),
            ),
            child: Icon(
              AppIcons.bookmarkSimpleFill,
              color: AppColors.cyberEmerald,
              size: 20,
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
                            ? ArabicSearchNormalizer.toArabicDigits(
                                item.ayahNumber,
                              )
                            : item.ayahNumber,
                      ),
                      style: TextStyle(
                        fontFamily:
                            context.currentLanguage == AppLanguage.arabic
                            ? 'IBMPlexSansArabic'
                            : null,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.comsilk : AppColors.oliveDark,
                      ),
                    ),
                    FuturisticBadge(
                      label: context.l10n.pageAbbr(
                        context.currentLanguage == AppLanguage.arabic
                            ? ArabicSearchNormalizer.toArabicDigits(item.page)
                            : item.page,
                      ),
                      color: AppColors.cyberEmerald,
                      isCompact: true,
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
            icon: appMenuIcon,
            onSelected: (val) {
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              appMenuItem(
                value: 'delete',
                icon: AppIcons.trash,
                label: context.l10n.removeBookmark,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
