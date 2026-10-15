import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_repository.dart';
import '../../settings/settings_screen.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

/// Side drawer menu providing direct jump navigation across Surahs and Juzs,
/// as well as fast access to Home and Settings.
/// القائمة الجانبية للمصحف للتنقل المباشر بين السور والأجزاء والوصول السريع للرئيسية والإعدادات.
class QuranSideMenu extends StatefulWidget {
  final int currentPage;
  final ValueChanged<int> onPageSelected;

  /// ينشئ ودجت القائمة الجانبية للمصحف الشريف.
  const QuranSideMenu({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  /// ينشئ الحالة التفاعلية للقائمة الجانبية.
  @override
  State<QuranSideMenu> createState() => _QuranSideMenuState();
}

/// الحالة التفاعلية للقائمة الجانبية للمصحف الشريف.
class _QuranSideMenuState extends State<QuranSideMenu>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  /// يهيئ متحكم التبويبات بين قائمتي السور والأجزاء.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// يحرر متحكم التبويبات وحقل البحث عند إغلاق القائمة.
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// يغلق القائمة الجانبية ويعود إلى الشاشة الرئيسية للتطبيق.
  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// يغلق القائمة الجانبية ويفتح شاشة الإعدادات.
  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  /// يبني واجهة القائمة الجانبية مع التبويبات وحقل تصفية السور.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = QuranRepository.instance;

    return Drawer(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.comsilkLight,
      child: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Drawer Header
            _buildDrawerHeader(context, isDark, l10n),

            // Tab bar: Surahs / Juzs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.comsilk,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBorder,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? AppColors.nightSubtitle
                    : AppColors.daySubtitle,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(10),
                ),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: l10n.surahs),
                  Tab(text: l10n.juzs),
                ],
              ),
            ),

            // Search filter for surahs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filter = val.trim()),
                decoration: InputDecoration(
                  hintText: l10n.searchSurahsHint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.olive,
                  ),
                  suffixIcon: _filter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.comsilk,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahsList(context, repo, isDark),
                  _buildJuzsList(context, repo, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// يبني ترويسة القائمة الجانبية التي تعرض اسم التطبيق وأزرار الرئيسية والإعدادات.
  Widget _buildDrawerHeader(
    BuildContext context,
    bool isDark,
    AppStrings l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.comsilk,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FlutterIslamicIcons.quran2,
              color: AppColors.olive,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appName,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.comsilk : AppColors.oliveDark,
                  ),
                ),
                Text(
                  l10n.offlineQuranAndReflection,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
              ],
            ),
          ),
          // Home Button
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: l10n.home,
            color: AppColors.olive,
            onPressed: () => _navigateToHome(context),
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            color: AppColors.olive,
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
    );
  }

  /// يبني قائمة سور القرآن الكريم القابلة للتصفية والانتقال المباشر.
  Widget _buildSurahsList(
    BuildContext context,
    QuranRepository repo,
    bool isDark,
  ) {
    final filteredSurahs = repo.surahs.where((s) {
      if (_filter.isEmpty) return true;
      final query = ArabicSearchNormalizer.normalize(_filter);
      final normName = ArabicSearchNormalizer.normalize(s.name);
      return normName.contains(query) || s.number.toString() == _filter;
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: filteredSurahs.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
      ),
      itemBuilder: (context, index) {
        final surah = filteredSurahs[index];
        final isCurrent =
            widget.currentPage >= surah.pageStart &&
            widget.currentPage <= surah.pageEnd;

        return ListTile(
          dense: true,
          selected: isCurrent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          selectedTileColor: AppColors.olive.withValues(alpha: 0.12),
          leading: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.olive
                  : (isDark ? AppColors.darkSurface : AppColors.comsilk),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? AppColors.olive
                    : AppColors.olive.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              context.currentLanguage == AppLanguage.arabic
                  ? ArabicSearchNormalizer.toArabicDigits(surah.number)
                  : surah.number.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isCurrent
                    ? Colors.white
                    : (isDark ? AppColors.comsilk : AppColors.oliveDark),
              ),
            ),
          ),
          title: Text(
            surah.name,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.nightQuranText : AppColors.dayQuranText,
            ),
          ),
          subtitle: Text(
            '${surah.isMeccan ? context.l10n.meccan : context.l10n.medinan} · ${context.l10n.ayahsCount(context.currentLanguage == AppLanguage.arabic ? ArabicSearchNormalizer.toArabicDigits(surah.ayahCount) : surah.ayahCount)}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.nightSubtitle : AppColors.daySubtitle,
            ),
          ),
          trailing: Text(
            context.l10n.pageAbbr(
              context.currentLanguage == AppLanguage.arabic
                  ? ArabicSearchNormalizer.toArabicDigits(surah.pageStart)
                  : surah.pageStart,
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.olive,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onPageSelected(surah.pageStart);
          },
        );
      },
    );
  }

  /// يبني قائمة أجزاء القرآن الكريم الثلاثين للانتقال المباشر إلى بداية كل جزء.
  Widget _buildJuzsList(
    BuildContext context,
    QuranRepository repo,
    bool isDark,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: 30,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
      ),
      itemBuilder: (context, index) {
        final juzNum = index + 1;
        final startPage = repo.pages.firstWhere(
          (p) => p.juzNumber == juzNum,
          orElse: () => repo.pages.first,
        );

        final firstAyah = startPage.ayahs.first;
        final surah = repo.getSurah(firstAyah.surahNumber);
        final isCurrent = repo.getPage(widget.currentPage).juzNumber == juzNum;

        return ListTile(
          dense: true,
          selected: isCurrent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          selectedTileColor: AppColors.olive.withValues(alpha: 0.12),
          leading: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.olive
                  : (isDark ? AppColors.darkSurface : AppColors.comsilk),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? AppColors.olive
                    : AppColors.olive.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              context.currentLanguage == AppLanguage.arabic
                  ? ArabicSearchNormalizer.toArabicDigits(juzNum)
                  : juzNum.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isCurrent
                    ? Colors.white
                    : (isDark ? AppColors.comsilk : AppColors.oliveDark),
              ),
            ),
          ),
          title: Text(
            context.l10n.juzAbbr(
              context.currentLanguage == AppLanguage.arabic
                  ? ArabicSearchNormalizer.toArabicDigits(juzNum)
                  : juzNum,
            ),
            style: TextStyle(
              fontFamily: context.currentLanguage == AppLanguage.arabic ? 'Amiri' : null,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.nightQuranText : AppColors.dayQuranText,
            ),
          ),
          subtitle: Text(
            context.l10n.ayahReference(
              surah.name,
              context.currentLanguage == AppLanguage.arabic
                  ? ArabicSearchNormalizer.toArabicDigits(firstAyah.ayahNumber)
                  : firstAyah.ayahNumber,
            ),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.nightSubtitle : AppColors.daySubtitle,
            ),
          ),
          trailing: Text(
            context.l10n.pageAbbr(
              context.currentLanguage == AppLanguage.arabic
                  ? ArabicSearchNormalizer.toArabicDigits(startPage.pageNumber)
                  : startPage.pageNumber,
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.olive,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onPageSelected(startPage.pageNumber);
          },
        );
      },
    );
  }
}
