import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../ayah_links/ayah_links_screen.dart';
import '../backup/backup_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../books/books_screen.dart';
import '../highlights/highlights_screen.dart';
import '../journey/journey_screen.dart';
import '../journey/mushaf_map_screen.dart';
import '../notes/notes_screen.dart';
import '../pathways/guided_pathways_screen.dart';
import '../reminders/reminders_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../word_meanings/word_meanings_screen.dart';

/// تبويب «المزيد»: الأدوات الثانوية والإعدادات في قائمة واحدة واضحة.
class MoreScreen extends StatelessWidget {
  /// ينشئ تبويب المزيد.
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
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Group(
              title: l10n.isArabic ? 'الأقسام' : 'Sections',
              children: [
                _Tile(
                  icon: Icons.insights_rounded,
                  label: l10n.myJourney,
                  onTap: () => open(const JourneyScreen()),
                ),
                _Tile(
                  icon: Icons.grid_on_rounded,
                  label: l10n.mushafMap,
                  onTap: () => open(const MushafMapScreen()),
                ),
                _Tile(
                  icon: Icons.route_rounded,
                  label: l10n.guidedPathways,
                  onTap: () => open(const GuidedPathwaysScreen()),
                ),
                _Tile(
                  icon: Icons.edit_note_rounded,
                  label: l10n.notes,
                  onTap: () => open(const NotesScreen()),
                ),
                _Tile(
                  icon: Icons.search_rounded,
                  label: l10n.search,
                  onTap: () => open(const SearchScreen()),
                ),
                _Tile(
                  icon: Icons.translate_rounded,
                  label: l10n.wordMeanings,
                  onTap: () => open(const WordMeaningsScreen()),
                ),
                _Tile(
                  icon: Icons.hub_rounded,
                  label: l10n.ayahLinks,
                  onTap: () => open(const AyahLinksScreen()),
                ),
                _Tile(
                  icon: Icons.auto_stories_rounded,
                  label: l10n.booksAndBooklets,
                  onTap: () => open(const BooksScreen()),
                ),
              ],
            ),
            _Group(
              title: l10n.isArabic ? 'آياتي' : 'My verses',
              children: [
                _Tile(
                  icon: Icons.bookmark_rounded,
                  label: l10n.bookmarks,
                  onTap: () => open(const BookmarksScreen()),
                ),
                _Tile(
                  icon: Icons.format_paint_rounded,
                  label: l10n.highlights,
                  onTap: () => open(const HighlightsScreen()),
                ),
              ],
            ),
            _Group(
              title: l10n.isArabic ? 'الأدوات' : 'Tools',
              children: [
                _Tile(
                  icon: Icons.alarm_rounded,
                  label: l10n.reminders,
                  onTap: () => open(const RemindersScreen()),
                ),
                _Tile(
                  icon: Icons.backup_rounded,
                  label: l10n.backup,
                  onTap: () => open(const BackupScreen()),
                ),
              ],
            ),
            _Group(
              title: l10n.isArabic ? 'التطبيق' : 'App',
              children: [
                _Tile(
                  icon: Icons.settings_rounded,
                  label: l10n.settings,
                  onTap: () => open(const SettingsScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// مجموعة عناصر بعنوان قسم وبطاقة واحدة.
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
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary(context),
              ),
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

/// عنصر قائمة بأيقونة ذهبية دائرية وسهم دخول.
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
      // Mirrors with text direction, so it points left in Arabic.
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary(context),
      ),
    );
  }
}
