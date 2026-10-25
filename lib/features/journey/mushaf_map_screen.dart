import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/storage/user_data_store.dart';
import '../memorization/memorization_model.dart';
import '../quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import 'reading_journey.dart';

/// مستوى نشاط الصفحة في خريطة المصحف.
enum PageActivity {
  /// لم تُقرأ.
  none,

  /// قُرئت.
  read,

  /// فيها آية محفوظة أو مميزة.
  marked,

  /// فيها آية في الحفظ.
  memorizing,

  /// فيها وقفة تدبر أو ملاحظة.
  reflected,
}

/// يحسب نشاط كل صفحة من بيانات المستخدم (الفهرس ٠ = الصفحة ١).
List<PageActivity> computePageActivity(UserDataStore store) {
  final repo = QuranRepository.instance;
  final levels = List.filled(mushafPageCount, PageActivity.none);

  void raise(int page, PageActivity level) {
    if (page < 1 || page > mushafPageCount) return;
    if (level.index > levels[page - 1].index) levels[page - 1] = level;
  }

  int? pageOf(int surah, int ayah) => repo.getAyah(surah, ayah)?.page;

  for (final pages in store.journey.dailyPages.values) {
    for (final p in pages) {
      raise(p, PageActivity.read);
    }
  }
  for (final b in store.bookmarks) {
    final p = pageOf(b.surahNumber, b.ayahNumber);
    if (p != null) raise(p, PageActivity.marked);
  }
  for (final h in store.highlights) {
    final p = pageOf(h.surahNumber, h.ayahNumber);
    if (p != null) raise(p, PageActivity.marked);
  }
  for (final n in store.notes) {
    final p =
        n.page ??
        (n.surahNumber != null && n.ayahNumber != null
            ? pageOf(n.surahNumber!, n.ayahNumber!)
            : null);
    if (p != null) raise(p, PageActivity.reflected);
  }
  for (final key in HifzStore.all().keys) {
    final parts = key.split(':');
    final p = pageOf(int.parse(parts[0]), int.parse(parts[1]));
    if (p != null) raise(p, PageActivity.memorizing);
  }
  for (final t in store.tadbeerItems) {
    if (t.isEmpty) continue;
    final p = pageOf(t.surahNumber, t.ayahNumber);
    if (p != null) raise(p, PageActivity.reflected);
  }
  return levels;
}

/// شاشة خريطة المصحف وسجل التدبر.
class MushafMapScreen extends StatelessWidget {
  /// ينشئ شاشة خريطة المصحف.
  const MushafMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.mushafMap),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.mapTab),
                Tab(text: l10n.reflectionLog),
              ],
            ),
          ),
          body: ListenableBuilder(
            listenable: UserDataStore.instance,
            builder: (context, _) =>
                const TabBarView(children: [_MapTab(), _ReflectionLogTab()]),
          ),
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab();

  Color _color(BuildContext context, PageActivity a) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (a) {
      case PageActivity.none:
        return AppColors.border(context).withValues(alpha: isDark ? 0.6 : 0.7);
      case PageActivity.read:
        return AppColors.primary(context)
            .withValues(alpha: isDark ? 0.55 : 0.4);
      case PageActivity.marked:
        return AppColors.primary(context);
      case PageActivity.memorizing:
        return AppColors.statusSuccess;
      case PageActivity.reflected:
        return AppColors.accentGold(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final levels = computePageActivity(UserDataStore.instance);
    final repo = QuranRepository.instance;
    final touched = levels.where((l) => l != PageActivity.none).length;

    // Group the pages by juz so each row reads as one juz.
    final byJuz = <int, List<int>>{};
    for (var p = 1; p <= mushafPageCount; p++) {
      byJuz.putIfAbsent(repo.getPage(p).juzNumber, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          l10n.pagesTouched(touched),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final a in PageActivity.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _color(context, a),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.activityLabel(a.index),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (final entry in byJuz.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    l10n.digits(entry.key),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      for (final p in entry.value)
                        Tooltip(
                          message: l10n.pageNumber(p),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuranScreen(initialPage: p),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: _color(context, levels[p - 1]),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// سجل زمني لوقفات التدبر والملاحظات المرتبطة بالآيات.
class _ReflectionLogTab extends StatelessWidget {
  const _ReflectionLogTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = UserDataStore.instance;
    final repo = QuranRepository.instance;

    final entries = <_LogEntry>[
      for (final t in store.tadbeerItems)
        if (!t.isEmpty)
          _LogEntry(
            date: t.updatedAt,
            surah: t.surahNumber,
            ayah: t.ayahNumber,
            text: t.combinedSummary,
            isReflection: true,
          ),
      for (final n in store.notes)
        if (n.surahNumber != null && n.ayahNumber != null)
          _LogEntry(
            date: n.updatedAt,
            surah: n.surahNumber!,
            ayah: n.ayahNumber!,
            text: n.content,
            isReflection: false,
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.history_edu_rounded,
        title: l10n.noReflectionsYet,
        hint: l10n.reflectionsEmptyHint,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final surah = repo.getSurah(e.surah);
        final gold = AppColors.accentGold(context);
        final color = e.isReflection ? gold : AppColors.primary(context);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline rail with a dot per entry.
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 2,
                      height: 14,
                      color: i == 0
                          ? Colors.transparent
                          : AppColors.border(context),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: i == entries.length - 1
                            ? Colors.transparent
                            : AppColors.border(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuranScreen(
                          targetSurahNumber: e.surah,
                          targetAyahNumber: e.ayah,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                e.isReflection
                                    ? Icons.spa_rounded
                                    : Icons.edit_note_rounded,
                                size: 18,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l10n.ayahReference(surah.name, e.ayah),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                l10n.shortDate(e.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.text,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogEntry {
  final DateTime date;
  final int surah;
  final int ayah;
  final String text;
  final bool isReflection;

  const _LogEntry({
    required this.date,
    required this.surah,
    required this.ayah,
    required this.text,
    required this.isReflection,
  });
}
