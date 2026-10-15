import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../features/ayah_links/ayah_link_model.dart';
import '../../features/ayah_links/ayah_link_repository.dart';
import '../../features/quran/data/quran_repository.dart';
import 'ayah_link_detail_screen.dart';
import 'curated_pathways.dart';
import 'widgets/ayah_link_qr_dialog.dart';
import 'widgets/create_link_dialog.dart';

/// الشاشة الرئيسية لإدارة وعرض روابط الآيات التدبرية الخاصة بالمستخدم.
///
/// Main screen managing the user's personal Ayah Links (روابط الآيات).
class AyahLinksScreen extends StatefulWidget {
  /// ينشئ الشاشة الرئيسية لروابط الآيات.
  const AyahLinksScreen({super.key});

  /// ينشئ حالة شاشة روابط الآيات.
  @override
  State<AyahLinksScreen> createState() => _AyahLinksScreenState();
}

/// الحالة الداخلية لشاشة روابط الآيات المسؤولة عن البحث والإنشاء والاستيراد.
class _AyahLinksScreenState extends State<AyahLinksScreen> {
  final AyahLinkRepository _repo = AyahLinkRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// يحرر موارد متحكم حقل البحث عند إغلاق الشاشة.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// يفتح نافذة إنشاء رابط آيات جديد وينتقل لتفاصيله فور إنشائه.
  Future<void> _createLink() async {
    final created = await CreateLinkDialog.show(context);
    if (created != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AyahLinkDetailScreen(linkId: created.id),
        ),
      );
    }
  }

  /// يفتح نافذة تعديل بيانات رابط آيات موجود.
  Future<void> _editLink(AyahLinkItem link) async {
    await CreateLinkDialog.show(context, existingLink: link);
  }

  /// يعرض نافذة تأكيد لحذف رابط الآيات المحدد.
  Future<void> _confirmDelete(AyahLinkItem link) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(
          l10n.isArabic
              ? 'هل أنت متأكد من رغبتك في حذف رابط «${link.title}»؟'
              : 'Are you sure you want to delete link "${link.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _repo.deleteLink(link.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isArabic
                  ? 'تم حذف رابط «${link.title}»'
                  : 'Link "${link.title}" deleted',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// يفتح نافذة استيراد رابط آيات عبر رمز الاستجابة السريعة.
  Future<void> _importFromQr() async {
    await AyahLinkQrDialog.showImportDialog(context, repo: _repo);
  }

  /// يعرض اللوحة السفلية للمسارات التدبرية المقترحة الجاهزة للاستيراد.
  void _showCuratedPathwaysSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Directionality(
          textDirection: context.currentLanguage.direction,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.explore_rounded, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.curatedPathways,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: CuratedPathwaysRegistry.pathways.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final pathway = CuratedPathwaysRegistry.pathways[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.comsilkLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pathway.title,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pathway.category,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pathway.description,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? AppColors.nightSubtitle
                                      : AppColors.daySubtitle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.l10n.linkedAyahsCount(
                                      context.l10n.isArabic
                                          ? ArabicSearchNormalizer.toArabicDigits(pathway.verses.length)
                                          : pathway.verses.length,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.nightSubtitle
                                          : AppColors.daySubtitle,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(sheetCtx);
                                      final imported =
                                          await CuratedPathwaysRegistry
                                              .importPathway(
                                        pathway,
                                        repo: _repo,
                                      );
                                      if (mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AyahLinkDetailScreen(
                                              linkId: imported.id,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text(
                                      context.l10n.importPathway,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
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
      },
    );
  }

  /// يبني واجهة شاشة روابط الآيات مع شريط البحث وقائمة الروابط.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.ayahLinks,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.explore_outlined),
              tooltip: l10n.curatedPathways,
              onPressed: _showCuratedPathwaysSheet,
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: l10n.importFromQrCode,
              onPressed: _importFromQr,
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final links = _searchQuery.isEmpty
                ? _repo.allLinks
                : _repo.searchLinks(_searchQuery);

            return Column(
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: l10n.searchAyahLinksHint,
                      prefixIcon: Icon(Icons.search, color: primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.comsilkLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.border(context),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: links.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.hub_outlined,
                                    size: 36,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? l10n.noAyahLinkSearchResults
                                      : l10n.noAyahLinksYet,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? l10n.tryAnotherAyahLinkSearch
                                      : l10n.ayahLinksSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.nightSubtitle
                                        : AppColors.daySubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: links.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final link = links[index];
                            final uniqueSurahs = <int>{};
                            for (final v in link.verses) {
                              uniqueSurahs.add(v.surahNumber);
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AyahLinkDetailScreen(linkId: link.id),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.border(context),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.04,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title & Options
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.hub_outlined,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                link.title,
                                                style: TextStyle(
                                                  fontFamily: 'Amiri',
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? AppColors
                                                            .darkTextPrimary
                                                      : AppColors
                                                            .lightPrimaryDark,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                l10n.linkedAyahsCount(
                                                  l10n.isArabic
                                                      ? ArabicSearchNormalizer.toArabicDigits(link.verses.length)
                                                      : link.verses.length,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
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
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _editLink(link);
                                            } else if (val == 'delete') {
                                              _confirmDelete(link);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(l10n.editTitleAndDescription),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    l10n.deleteAyahLink,
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

                                    // Description snippet (if any)
                                    if (link.description != null &&
                                        link.description!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        link.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: isDark
                                              ? AppColors.nightSubtitle
                                              : AppColors.daySubtitle,
                                        ),
                                      ),
                                    ],

                                    // Surahs Chips (if any)
                                    if (uniqueSurahs.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: uniqueSurahs.take(4).map((
                                          sNum,
                                        ) {
                                          final s = QuranRepository.instance
                                              .getSurah(sNum);
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              s.name,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createLink,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(l10n.newAyahLink),
        ),
      ),
    );
  }
}
