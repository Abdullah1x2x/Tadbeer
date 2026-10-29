import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import '../ayah_links/data/curated_pathways.dart';
import '../books/screens/book_reader_screen.dart';
import '../books/data/book_repository.dart';
import '../duas/data/adhkar_repository.dart';
import '../duas/screens/morning_evening_adhkar_screen.dart';
import '../memorization/memorization_screen.dart';
import '../pathways/guided_pathways_screen.dart';
import '../../data/quran/quran_repository.dart';
import 'last_activity.dart';
import '../../core/design_system/app_icons.dart';

/// بطاقة «أكمل من حيث توقفت»: آخر الأذكار والكتاب والحفظ والمسار في مكان واحد.
class ContinueCard extends StatelessWidget {
  const ContinueCard({super.key, this.limit = 3, this.gap = 0});

  /// كم نشاطاً من الأحدث تعرض.
  final int limit;

  /// المسافة تحتها حين تظهر.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) {
        final items = LastActivityStore.recent()
            .map((a) => _resolve(context, a))
            .whereType<_Entry>()
            .take(limit)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();
        final single = limit == 1;
        return Card(
          margin: EdgeInsetsDirectional.only(bottom: gap),
          child: Padding(
            // البطاقة ذات السطر الواحد تضع اسمها في سطرها بدل عنوان، لتبقى بارتفاع سطر.
            padding: single
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 2)
                : const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!single) ...[
                  Text(
                    l10n.continueWhereYouLeft,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                for (final e in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accentGold(context)
                          .withValues(alpha: 0.14),
                      child: Icon(
                        e.icon,
                        size: 20,
                        color: AppColors.accentGold(context),
                      ),
                    ),
                    title: Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      single
                          ? '${l10n.continueWhereYouLeft} · ${e.subtitle}'
                          : e.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(AppIcons.caretRight),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => e.open()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// صف النشاط المحفوظ، أو null إن لم يعد موجوداً.
  _Entry? _resolve(BuildContext context, LastActivity a) {
    final l10n = context.l10n;
    switch (a.kind) {
      case ActivityKind.adhkar:
        final morning = a.ref == AdhkarCategory.morning.name;
        return _Entry(
          icon: morning ? AppIcons.sunFill : AppIcons.moonStars,
          title: morning
              ? l10n.morningAdhkarReminder
              : l10n.eveningAdhkarReminder,
          subtitle: l10n.adhkarKind,
          open: () => MorningEveningAdhkarScreen(
            initialCategory: morning
                ? AdhkarCategory.morning
                : AdhkarCategory.evening,
          ),
        );
      case ActivityKind.book:
        final book = BookRepository.instance.books
            .where((b) => b.id == a.ref)
            .firstOrNull;
        if (book == null) return null;
        return _Entry(
          icon: AppIcons.bookOpenTextFill,
          title: book.title,
          subtitle: book.isPdf
              ? l10n.pageNumber(a.position + 1)
              : l10n.chapterN(a.position + 1),
          open: () => book.isPdf
              ? BookReaderScreen(book: book, initialPdfPage: a.position)
              : BookReaderScreen(book: book, initialChapterIndex: a.position),
        );
      case ActivityKind.hifz:
        final surah = int.tryParse(a.ref);
        if (surah == null) return null;
        final s = QuranRepository.instance.getSurah(surah);
        return _Entry(
          icon: AppIcons.brainFill,
          title: s.name,
          subtitle: l10n.memorization,
          open: () => HifzSessionScreen(
            verses: [for (var v = 1; v <= s.ayahCount; v++) (surah, v)],
          ),
        );
      case ActivityKind.pathway:
        final p = CuratedPathwaysRegistry.pathways
            .where((p) => p.id == a.ref)
            .firstOrNull;
        if (p == null) return null;
        return _Entry(
          icon: AppIcons.path,
          title: p.title,
          subtitle: l10n.guidedPathways,
          open: () => PathwayJourneyScreen(pathway: p),
        );
    }
  }
}

class _Entry {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() open;

  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.open,
  });
}
