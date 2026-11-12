import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/user_settings_model.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../quran/qcf/qcf_layout.dart';
import '../quran/screens/quran_screen.dart';
import '../../core/design_system/app_icons.dart';

/// الفواصل، للانتقال السريع إلى مواضعها، مع بحث فوري باسم السورة أو رقم الآية
/// أو نصها.
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
        resizeToAvoidBottomInset: false,
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
              return QuranRepository.instance.ayahMatches(
                item.surahNumber,
                item.ayahNumber,
                normalizedQuery,
              );
            }).toList();

            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: AppSearchField(
                    controller: _searchController,
                    hintText: l10n.searchBookmarksHint,
                    clearTooltip: l10n.clearText,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
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
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
                            final style =
                                UserDataStore.instance.settings.mushafStyle;
                            final displayPage = ayah == null
                                ? item.page
                                : QcfLayout.instance.pageFor(ayah, style);

                            return RepaintBoundary(
                              child: _BookmarkTile(
                                item: item,
                                surahName: surah.name,
                                ayahText: ayah?.text ?? '',
                                ayah: ayah,
                                displayPage: displayPage,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuranScreen(
                                        initialPage: displayPage,
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
                                      content: Text(l10n.bookmarkRemoved),
                                      action: SnackBarAction(
                                        label: l10n.undo,
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

/// بطاقة فاصل: اسم السورة ومقتطف من الآية.
class _BookmarkTile extends StatelessWidget {
  final BookmarkItem item;
  final String surahName;
  final String ayahText;
  final Ayah? ayah;
  final int? displayPage;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.item,
    required this.surahName,
    required this.ayahText,
    this.ayah,
    this.displayPage,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = UserDataStore.instance.settings.mushafStyle;
    final page =
        displayPage ??
        (ayah == null
            ? item.page
            : QcfLayout.instance.pageFor(ayah!, style));

    Widget fallbackSnippet() => Text(
      '﴿ $ayahText ﴾',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: UserDataStore.instance.quranFontFamily,
        fontSize: 14,
        color: isDark ? AppColors.nightQuranText : AppColors.dayQuranText,
      ),
    );

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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
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
                            ? ArabicSearchNormalizer.toArabicDigits(page)
                            : page,
                      ),
                      color: AppColors.cyberEmerald,
                      isCompact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (ayahText.isNotEmpty)
                  (style == MushafStyle.madinah && ayah != null)
                      ? QcfAyahText(
                          ayah: ayah!,
                          fontSize: 14,
                          height: 1.5,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          color: isDark
                              ? AppColors.nightQuranText
                              : AppColors.dayQuranText,
                          fallback: fallbackSnippet(),
                        )
                      : fallbackSnippet(),
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
