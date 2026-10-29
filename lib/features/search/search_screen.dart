import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/motion/app_motion.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/quran/quran_repository.dart';
import 'search_provider.dart';
import '../../core/design_system/app_icons.dart';

/// البحث الشامل الفوري دون إنترنت في كل أقسام التطبيق.
/// يسأل كل المزوّدات معاً، مع تصفية بالقسم، وينتقل إلى وجهة النتيجة؛ أو يعيد الآية المختارة إن كان [returnToCaller].
class SearchScreen extends StatefulWidget {
  /// يعيد الآية المختارة إلى الشاشة المستدعية بدل فتح المصحف.
  final bool returnToCaller;

  /// القسم المختار عند الفتح.
  final String? initialProviderId;

  /// نص البحث عند الفتح.
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.returnToCaller = false,
    this.initialProviderId,
    this.initialQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  String _currentQuery = '';
  String? _selectedProviderId;
  String? _lastSearchedProviderId;
  bool _isLoading = false;
  List<SearchResultItem> _results = [];

  @override
  void initState() {
    super.initState();
    _selectedProviderId = widget.initialProviderId;
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _currentQuery = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _executeSearch(_controller.text, force: true);
      });
    } else if (_selectedProviderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _executeSearch('', force: true);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// يؤخّر البحث قليلاً أثناء الكتابة، فلا يتكرر مع كل حرف.
  void _onSearchChanged(String query) {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      _executeSearch(query);
    });
  }

  /// يبحث ويحدّث النتائج؛ [force] يعيد البحث ولو لم يتغير النص.
  Future<void> _executeSearch(String query, {bool force = false}) async {
    final trimmed = query.trim();
    if (!force &&
        trimmed == _currentQuery &&
        _selectedProviderId == _lastSearchedProviderId &&
        _results.isNotEmpty) {
      return;
    }

    _lastSearchedProviderId = _selectedProviderId;

    setState(() {
      _currentQuery = trimmed;
    });

    if (_selectedProviderId == null && trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await SearchRegistry.instance.searchAll(
      trimmed,
      context,
      providerId: _selectedProviderId,
    );

    if (!mounted) return;

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  /// يغيّر القسم المختار ويعيد البحث.
  void _onSelectFilter(String? providerId) {
    // النقر على القسم المختار يعيد إلى "الكل".
    final newId = (_selectedProviderId == providerId) ? null : providerId;
    setState(() {
      _selectedProviderId = newId;
    });
    _executeSearch(_controller.text, force: true);
  }

  /// عند النقر: يعيد الآية للمستدعي، أو يفتح وجهة النتيجة.
  void _handleItemTap(SearchResultItem item) {
    if (widget.returnToCaller &&
        item.surahNumber != null &&
        item.ayahNumber != null) {
      final ayah = QuranRepository.instance.getAyah(
        item.surahNumber!,
        item.ayahNumber!,
      );
      if (ayah != null) {
        Navigator.pop(context, ayah);
        return;
      }
    }

    item.onTap?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hasQuery = _currentQuery.isNotEmpty;
    final providers = SearchRegistry.instance.providers;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.search,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.comsilk,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: AppTokens.borderRegular,
                  ),
                  boxShadow: AppTokens.cardShadow(isDark: isDark),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: widget.initialQuery == null,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: _selectedProviderId != null
                        ? (l10n.isArabic
                              ? 'ابحث في ${providers.firstWhere((p) => p.id == _selectedProviderId, orElse: () => providers.first).getSectionTitle(context)}...'
                              : 'Search in ${providers.firstWhere((p) => p.id == _selectedProviderId, orElse: () => providers.first).getSectionTitle(context)}...')
                        : l10n.searchGlobalPlaceholder,
                    hintStyle: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 14,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                    prefixIcon: Icon(
                      AppIcons.magnifyingGlass,
                      color: primaryColor,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            tooltip: context.l10n.clearText,
                            icon: const Icon(AppIcons.x, size: 20),
                            onPressed: () {
                              _controller.clear();
                              _executeSearch('', force: true);
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // شرائح التصفية تلتف إلى سطر ثانٍ بدل أن تُقص عند حافة الشاشة.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Wrap(
                runSpacing: 8,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      label: Text(
                        l10n.searchAll,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 13,
                          fontWeight: _selectedProviderId == null
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: _selectedProviderId == null
                              ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : primaryColor)
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                      ),
                      selected: _selectedProviderId == null,
                      selectedColor: primaryColor.withValues(
                        alpha: isDark ? 0.30 : 0.16,
                      ),
                      checkmarkColor: isDark
                          ? AppColors.darkTextPrimary
                          : primaryColor,
                      side: BorderSide(
                        color: _selectedProviderId == null
                            ? primaryColor
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        width: _selectedProviderId == null ? 1.5 : 0.8,
                      ),
                      onSelected: (_) => _onSelectFilter(null),
                    ),
                  ),

                  ...providers.map((p) {
                    final isSelected = _selectedProviderId == p.id;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: FilterChip(
                        avatar: Icon(
                          p.icon,
                          size: 16,
                          color: isSelected
                              ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : primaryColor)
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                        label: Text(
                          p.getSectionTitle(context),
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : primaryColor)
                                : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(
                          alpha: isDark ? 0.30 : 0.16,
                        ),
                        checkmarkColor: isDark
                            ? AppColors.darkTextPrimary
                            : primaryColor,
                        side: BorderSide(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          width: isSelected ? 1.5 : 0.8,
                        ),
                        onSelected: (_) => _onSelectFilter(p.id),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.shouldAnimate(context)
                    ? AppMotion.normal
                    : Duration.zero,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.standard,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${_selectedProviderId ?? "all"}_${_isLoading}_$hasQuery',
                  ),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        )
                      : !hasQuery && _selectedProviderId == null
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.magnifyingGlass,
                                  size: 64,
                                  color: AppColors.border(context),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.searchGlobalPlaceholder,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.nightSubtitle
                                        : AppColors.daySubtitle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.selectSearchSection,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? AppColors.nightSubtitle.withValues(
                                            alpha: 0.8,
                                          )
                                        : AppColors.daySubtitle.withValues(
                                            alpha: 0.8,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.magnifyingGlassMinus,
                                  size: 56,
                                  color: isDark
                                      ? AppColors.nightSubtitle
                                      : AppColors.daySubtitle,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedProviderId != null && !hasQuery
                                      ? (_selectedProviderId == 'quran'
                                            ? (l10n.isArabic
                                                  ? 'اكتب كلمة أو اسم سورة أو ابحث بالجذر اللغوي (مثال: جذر صبر)'
                                                  : 'Type a word, surah name, or search by root (e.g. root:sbr)')
                                            : (l10n.isArabic
                                                  ? 'لا توجد عناصر محفوظة في هذا القسم بعد'
                                                  : 'No saved items in this section yet'))
                                      : l10n.noSearchResults,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.nightSubtitle
                                        : AppColors.daySubtitle,
                                  ),
                                ),
                                if (_selectedProviderId != null &&
                                    hasQuery) ...[
                                  const SizedBox(height: 16),
                                  FuturisticButton.secondary(
                                    onPressed: () => _onSelectFilter(null),
                                    icon: AppIcons.globe,
                                    label: l10n.searchInAllSections,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : _buildResultsList(context, isDark, providers),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// النتائج مجمّعة بالقسم، أو لقسم واحد مختار.
  Widget _buildResultsList(
    BuildContext context,
    bool isDark,
    List<SearchProvider> providers,
  ) {
    if (_selectedProviderId != null) {
      final provider = providers.firstWhere(
        (p) => p.id == _selectedProviderId,
        orElse: () => providers.first,
      );

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroupHeader(
            title: provider.getSectionTitle(context),
            count: _results.length,
            icon: provider.icon,
          ),
          const SizedBox(height: 10),
          ..._results.map((item) => _buildResultCard(context, item, isDark)),
        ],
      );
    }

    final Map<String, List<SearchResultItem>> grouped = {};
    for (final item in _results) {
      grouped.putIfAbsent(item.providerId, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final provider in providers)
          if (grouped.containsKey(provider.id) &&
              grouped[provider.id]!.isNotEmpty) ...[
            _buildGroupHeader(
              title: provider.getSectionTitle(context),
              count: grouped[provider.id]!.length,
              icon: provider.icon,
            ),
            const SizedBox(height: 8),
            ...grouped[provider.id]!.map(
              (item) => _buildResultCard(context, item, isDark),
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  /// ترويسة مجموعة قسم مع عدد نتائجها.
  Widget _buildGroupHeader({
    required String title,
    required int count,
    IconData? icon,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final countStr = context.currentLanguage == AppLanguage.arabic
        ? ArabicSearchNormalizer.toArabicDigits(count)
        : count.toString();

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(width: 8),
        FuturisticBadge(
          label: countStr,
          color: primary,
          showDot: true,
          isCompact: true,
        ),
      ],
    );
  }

  /// بطاقة نتيجة بحث.
  Widget _buildResultCard(
    BuildContext context,
    SearchResultItem item,
    bool isDark,
  ) {
    final isQuranAyah =
        item.providerId == 'quran' ||
        item.providerId == 'bookmarks' ||
        item.providerId == 'highlights' ||
        item.providerId == 'duas';

    final primary = Theme.of(context).colorScheme.primary;
    final accent = isQuranAyah
        ? (isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold)
        : primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FuturisticCard(
        onTap: () => _handleItemTap(item),
        borderRadius: AppTokens.radiusLg,
        padding: const EdgeInsets.all(14),
        accentColor: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightPrimaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.badge != null) ...[
                  const SizedBox(width: 8),
                  FuturisticBadge(
                    label: item.badge!,
                    color: accent,
                    isCompact: true,
                  ),
                ],
              ],
            ),
            if (item.snippet.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.snippet,
                maxLines: isQuranAyah ? null : 4,
                overflow: isQuranAyah ? null : TextOverflow.ellipsis,
                textDirection: isQuranAyah ? TextDirection.rtl : null,
                style: TextStyle(
                  fontFamily: isQuranAyah ? 'AmiriQuran' : 'Amiri',
                  fontSize: isQuranAyah ? 16 : 13,
                  height: isQuranAyah ? 1.8 : 1.4,
                  color: isDark
                      ? (isQuranAyah
                            ? AppColors.nightQuranText
                            : AppColors.darkTextSecondary)
                      : (isQuranAyah
                            ? AppColors.dayQuranText
                            : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
