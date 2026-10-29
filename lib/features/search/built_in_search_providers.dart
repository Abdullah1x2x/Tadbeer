import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_root_search_helper.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../ayah_links/screens/ayah_link_detail_screen.dart';
import '../ayah_links/data/ayah_link_repository.dart';
import '../ayah_links/data/curated_pathways.dart';
import '../../features/pathways/guided_pathways_screen.dart';
import '../books/screens/book_reader_screen.dart';
import '../books/data/book_repository.dart';
import '../duas/data/quran_duas_repository.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../data/quran/quran_repository.dart';
import '../../features/quran/screens/quran_screen.dart';
import '../../data/models/reminder_model.dart';
import '../../features/reminders/reminders_screen.dart';
import 'search_provider.dart';
import '../../core/design_system/app_icons.dart';

/// البحث في الآيات، بالنص أو بالجذر.
class QuranSearchProvider implements SearchProvider {
  const QuranSearchProvider();

  @override
  String get id => 'quran';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.quran;

  @override
  IconData get icon => AppIcons.bookOpenFill;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final repo = QuranRepository.instance;
    final isRoot = ArabicRootSearchHelper.isRootQuery(query);
    final root = isRoot ? ArabicRootSearchHelper.extractRoot(query) : '';
    final ayahs = repo.searchAyahs(query, limit: 40);

    return ayahs.map((ayah) {
      final surah = repo.getSurah(ayah.surahNumber);
      return SearchResultItem(
        id: isRoot
            ? 'quran_root_${ayah.surahNumber}_${ayah.ayahNumber}'
            : 'quran_${ayah.surahNumber}_${ayah.ayahNumber}',
        providerId: id,
        sectionTitle: isRoot
            ? '${getSectionTitle(context)} (جذر: $root)'
            : getSectionTitle(context),
        title:
            'سورة ${surah.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)}',
        snippet: '﴿ ${ayah.text} ﴾',
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.ayahNumber,
        page: ayah.page,
        badge: isRoot
            ? 'جذر: $root · ص ${ArabicSearchNormalizer.toArabicDigits(ayah.page)} · ج ${ArabicSearchNormalizer.toArabicDigits(ayah.juz)}'
            : 'ص ${ArabicSearchNormalizer.toArabicDigits(ayah.page)} · ج ${ArabicSearchNormalizer.toArabicDigits(ayah.juz)}',
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => QuranScreen(
                initialPage: ayah.page,
                targetSurahNumber: ayah.surahNumber,
                targetAyahNumber: ayah.ayahNumber,
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

/// البحث في الخواطر: عناوينها ونصوصها والآيات المرتبطة بها.
class NotesSearchProvider implements SearchProvider {
  const NotesSearchProvider();

  @override
  String get id => 'notes';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.notes;

  @override
  IconData get icon => AppIcons.notePencil;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    final notes = UserDataStore.instance.notes.where((note) {
      final title = ArabicSearchNormalizer.normalize(note.title ?? '');
      final content = ArabicSearchNormalizer.normalize(note.content);
      final verse = ArabicSearchNormalizer.normalize(note.ayahText ?? '');
      return title.contains(normalizedQuery) ||
          content.contains(normalizedQuery) ||
          verse.contains(normalizedQuery);
    }).toList();

    return notes.map((note) {
      final surahName = note.surahNumber != null
          ? QuranRepository.instance.getSurah(note.surahNumber!).name
          : '';
      final title = note.isAyahNote
          ? 'تدبر سورة $surahName · آية ${note.ayahNumber != null ? ArabicSearchNormalizer.toArabicDigits(note.ayahNumber!) : ""}'
          : (note.title?.isNotEmpty == true
                ? note.title!
                : context.l10n.freeNoteLabel);

      return SearchResultItem(
        id: 'note_${note.id}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title: title,
        snippet: note.content,
        surahNumber: note.surahNumber,
        ayahNumber: note.ayahNumber,
        page: note.page,
        badge:
            '${ArabicSearchNormalizer.toArabicDigits(note.createdAt.year)}/${ArabicSearchNormalizer.toArabicDigits(note.createdAt.month)}/${ArabicSearchNormalizer.toArabicDigits(note.createdAt.day)}',
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(existingNote: note),
            ),
          );
        },
      );
    }).toList();
  }
}

/// البحث في وقفات التدبر: إجاباتها وأسماء سورها ونصوص آياتها.
class TadbeerSearchProvider implements SearchProvider {
  const TadbeerSearchProvider();

  @override
  String get id => 'tadbeer';

  @override
  String getSectionTitle(BuildContext context) =>
      context.l10n.tadbeerSectionTitle;

  @override
  IconData get icon => AppIcons.sparkleFill;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    final items = UserDataStore.instance.tadbeerItems.where((item) {
      final surah = QuranRepository.instance.getSurah(item.surahNumber);
      final surahNorm = ArabicSearchNormalizer.normalize(surah.name);
      final ayahStr = item.ayahNumber.toString();

      if (surahNorm.contains(normalizedQuery) ||
          ayahStr.contains(normalizedQuery)) {
        return true;
      }

      for (final answer in item.answers.values) {
        if (ArabicSearchNormalizer.normalize(answer)
            .contains(normalizedQuery)) {
          return true;
        }
      }

      final ayah = QuranRepository.instance.getAyah(
        item.surahNumber,
        item.ayahNumber,
      );
      if (ayah != null &&
          ArabicSearchNormalizer.normalize(ayah.text)
              .contains(normalizedQuery)) {
        return true;
      }

      return false;
    }).toList();

    return items.map((item) {
      final surah = QuranRepository.instance.getSurah(item.surahNumber);
      final ayah = QuranRepository.instance.getAyah(
        item.surahNumber,
        item.ayahNumber,
      );
      final snippet = item.combinedSummary.isNotEmpty
          ? item.combinedSummary
          : (ayah != null ? '﴿ ${ayah.text} ﴾' : 'وقفة تدبرية مسجلة');

      return SearchResultItem(
        id: 'tadbeer_${item.id}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title:
            'وقفة تدبر: سورة ${surah.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(item.ayahNumber)}',
        snippet: snippet,
        surahNumber: item.surahNumber,
        ayahNumber: item.ayahNumber,
        page: ayah?.page,
        badge: ayah != null
            ? 'ص ${ArabicSearchNormalizer.toArabicDigits(ayah.page)}'
            : null,
        icon: icon,
        onTap: (ctx) {
          if (ayah != null) {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => QuranScreen(
                  initialPage: ayah.page,
                  targetSurahNumber: item.surahNumber,
                  targetAyahNumber: item.ayahNumber,
                ),
              ),
            );
          }
        },
      );
    }).toList();
  }
}

/// البحث في الفواصل باسم السورة أو رقم الآية أو نصها.
class BookmarksSearchProvider implements SearchProvider {
  const BookmarksSearchProvider();

  @override
  String get id => 'bookmarks';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.bookmarks;

  @override
  IconData get icon => AppIcons.bookmarkSimpleFill;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    final bookmarks = UserDataStore.instance.bookmarks.where((b) {
      final surah = QuranRepository.instance.getSurah(b.surahNumber);
      final ayah = QuranRepository.instance.getAyah(
        b.surahNumber,
        b.ayahNumber,
      );
      final surahNorm = ArabicSearchNormalizer.normalize(surah.name);
      final ayahTextNorm = ayah != null
          ? ArabicSearchNormalizer.normalize(ayah.text)
          : '';
      final ayahNumStr = b.ayahNumber.toString();

      return surahNorm.contains(normalizedQuery) ||
          ayahTextNorm.contains(normalizedQuery) ||
          ayahNumStr.contains(normalizedQuery);
    }).toList();

    return bookmarks.map((b) {
      final surah = QuranRepository.instance.getSurah(b.surahNumber);
      final ayah = QuranRepository.instance.getAyah(
        b.surahNumber,
        b.ayahNumber,
      );

      return SearchResultItem(
        id: 'bookmark_${b.id}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title:
            'سورة ${surah.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(b.ayahNumber)}',
        snippet: ayah != null ? '﴿ ${ayah.text} ﴾' : '',
        surahNumber: b.surahNumber,
        ayahNumber: b.ayahNumber,
        page: b.page,
        badge: 'ص ${ArabicSearchNormalizer.toArabicDigits(b.page)}',
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => QuranScreen(
                initialPage: b.page,
                targetSurahNumber: b.surahNumber,
                targetAyahNumber: b.ayahNumber,
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

/// البحث في الآيات المظلّلة باسم السورة أو رقم الآية أو نصها.
class HighlightsSearchProvider implements SearchProvider {
  const HighlightsSearchProvider();

  @override
  String get id => 'highlights';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.highlights;

  @override
  IconData get icon => AppIcons.palette;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    final highlights = UserDataStore.instance.highlights.where((h) {
      final surah = QuranRepository.instance.getSurah(h.surahNumber);
      final ayah = QuranRepository.instance.getAyah(
        h.surahNumber,
        h.ayahNumber,
      );
      final surahNorm = ArabicSearchNormalizer.normalize(surah.name);
      final ayahTextNorm = ayah != null
          ? ArabicSearchNormalizer.normalize(ayah.text)
          : '';
      final ayahNumStr = h.ayahNumber.toString();

      return surahNorm.contains(normalizedQuery) ||
          ayahTextNorm.contains(normalizedQuery) ||
          ayahNumStr.contains(normalizedQuery);
    }).toList();

    return highlights.map((h) {
      final surah = QuranRepository.instance.getSurah(h.surahNumber);
      final ayah = QuranRepository.instance.getAyah(
        h.surahNumber,
        h.ayahNumber,
      );

      return SearchResultItem(
        id: 'highlight_${h.id}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title:
            'سورة ${surah.name} · الآية ${ArabicSearchNormalizer.toArabicDigits(h.ayahNumber)}',
        snippet: ayah != null ? '﴿ ${ayah.text} ﴾' : '',
        surahNumber: h.surahNumber,
        ayahNumber: h.ayahNumber,
        page: h.page,
        badge: 'ص ${ArabicSearchNormalizer.toArabicDigits(h.page)}',
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => QuranScreen(
                initialPage: h.page,
                targetSurahNumber: h.surahNumber,
                targetAyahNumber: h.ayahNumber,
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

/// البحث في روابط الآيات: عناوينها ووصفها وآياتها.
class AyahLinksSearchProvider implements SearchProvider {
  const AyahLinksSearchProvider();

  @override
  String get id => 'ayah_links';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.ayahLinks;

  @override
  IconData get icon => AppIcons.graph;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final matchingLinks = AyahLinkRepository().searchLinks(query);

    return matchingLinks.map((link) {
      return SearchResultItem(
        id: 'ayah_link_${link.id}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title: link.title,
        snippet:
            link.description ??
            '${ArabicSearchNormalizer.toArabicDigits(link.verses.length)} آيات مرتبطة',
        badge:
            '${ArabicSearchNormalizer.toArabicDigits(link.verses.length)} آيات',
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => AyahLinkDetailScreen(linkId: link.id),
            ),
          );
        },
      );
    }).toList();
  }
}

/// البحث في أدعية القرآن: نصوصها وعناوينها وتصنيفاتها.
class DuasSearchProvider implements SearchProvider {
  const DuasSearchProvider();

  @override
  String get id => 'duas';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.quranDuas;

  @override
  IconData get icon => AppIcons.hand;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final matchingDuas = QuranDuasRepository.instance.search(query);

    return matchingDuas.map((dua) {
      return SearchResultItem(
        id: 'dua_${dua.id}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title: dua.title.isNotEmpty
            ? '${dua.title} · سورة ${dua.surahName} (${ArabicSearchNormalizer.convertDigits(dua.ayahDisplay)})'
            : 'دعاء من سورة ${dua.surahName} · الآية ${ArabicSearchNormalizer.convertDigits(dua.ayahDisplay)}',
        snippet: dua.isMultiAyah ? dua.formattedTextWithMarkers : dua.duaText,
        surahNumber: dua.surahNumber,
        ayahNumber: dua.ayahNumber,
        page: dua.page,
        badge: dua.category,
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => QuranScreen(
                initialPage: dua.page,
                targetSurahNumber: dua.surahNumber,
                targetAyahNumber: dua.ayahNumber,
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

/// البحث في عناوين التذكيرات.
class RemindersSearchProvider implements SearchProvider {
  const RemindersSearchProvider();

  @override
  String get id => 'reminders';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.reminders;

  @override
  IconData get icon => AppIcons.alarm;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    final reminders = UserDataStore.instance.reminders.where((r) {
      final titleNorm = ArabicSearchNormalizer.normalize(r.title);
      return titleNorm.contains(normalizedQuery);
    }).toList();

    return reminders.map((r) {
      final repeatText = r.repeatMode == ReminderRepeatMode.daily
          ? 'يومي'
          : (r.repeatMode == ReminderRepeatMode.weekdays
                ? 'أيام محددة'
                : 'مرة واحدة');

      return SearchResultItem(
        id: 'reminder_${r.id}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title: r.title,
        snippet: 'وقت التنبيه: ${r.formattedTime}',
        badge: repeatText,
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const RemindersScreen()),
          );
        },
      );
    }).toList();
  }
}

/// البحث في معاني الكلمات.
class WordMeaningsSearchProvider implements SearchProvider {
  const WordMeaningsSearchProvider();

  @override
  String get id => 'word_meanings';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.wordMeanings;

  @override
  IconData get icon => AppIcons.bookOpenTextFill;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final repo = QuranRepository.instance;
    final words = repo.searchWordMeanings(query, limit: 30);

    return words.map((w) {
      final surah = repo.getSurah(w.surah);
      return SearchResultItem(
        id: 'word_${w.surah}_${w.ayah}_${w.word}',
        providerId: id,
        sectionTitle: getSectionTitle(context),
        title:
            '${w.word} — سورة ${surah.name} (${ArabicSearchNormalizer.toArabicDigits(w.ayah)})',
        snippet: w.meaning,
        surahNumber: w.surah,
        ayahNumber: w.ayah,
        page: w.page,
        badge: 'ص ${ArabicSearchNormalizer.toArabicDigits(w.page)}',
        icon: icon,
        onTap: (ctx) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => QuranScreen(
                initialPage: w.page,
                targetSurahNumber: w.surah,
                targetAyahNumber: w.ayah,
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

/// البحث في الكتب والملازم: العنوان والسلسلة والمؤلف والفصول والوصف، بأكثر من كلمة.
class BooksSearchProvider implements SearchProvider {
  const BooksSearchProvider();

  @override
  String get id => 'books';

  @override
  String getSectionTitle(BuildContext context) =>
      context.l10n.isArabic ? 'الملازم والكتب' : 'Books & Booklets';

  @override
  IconData get icon => AppIcons.bookOpenTextFill;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final sectionTitle = getSectionTitle(context);
    final repo = BookRepository.instance;
    if (!repo.isInitialized) {
      await repo.init();
    }

    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final tokens = normalizedQuery
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return const [];

    final results = <SearchResultItem>[];

    for (final book in repo.books) {
      final titleNorm = ArabicSearchNormalizer.normalize(book.title);
      final subtitleNorm = ArabicSearchNormalizer.normalize(book.subtitle);
      final authorNorm = ArabicSearchNormalizer.normalize(book.author);
      final categoryNorm = ArabicSearchNormalizer.normalize(book.category);
      final badgeNorm = ArabicSearchNormalizer.normalize(book.badgeText ?? '');

      bool match = false;

      // ١. مطابقة مباشرة في بيانات الملزمة.
      if (titleNorm.contains(normalizedQuery) ||
          subtitleNorm.contains(normalizedQuery) ||
          authorNorm.contains(normalizedQuery) ||
          categoryNorm.contains(normalizedQuery) ||
          badgeNorm.contains(normalizedQuery)) {
        match = true;
      } else if (tokens.length > 1) {
        // ٢. كل الكلمات عبر حقول الملزمة، دون اشتراط "ال".
        final combined =
            '$titleNorm $subtitleNorm $authorNorm $categoryNorm $badgeNorm';
        match = tokens.every((token) {
          if (combined.contains(token)) return true;
          if (token.startsWith('ال') && token.length >= 4) {
            return combined.contains(token.substring(2));
          }
          return false;
        });
      } else if (tokens.length == 1 &&
          tokens.first.startsWith('ال') &&
          tokens.first.length >= 4) {
        // كلمة واحدة، دون اشتراط "ال".
        final withoutAl = tokens.first.substring(2);
        final combined =
            '$titleNorm $subtitleNorm $authorNorm $categoryNorm $badgeNorm';
        if (combined.contains(withoutAl)) {
          match = true;
        }
      }

      // ٣. عناوين الفصول.
      if (!match && book.chapters.isNotEmpty) {
        for (final ch in book.chapters) {
          final chTitleNorm = ArabicSearchNormalizer.normalize(ch.title);
          if (chTitleNorm.contains(normalizedQuery)) {
            match = true;
            break;
          }
          if (tokens.length > 1 &&
              tokens.every((t) => chTitleNorm.contains(t))) {
            match = true;
            break;
          }
        }
      }

      if (match) {
        final snippet = book.subtitle.isNotEmpty
            ? book.subtitle
            : (book.author.isNotEmpty
                  ? 'المؤلف: ${book.author}'
                  : (book.badgeText != null && book.badgeText!.isNotEmpty
                        ? book.badgeText!
                        : book.category));

        final badge = book.isPdf ? 'ملزمة PDF' : 'كتاب نصي';

        results.add(
          SearchResultItem(
            id: 'book_${book.id}',
            providerId: id,
            sectionTitle: sectionTitle,
            title: book.title,
            snippet: snippet,
            badge: badge,
            icon: icon,
            onTap: (ctx) {
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
              );
            },
          ),
        );
      }
    }

    return results;
  }
}

/// البحث في مسارات التدبر: العنوان والوصف وفوائد الآيات.
class PathwaysSearchProvider implements SearchProvider {
  const PathwaysSearchProvider();

  @override
  String get id => 'pathways';

  @override
  String getSectionTitle(BuildContext context) => context.l10n.guidedPathways;

  @override
  IconData get icon => AppIcons.path;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    final q = ArabicSearchNormalizer.normalize(query);
    if (q.isEmpty) return const [];
    bool matches(String text) =>
        ArabicSearchNormalizer.normalize(text).contains(q);

    return [
      for (final p in CuratedPathwaysRegistry.pathways)
        if (matches(p.title) ||
            matches(p.description) ||
            p.verses.any((v) => matches(v.note)))
          SearchResultItem(
            id: 'pathway_${p.id}',
            providerId: id,
            sectionTitle: getSectionTitle(context),
            title: p.title,
            snippet: p.description,
            badge: p.category,
            icon: icon,
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => PathwayJourneyScreen(pathway: p),
              ),
            ),
          ),
    ];
  }
}
