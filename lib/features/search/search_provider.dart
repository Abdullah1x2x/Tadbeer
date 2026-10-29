import 'package:flutter/material.dart';

import 'built_in_search_providers.dart';

/// نتيجة بحث واحدة من أي قسم.
class SearchResultItem {
  final String id;

  /// المزوّد الذي أنتجها.
  final String providerId;

  final String sectionTitle;

  final String title;

  /// مقتطف يوضح المحتوى.
  final String snippet;

  final int? surahNumber;

  final int? ayahNumber;

  final int? page;

  /// نص الشارة الجانبية.
  final String? badge;

  final IconData? icon;

  /// ما يحدث عند النقر.
  final void Function(BuildContext context)? onTap;

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

/// قسم يشارك في البحث الشامل بتنفيذ هذه الواجهة وتسجيله في [SearchRegistry].
abstract class SearchProvider {
  /// معرّف المزوّد ('quran'، 'notes'، 'tadbeer'…).
  String get id;

  /// اسم القسم بلغة الواجهة.
  String getSectionTitle(BuildContext context);

  /// أيقونة القسم.
  IconData get icon;

  /// يبحث عن [query] في هذا القسم.
  Future<List<SearchResultItem>> search(String query, BuildContext context);
}

/// سجل مزوّدات البحث في التطبيق.
class SearchRegistry {
  static final SearchRegistry instance = SearchRegistry._internal();

  final Map<String, SearchProvider> _providers = {};

  SearchRegistry._internal() {
    registerDefaults();
  }

  /// المزوّدات المسجلة، بالترتيب.
  List<SearchProvider> get providers => List.unmodifiable(_providers.values);

  /// المزوّد [id]، أو null.
  SearchProvider? getProvider(String id) => _providers[id];

  void register(SearchProvider provider) {
    _providers[provider.id] = provider;
  }

  void unregister(String id) {
    _providers.remove(id);
  }

  void clear() {
    _providers.clear();
  }

  /// يسجّل المزوّدات المدمجة.
  void registerDefaults() {
    register(const QuranSearchProvider());
    register(const BooksSearchProvider());
    register(const NotesSearchProvider());
    register(const TadbeerSearchProvider());
    register(const BookmarksSearchProvider());
    register(const HighlightsSearchProvider());
    register(const AyahLinksSearchProvider());
    register(const DuasSearchProvider());
    register(const PathwaysSearchProvider());
    register(const RemindersSearchProvider());
    register(const WordMeaningsSearchProvider());
  }

  /// يعيد السجل إلى المزوّدات المدمجة.
  void resetToDefaults() {
    clear();
    registerDefaults();
  }

  /// يبحث في كل المزوّدات معاً، أو في [providerId] وحده.
  ///
  /// فشل مزوّد لا يوقف البحث، وتبقى نتائج الباقين.
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
