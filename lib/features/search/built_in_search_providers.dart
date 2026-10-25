import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_root_search_helper.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../features/ayah_links/ayah_link_detail_screen.dart';
import '../../features/ayah_links/ayah_link_repository.dart';
import '../../features/ayah_links/curated_pathways.dart';
import '../../features/pathways/guided_pathways_screen.dart';
import '../../features/books/book_reader_screen.dart';
import '../../features/books/book_repository.dart';
import '../../features/duas/quran_duas_repository.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../features/quran/data/quran_repository.dart';
import '../../features/quran/screens/quran_screen.dart';
import '../../features/reminders/reminder_model.dart';
import '../../features/reminders/reminders_screen.dart';
import 'search_provider.dart';
import '../../core/design_system/app_icons.dart';

/// مزود البحث في آيات القرآن الكريم (بالنص المطبع أو بالجذر اللغوي).
///
/// Search provider for authentic Quranic Ayahs.
class QuranSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في القرآن الكريم.
  const QuranSearchProvider();

  /// المعرّف الفريد لمزود بحث القرآن.
  @override
  String get id => 'quran';

  /// يعيد عنوان قسم المصحف حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.quran;

  /// أيقونة قسم المصحف الشريف.
  @override
  IconData get icon => AppIcons.bookOpenFill;

  /// يبحث في آيات القرآن الكريم ويعيد النتائج المطابقة مع إمكانية الانتقال لصفحة المصحف.
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

/// مزود البحث في ملاحظات وخواطر المستخدم المحفوظة.
///
/// Search provider for user notes and reflections.
class NotesSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في الملاحظات.
  const NotesSearchProvider();

  /// المعرّف الفريد لمزود بحث الملاحظات.
  @override
  String get id => 'notes';

  /// يعيد عنوان قسم الملاحظات حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.notes;

  /// أيقونة قسم الملاحظات.
  @override
  IconData get icon => AppIcons.notePencil;

  /// يبحث في عناوين ومحتوى الملاحظات والنصوص القرآنية المرتبطة بها.
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

/// مزود البحث في وقفات التدبر الموجهة بالأسئلة الأربعة.
///
/// Search provider for Tadbeer pauses (guided 4-question reflections).
class TadbeerSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في وقفات التدبر.
  const TadbeerSearchProvider();

  /// المعرّف الفريد لمزود بحث وقفات التدبر.
  @override
  String get id => 'tadbeer';

  /// يعيد عنوان قسم التدبر حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) =>
      context.l10n.tadbeerSectionTitle;

  /// أيقونة قسم وقفات التدبر.
  @override
  IconData get icon => AppIcons.sparkleFill;

  /// يبحث في إجابات وقفات التدبر وأسماء السور ونصوص الآيات المرتبطة بها.
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

/// مزود البحث في العلامات المرجعية (المحفوظات).
///
/// Search provider for bookmarked reading markers.
class BookmarksSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في المحفوظات.
  const BookmarksSearchProvider();

  /// المعرّف الفريد لمزود بحث المحفوظات.
  @override
  String get id => 'bookmarks';

  /// يعيد عنوان قسم المحفوظات حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.bookmarks;

  /// أيقونة قسم المحفوظات.
  @override
  IconData get icon => AppIcons.bookmarkSimpleFill;

  /// يبحث في الآيات المحفوظة حسب اسم السورة أو رقم الآية أو نصها.
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

/// مزود البحث في الآيات المميزة بالألوان.
///
/// Search provider for highlighted Quran verses.
class HighlightsSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في الآيات المميزة.
  const HighlightsSearchProvider();

  /// المعرّف الفريد لمزود بحث التظليلات.
  @override
  String get id => 'highlights';

  /// يعيد عنوان قسم الآيات المميزة حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.highlights;

  /// أيقونة قسم الآيات المميزة.
  @override
  IconData get icon => AppIcons.palette;

  /// يبحث في الآيات المميزة بالألوان حسب اسم السورة أو رقم الآية أو نصها.
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

/// مزود البحث في خرائط روابط الآيات الموضوعية.
///
/// Search provider for interconnected Ayah Links maps.
class AyahLinksSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في روابط الآيات.
  const AyahLinksSearchProvider();

  /// المعرّف الفريد لمزود بحث روابط الآيات.
  @override
  String get id => 'ayah_links';

  /// يعيد عنوان قسم روابط الآيات حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.ayahLinks;

  /// أيقونة قسم روابط الآيات.
  @override
  IconData get icon => AppIcons.graph;

  /// يبحث في عناوين ووصف خرائط روابط الآيات والآيات المتصلة بها.
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

/// مزود البحث في الأدعية القرآنية الموثقة.
///
/// Search provider for authentic Quranic supplications (الأدعية).
class DuasSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في الأدعية القرآنية.
  const DuasSearchProvider();

  /// المعرّف الفريد لمزود بحث الأدعية.
  @override
  String get id => 'duas';

  /// يعيد عنوان قسم الأدعية حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.quranDuas;

  /// أيقونة قسم الأدعية.
  @override
  IconData get icon => AppIcons.hand;

  /// يبحث في نصوص وعناوين وتصنيفات الأدعية القرآنية.
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

/// مزود البحث في تذكيرات القراءة المجدولة.
///
/// Search provider for user reading reminders.
class RemindersSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في التذكيرات.
  const RemindersSearchProvider();

  /// المعرّف الفريد لمزود بحث التذكيرات.
  @override
  String get id => 'reminders';

  /// يعيد عنوان قسم التذكيرات حسب لغة الواجهة.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.reminders;

  /// أيقونة قسم التذكيرات.
  @override
  IconData get icon => AppIcons.alarm;

  /// يبحث في عناوين تذكيرات الورد القرآني المحفوظة.
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

/// مزود البحث في معجم معاني كلمات القرآن الكريم.
///
/// Search provider for authentic Quranic word meanings (معاني كلمات القرآن).
class WordMeaningsSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في معاني كلمات القرآن.
  const WordMeaningsSearchProvider();

  /// المعرّف الفريد لمزود بحث معاني الكلمات.
  @override
  String get id => 'word_meanings';

  /// يعيد عنوان قسم معاني الكلمات.
  @override
  String getSectionTitle(BuildContext context) => context.l10n.wordMeanings;

  /// أيقونة قسم معاني الكلمات.
  @override
  IconData get icon => AppIcons.bookOpenTextFill;

  /// يبحث في الكلمات القرآنية ومعانيها الموثقة ويعيد النتائج المطابقة.
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

/// مزود البحث في مكتبة الملازم والكتب التدبرية.
///
/// Search provider for curated and personal books, booklets, and pamphlets.
class BooksSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في الملازم والكتب.
  const BooksSearchProvider();

  /// المعرّف الفريد لمزود بحث الكتب والملازم.
  @override
  String get id => 'books';

  /// يعيد عنوان قسم الملازم والكتب.
  @override
  String getSectionTitle(BuildContext context) =>
      context.l10n.isArabic ? 'الملازم والكتب' : 'Books & Booklets';

  /// أيقونة قسم الكتب والملازم.
  @override
  IconData get icon => AppIcons.bookOpenTextFill;

  /// يبحث في عناوين الملازم، وأسماء السلاسل، والمؤلفين، والفصول، والوصف مع دعم البحث المرن وتعدد الكلمات.
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

    final tokens = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();
    if (tokens.isEmpty) return const [];

    final results = <SearchResultItem>[];

    for (final book in repo.books) {
      final titleNorm = ArabicSearchNormalizer.normalize(book.title);
      final subtitleNorm = ArabicSearchNormalizer.normalize(book.subtitle);
      final authorNorm = ArabicSearchNormalizer.normalize(book.author);
      final categoryNorm = ArabicSearchNormalizer.normalize(book.category);
      final badgeNorm = ArabicSearchNormalizer.normalize(book.badgeText ?? '');

      bool match = false;

      // ١. المطابقة المباشرة في البيانات الأساسية للملزمة
      if (titleNorm.contains(normalizedQuery) ||
          subtitleNorm.contains(normalizedQuery) ||
          authorNorm.contains(normalizedQuery) ||
          categoryNorm.contains(normalizedQuery) ||
          badgeNorm.contains(normalizedQuery)) {
        match = true;
      } else if (tokens.length > 1) {
        // ٢. مطابقة الكلمات المتعددة عبر حقول الملزمة مع مرونة السوابق
        final combined = '$titleNorm $subtitleNorm $authorNorm $categoryNorm $badgeNorm';
        match = tokens.every((token) {
          if (combined.contains(token)) return true;
          if (token.startsWith('ال') && token.length >= 4) {
            return combined.contains(token.substring(2));
          }
          return false;
        });
      } else if (tokens.length == 1 && tokens.first.startsWith('ال') && tokens.first.length >= 4) {
        // كلمة مفردة بمرونة "ال" التعريف
        final withoutAl = tokens.first.substring(2);
        final combined = '$titleNorm $subtitleNorm $authorNorm $categoryNorm $badgeNorm';
        if (combined.contains(withoutAl)) {
          match = true;
        }
      }

      // ٣. فحص عناوين الفصول إن وجدت
      if (!match && book.chapters.isNotEmpty) {
        for (final ch in book.chapters) {
          final chTitleNorm = ArabicSearchNormalizer.normalize(ch.title);
          if (chTitleNorm.contains(normalizedQuery)) {
            match = true;
            break;
          }
          if (tokens.length > 1 && tokens.every((t) => chTitleNorm.contains(t))) {
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
                MaterialPageRoute(
                  builder: (_) => BookReaderScreen(book: book),
                ),
              );
            },
          ),
        );
      }
    }

    return results;
  }
}


/// مزود البحث في مسارات التدبر الموجّهة (العنوان والوصف وإضاءات الآيات).
///
/// Search provider for the guided reflection pathways.
class PathwaysSearchProvider implements SearchProvider {
  /// ينشئ مزود البحث في المسارات.
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
