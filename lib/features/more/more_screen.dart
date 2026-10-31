import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../ayah_links/screens/ayah_links_screen.dart';
import '../backup/backup_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../books/screens/books_screen.dart';
import '../highlights/highlights_screen.dart';
import '../journey/journey_screen.dart';
import '../journey/mushaf_map_screen.dart';
import '../audio/downloads_screen.dart';
import '../qibla/qibla_screen.dart';
import '../memorization/memorization_screen.dart';
import '../notes/notes_screen.dart';
import '../tadbeer/my_reflections_screen.dart';
import '../pathways/guided_pathways_screen.dart';
import '../reminders/reminders_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../word_meanings/word_meanings_screen.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/ornaments.dart';

/// تبويب «المزيد»: الأدوات الثانوية والإعدادات في قائمة واحدة.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    void open(Widget screen) {
      HapticFeedback.selectionClick();
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.more)),
        body: PatternBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SectionsGrid(
                title: l10n.sectionsTitle,
                children: [
                  _SectionCard(
                    icon: AppIcons.flowerLotusFill,
                    label: l10n.myReflections,
                    hint: l10n.myReflectionsCardHint,
                    onTap: () => open(const MyReflectionsScreen()),
                  ),
                  _SectionCard(
                    icon: AppIcons.notePencil,
                    label: l10n.notes,
                    hint: l10n.notesCardHint,
                    onTap: () => open(const NotesScreen()),
                  ),
                  _SectionCard(
                    icon: AppIcons.brainFill,
                    label: l10n.memorization,
                    hint: l10n.memorizationCardHint,
                    onTap: () => open(const MemorizationScreen()),
                  ),
                  _SectionCard(
                    icon: AppIcons.magnifyingGlass,
                    label: l10n.search,
                    hint: l10n.searchCardHint,
                    onTap: () => open(const SearchScreen()),
                  ),
                  _SectionCard(
                    icon: AppIcons.books,
                    label: l10n.wordMeanings,
                    hint: l10n.wordMeaningsCardHint,
                    onTap: () => open(const WordMeaningsScreen()),
                  ),
                  _SectionCard(
                    icon: AppIcons.graphFill,
                    label: l10n.ayahLinks,
                    hint: l10n.ayahLinksCardHint,
                    onTap: () => open(const AyahLinksScreen()),
                  ),
                  _SectionCard(
                    icon: AppIcons.path,
                    label: l10n.guidedPathways,
                    hint: l10n.guidedPathwaysCardHint,
                    onTap: () => open(const GuidedPathwaysScreen()),
                  ),
                  _SectionCard(
                    icon: AppIcons.bookOpenTextFill,
                    label: l10n.booksAndBooklets,
                    hint: l10n.booksAndBookletsCardHint,
                    onTap: () => open(const BooksScreen()),
                  ),
                ],
              ),
              _Group(
                title: l10n.myVersesSection,
                children: [
                  _Tile(
                    icon: AppIcons.bookmarkSimpleFill,
                    label: l10n.bookmarks,
                    onTap: () => open(const BookmarksScreen()),
                  ),
                  _Tile(
                    icon: AppIcons.paintBrushFill,
                    label: l10n.highlights,
                    onTap: () => open(const HighlightsScreen()),
                  ),
                ],
              ),
              _Group(
                title: l10n.toolsSection,
                children: [
                  _Tile(
                    icon: AppIcons.chartLineUp,
                    label: l10n.myJourney,
                    onTap: () => open(const JourneyScreen()),
                  ),
                  _Tile(
                    icon: AppIcons.headphones,
                    label: l10n.recitationDownloads,
                    onTap: () => open(const RecitationDownloadsScreen()),
                  ),
                  _Tile(
                    icon: AppIcons.alarmFill,
                    label: l10n.reminders,
                    onTap: () => open(const RemindersScreen()),
                  ),
                  _Tile(
                    icon: AppIcons.gridFour,
                    label: l10n.mushafMap,
                    onTap: () => open(const MushafMapScreen()),
                  ),
                  _Tile(
                    icon: AppIcons.compass,
                    label: l10n.qibla,
                    onTap: () => open(const QiblaScreen()),
                  ),
                  _Tile(
                    icon: AppIcons.cloudArrowUp,
                    label: l10n.backup,
                    onTap: () => open(const BackupScreen()),
                  ),
                ],
              ),
              _Group(
                title: l10n.appSection,
                children: [
                  _Tile(
                    icon: AppIcons.gearFill,
                    label: l10n.settings,
                    onTap: () => open(const SettingsScreen()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مجموعة عناصر تحت عنوان قسم، في بطاقة واحدة.
class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
            child: Row(
              children: [
                const OrnamentStar(size: 10),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.appFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 64),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر بأيقونة ذهبية دائرية وسهم دخول.
class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.accentGold(context);

    return ListTile(
      onTap: onTap,
      minTileHeight: 60,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold.withValues(alpha: isDark ? 0.16 : 0.14),
        ),
        child: Icon(icon, size: 22, color: gold),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.appFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      // يتبع اتجاه النص، فيشير لليسار في العربية.
      trailing: Icon(
        AppIcons.caretRight,
        color: AppColors.textSecondary(context),
      ),
    );
  }
}

/// الأقسام الرئيسية في شبكة بطاقات، فتتقدّم على بقية المزيد.
class _SectionsGrid extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionsGrid({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
            child: Row(
              children: [
                const OrnamentStar(size: 10),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.appFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, box) {
              // عمودان على الهاتف، وثلاثة حين يتسع العرض.
              final columns = box.maxWidth >= 560 ? 3 : 2;
              const gap = 10.0;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final c in children) SizedBox(width: width, child: c),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// بطاقة قسم: أيقونة بارزة، واسمه، وسطر يقول ما فيه.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final gold = AppColors.accentGold(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                primary.withValues(alpha: isDark ? 0.34 : 0.10),
                gold.withValues(alpha: isDark ? 0.12 : 0.10),
              ],
            ),
            border: Border.all(color: gold.withValues(alpha: 0.35)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 124),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? gold.withValues(alpha: 0.2) : primary,
                    ),
                    child: Icon(
                      icon,
                      size: 23,
                      color: isDark ? gold : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontFamily: AppTheme.appFontFamily,
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
