import 'package:flutter/material.dart';

import 'built_in_search_providers.dart';

/// عنصر يمثل نتيجة بحث مفردة من أي قسم قابل للبحث في التطبيق.
///
/// Item representing a single search result from any section in Tadbeer.
class SearchResultItem {
  /// المعرّف الفريد لنتيجة البحث.
  final String id;

  /// معرّف مزود البحث الذي أنتج هذه النتيجة.
  final String providerId;

  /// عنوان القسم الذي تنتمي إليه النتيجة.
  final String sectionTitle;

  /// العنوان الرئيسي لنتيجة البحث.
  final String title;

  /// المقتطف النصي الموضح لمحتوى النتيجة.
  final String snippet;

  /// رقم السورة المرتبطة بالنتيجة إن وجدت.
  final int? surahNumber;

  /// رقم الآية المرتبطة بالنتيجة إن وجدت.
  final int? ayahNumber;

  /// رقم صفحة المصحف المرتبطة بالنتيجة إن وجدت.
  final int? page;

  /// نص شارة التوضيح الجانبية إن وجد.
  final String? badge;

  /// أيقونة القسم أو النتيجة.
  final IconData? icon;

  /// الإجراء المنفذ عند النقر على النتيجة.
  final void Function(BuildContext context)? onTap;

  /// ينشئ عنصر نتيجة بحث جديد.
  const SearchResultItem({
    required this.id,
    required this.providerId,
    required this.sectionTitle,
    required this.title,
    required this.snippet,
    this.surahNumber,
    this.ayahNumber,
    this.page,
    this.badge,
    this.icon,
    this.onTap,
  });
}

/// واجهة قابلة للتوسعة لتزويد نتائج البحث عبر أقسام التطبيق المختلفة.
///
/// Extensible interface for providing searchable items in Tadbeer.
///
/// Any section in Tadbeer can participate in global search by implementing
/// this interface and registering with [SearchRegistry].
abstract class SearchProvider {
  /// المعرّف الفريد لمزود البحث.
  ///
  /// Unique identifier of the provider (e.g. 'quran', 'notes', 'tadbeer').
  String get id;

  /// يعيد العنوان المترجم للقسم (مثل "المصحف" أو "الملاحظات").
  ///
  /// Localized title of the section (e.g. "المصحف", "الملاحظات").
  String getSectionTitle(BuildContext context);

  /// الأيقونة الممثلة لهذا القسم في البحث.
  ///
  /// Representative icon for this search section.
  IconData get icon;

  /// ينفذ عملية البحث عن النص الممرر داخل هذا القسم ويعيد قائمة النتائج.
  ///
  /// Executes search for [query] within this section and returns formatted results.
  Future<List<SearchResultItem>> search(String query, BuildContext context);
}

/// السجل المركزي الذي يدير جميع مزودات البحث المسجلة في التطبيق.
///
/// Central registry managing all search providers across the application.
class SearchRegistry {
  /// النسخة المفردة (Singleton) من سجل البحث.
  static final SearchRegistry instance = SearchRegistry._internal();

  final Map<String, SearchProvider> _providers = {};

  SearchRegistry._internal() {
    registerDefaults();
  }

  /// قائمة مزودات البحث المسجلة بالترتيب.
  ///
  /// Registered providers in order.
  List<SearchProvider> get providers => List.unmodifiable(_providers.values);

  /// يسترجع مزود بحث محدد بواسطة معرّفه، أو قيمة فارغة إن لم يوجد.
  ///
  /// Returns a specific provider by its [id], or null if not found.
  SearchProvider? getProvider(String id) => _providers[id];

  /// يسجل مزود بحث جديد في السجل.
  ///
  /// Registers a new [SearchProvider].
  void register(SearchProvider provider) {
    _providers[provider.id] = provider;
  }

  /// يلغي تسجيل مزود بحث بواسطة معرّفه.
  ///
  /// Unregisters a provider by its [id].
  void unregister(String id) {
    _providers.remove(id);
  }

  /// يمسح جميع مزودات البحث المسجلة.
  ///
  /// Clears all registered providers.
  void clear() {
    _providers.clear();
  }

  /// يسجل مزودات البحث الافتراضية المدمجة في تطبيق تدبير.
  ///
  /// Registers the standard built-in search providers for Tadbeer.
  void registerDefaults() {
    register(const QuranSearchProvider());
    register(const NotesSearchProvider());
    register(const TadbeerSearchProvider());
    register(const BookmarksSearchProvider());
    register(const HighlightsSearchProvider());
    register(const AyahLinksSearchProvider());
    register(const DuasSearchProvider());
    register(const RemindersSearchProvider());
    register(const WordMeaningsSearchProvider());
  }

  /// يعيد ضبط السجل إلى مزودات البحث الافتراضية.
  ///
  /// Resets the registry to its default built-in providers.
  void resetToDefaults() {
    clear();
    registerDefaults();
  }

  /// ينفذ البحث بشكل متزامن عبر جميع المزودات المسجلة (أو المزود المحدد فقط).
  ///
  /// Concurrently executes search across all registered providers (or filtered to [providerId]).
  ///
  /// Graceful error isolation: If one provider throws an exception, other providers
  /// will still return their results without aborting the entire search.
  Future<List<SearchResultItem>> searchAll(
    String query,
    BuildContext context, {
    String? providerId,
  }) async {
    final trimmed = query.trim();
    if (providerId == null && trimmed.isEmpty) return const [];

    final targetProviders = providerId != null
        ? (_providers.containsKey(providerId)
            ? [_providers[providerId]!]
            : <SearchProvider>[])
        : _providers.values.toList();

    if (targetProviders.isEmpty) return const [];

    final searchFutures = targetProviders.map((provider) async {
      try {
        return await provider.search(trimmed, context);
      } catch (e, stack) {
        debugPrint('SearchProvider [${provider.id}] failed: $e\n$stack');
        return <SearchResultItem>[];
      }
    });

    final nestedResults = await Future.wait(searchFutures);
    return nestedResults.expand((list) => list).toList();
  }
}
