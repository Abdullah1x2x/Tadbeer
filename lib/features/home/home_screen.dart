import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../ayah_links/ayah_links_screen.dart';
import '../backup/backup_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../books/books_screen.dart';
import '../duas/duas_screen.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import '../highlights/highlights_screen.dart';
import '../notes/notes_screen.dart';
import '../quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import '../reminders/reminders_screen.dart';
import '../search/search_provider.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../tasbeeh/tasbeeh_screen.dart';
import '../word_meanings/word_meanings_screen.dart';

/// الشاشة الرئيسية لتطبيق تدبير وتضم لوحة الوصول السريع للمصحف وأدوات التدبر.
///
/// Serene, elegant Islamic dashboard for Tadbeer (تَدْبِير).
///
/// Features:
/// - Distinctive Brand Header with 'Amiri' calligraphy and subtle spiritual arch
/// - Prominent Quran Hero Card with live reading resume status
/// - 4 Core Contemplation & Quranic Grid Cards:
///   1. الأدعية (أدعية من الكتاب والسنة)
///   2. معاني كلمات القرآن (معجم غريب الألفاظ)
///   3. الملاحظات (خواطرك وتدبراتك)
///   4. روابط الآيات (العلاقات الموضوعية)
/// - Balanced Secondary Tools:
///   المحفوظات، المميزة، التذكيرات، النسخ الاحتياطي
class HomeScreen extends StatelessWidget {
  /// ينشئ الشاشة الرئيسية للتطبيق.
  const HomeScreen({super.key});

  /// يبني واجهة الشاشة الرئيسية المتجاوبة مع مختلف أحجام الشاشات.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final isCompact = h < 740;
              final isVeryCompact = h < 640;

              // Spacing tokens
              final paddingH = isVeryCompact ? 14.0 : (isCompact ? 18.0 : 20.0);
              final paddingV = isVeryCompact ? 6.0 : (isCompact ? 10.0 : 14.0);

              final spaceTopBar = isVeryCompact ? 4.0 : (isCompact ? 6.0 : 10.0);
              final spaceBrandToSearch = isVeryCompact ? 6.0 : (isCompact ? 10.0 : 14.0);
              final spaceSearchToHero = isVeryCompact ? 8.0 : (isCompact ? 12.0 : 16.0);
              final spaceHeroToCore = isVeryCompact ? 8.0 : (isCompact ? 10.0 : 14.0);
              final spaceCoreToSection = isVeryCompact ? 8.0 : (isCompact ? 12.0 : 18.0);
              final spaceSectionToSecondary = isVeryCompact ? 6.0 : (isCompact ? 10.0 : 14.0);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: paddingH,
                  vertical: paddingV,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                              // Top App Bar with Settings round button
                              _buildTopBar(
                                context,
                                l10n,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceTopBar),

                              // Serene Brand Header
                              _buildBrandHeader(
                                context,
                                l10n,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceBrandToSearch),

                              // Prominent Global Search Entry Bar
                              _buildGlobalSearchBar(
                                context,
                                l10n,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceSearchToHero),

                              // 1. Featured Quran Hero Card
                              _QuranHeroCard(
                                onTap: () {
                                  final pos = UserDataStore.instance.readingPosition;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuranScreen(initialPage: pos.page),
                                    ),
                                  );
                                },
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceHeroToCore),

                              // 2. قسم استغفار وتسبيح (السبحة الإلكترونية ومحراب الذكر)
                              _IstighfarTasbeehCard(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TasbeehScreen(),
                                    ),
                                  );
                                },
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceHeroToCore),

                              // 3. Core 2x2 Feature Cards Grid
                              _buildCoreFeaturesGrid(
                                context,
                                l10n,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceHeroToCore),

                              // 4. قسم كتب وملازم (مكتبة الملازم التدبرية والكتب الإسلامية)
                              _BooksHeroCard(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BooksScreen(),
                                    ),
                                  );
                                },
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceCoreToSection),

                              // Secondary Tools Section Header ("أدوات إضافية")
                              _buildSectionHeader(
                                context,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: spaceSectionToSecondary),

                              // Secondary Tools (المحفوظات، المميزة، التذكيرات، النسخ الاحتياطي)
                              _buildSecondaryToolsGrid(
                                context,
                                l10n,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: isVeryCompact ? 4.0 : 8.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }

  /// يبني الشريط العلوي للشاشة مع زر الإعدادات الدائري.
  Widget _buildTopBar(
    BuildContext context,
    AppStrings l10n,
    bool isDark, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Settings Button (in place of the side menu button)
        _TopBarIconButton(
          icon: Icons.settings_outlined,
          tooltip: l10n.settings,
          isCompact: isCompact,
          isVeryCompact: isVeryCompact,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        // Search Button in Top Bar
        _TopBarIconButton(
          icon: Icons.search_rounded,
          tooltip: l10n.search,
          isCompact: isCompact,
          isVeryCompact: isVeryCompact,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
      ],
    );
  }

  /// يبني ترويسة هوية التطبيق مع القوس الزخرفي والشعار النصي.
  Widget _buildBrandHeader(
    BuildContext context,
    AppStrings l10n,
    bool isDark, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final titleSize = isVeryCompact ? 28.0 : (isCompact ? 32.0 : 38.0);
    final taglineSize = isVeryCompact ? 11.5 : (isCompact ? 12.5 : 13.5);
    final archW = isVeryCompact ? 130.0 : (isCompact ? 150.0 : 180.0);
    final archH = isVeryCompact ? 46.0 : (isCompact ? 56.0 : 70.0);
    final iconLeafSize = isVeryCompact ? 12.0 : (isCompact ? 13.5 : 15.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Soft atmospheric arch in the background
            CustomPaint(
              size: Size(archW, archH),
              painter: _ArchBackgroundPainter(
                color: (isDark ? AppColors.darkAccentGold : AppColors.olive)
                    .withValues(alpha: isDark ? 0.08 : 0.06),
              ),
            ),
            // Brand Title
            Padding(
              padding: EdgeInsets.only(top: isVeryCompact ? 4 : (isCompact ? 6 : 10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appName,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.eco_rounded,
                      size: iconLeafSize,
                      color:
                          (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          l10n.appTagline,
          style: TextStyle(
            fontSize: taglineSize,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// يبني شريط الانتقال السريع إلى شاشة البحث الشامل مع زر تصفية تفاعلي.
  Widget _buildGlobalSearchBar(
    BuildContext context,
    AppStrings l10n,
    bool isDark, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final padV = isVeryCompact ? 8.0 : (isCompact ? 10.0 : 12.0);
    final padH = isVeryCompact ? 12.0 : (isCompact ? 14.0 : 16.0);
    final iconSize = isVeryCompact ? 19.0 : (isCompact ? 20.0 : 22.0);
    final fontSize = isVeryCompact ? 12.5 : (isCompact ? 13.0 : 14.0);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.comsilk,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: primaryColor,
                  size: iconSize,
                ),
                SizedBox(width: isVeryCompact ? 8 : 12),
                Expanded(
                  child: Text(
                    l10n.searchGlobalPlaceholder,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: fontSize,
                      color: isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.filterSearchTitle,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showSearchFilterSheet(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.tune_rounded,
                          size: isVeryCompact ? 18 : 20,
                          color: primaryColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// يعرض نافذة سفلية منبثقة لاختيار تصنيف البحث المطلوب مباشرة.
  void _showSearchFilterSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final providers = SearchRegistry.instance.providers;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.filterSearchTitle,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightPrimaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.selectSearchSection,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.nightSubtitle
                        : AppColors.daySubtitle,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.travel_explore_rounded,
                        size: 16,
                      ),
                      label: Text(l10n.searchAll),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchScreen(),
                          ),
                        );
                      },
                    ),
                    ...providers.map((p) {
                      return ActionChip(
                        avatar: Icon(p.icon, size: 16),
                        label: Text(p.getSectionTitle(context)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchScreen(
                                initialProviderId: p.id,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// يبني فاصل القسم الخاص بالأدوات الإضافية.
  Widget _buildSectionHeader(
    BuildContext context,
    bool isDark, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final fontSize = isVeryCompact ? 11.5 : (isCompact ? 12.0 : 13.0);

    return Row(
      children: [
        Expanded(
          child: Divider(color: borderColor, thickness: 1, endIndent: 12),
        ),
        Text(
          'أدوات إضافية',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.3,
          ),
        ),
        Expanded(child: Divider(color: borderColor, thickness: 1, indent: 12)),
      ],
    );
  }

  /// يبني شبكة البطاقات الأربع الأساسية (الأدعية، معاني الكلمات، الملاحظات، روابط الآيات).
  Widget _buildCoreFeaturesGrid(
    BuildContext context,
    AppStrings l10n,
    bool isDark, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final gap = isVeryCompact ? 8.0 : (isCompact ? 10.0 : 12.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GridFeatureCard(
                icon: FlutterIslamicIcons.prayer,
                title: l10n.duas,
                subtitle: 'أدعية الكتاب والسنة',
                accentColor: isDark
                    ? AppColors.darkAccentGold
                    : const Color(0xFF8B6B38),
                badgeBackground: isDark
                    ? const Color(0xFF332D20)
                    : const Color(0xFFF7F1E2),
                isCompact: isCompact,
                isVeryCompact: isVeryCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DuasScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _GridFeatureCard(
                icon: Icons.library_books_rounded,
                title: 'معاني الكلمات',
                subtitle: 'غريب ألفاظ القرآن',
                accentColor: AppColors.primary(context),
                badgeBackground: isDark
                    ? const Color(0xFF263A2F)
                    : const Color(0xFFE5EDE6),
                isCompact: isCompact,
                isVeryCompact: isVeryCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WordMeaningsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _GridFeatureCard(
                icon: Icons.edit_note_rounded,
                title: l10n.notes,
                subtitle: 'خواطرك وتدبراتك',
                accentColor: isDark
                    ? const Color(0xFF8BAA96)
                    : const Color(0xFF3D6652),
                badgeBackground: isDark
                    ? const Color(0xFF243028)
                    : const Color(0xFFE8EFEA),
                isCompact: isCompact,
                isVeryCompact: isVeryCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotesScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _GridFeatureCard(
                icon: Icons.hub_rounded,
                title: l10n.ayahLinks,
                subtitle: 'الربط والعلاقات',
                accentColor: isDark
                    ? AppColors.darkAccentGold
                    : const Color(0xFFA88A55),
                badgeBackground: isDark
                    ? const Color(0xFF302B20)
                    : const Color(0xFFF6F0E4),
                isCompact: isCompact,
                isVeryCompact: isVeryCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AyahLinksScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// يبني صف الأدوات المساندة (المحفوظات، المميزة، التذكيرات، النسخ الاحتياطي).
  Widget _buildSecondaryToolsGrid(
    BuildContext context,
    AppStrings l10n,
    bool isDark, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final tools = [
      _SecondaryToolItem(
        icon: Icons.bookmark_rounded,
        label: l10n.bookmarks,
        isCompact: isCompact,
        isVeryCompact: isVeryCompact,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookmarksScreen()),
        ),
      ),
      _SecondaryToolItem(
        icon: Icons.highlight_rounded,
        label: l10n.highlights,
        isCompact: isCompact,
        isVeryCompact: isVeryCompact,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HighlightsScreen()),
        ),
      ),
      _SecondaryToolItem(
        icon: Icons.alarm_rounded,
        label: l10n.reminders,
        isCompact: isCompact,
        isVeryCompact: isVeryCompact,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RemindersScreen()),
        ),
      ),
      _SecondaryToolItem(
        icon: Icons.backup_rounded,
        label: l10n.backup,
        isCompact: isCompact,
        isVeryCompact: isVeryCompact,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BackupScreen()),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 320) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tools.map((t) => Expanded(child: t)).toList(),
          );
        }
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: tools.map((t) => SizedBox(width: 58, child: t)).toList(),
        );
      },
    );
  }
}

/// زر أيقونة دائري مخصص للشريط العلوي في الشاشة الرئيسية.
class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isCompact;
  final bool isVeryCompact;

  /// ينشئ زر أيقونة دائري للشريط العلوي.
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isCompact = false,
    this.isVeryCompact = false,
  });

  /// يبني واجهة الزر الدائري مع التلميح النصي.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = isVeryCompact ? 7.0 : (isCompact ? 8.5 : 10.0);
    final iconSize = isVeryCompact ? 18.0 : (isCompact ? 19.0 : 20.0);

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: CircleBorder(
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        splashColor: Theme.of(context).colorScheme.primary
            .withValues(alpha: 0.15),
        hoverColor: Theme.of(context).colorScheme.primary
            .withValues(alpha: 0.08),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Icon(
              icon,
              size: iconSize,
              color: isDark ? AppColors.darkTextPrimary : AppColors.oliveDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// البطاقة البارزة للمصحف الشريف مع حالة استئناف القراءة من آخر موضع.
class _QuranHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCompact;
  final bool isVeryCompact;

  /// ينشئ بطاقة المصحف البارزة في الشاشة الرئيسية.
  const _QuranHeroCard({
    required this.onTap,
    this.isCompact = false,
    this.isVeryCompact = false,
  });

  /// يبني واجهة بطاقة المصحف ومعلومات السورة والصفحة الحالية.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pos = UserDataStore.instance.readingPosition;
    final surah = QuranRepository.instance.getSurah(pos.surahNumber);
    final readingSubtitle =
        'سورة ${surah.name} · صفحة ${ArabicSearchNormalizer.toArabicDigits(pos.page)}';

    final padH = isVeryCompact ? 12.0 : 16.0;
    final padV = isVeryCompact ? 7.0 : (isCompact ? 9.5 : 13.0);
    final badgeDim = isVeryCompact ? 36.0 : (isCompact ? 40.0 : 46.0);
    final iconDim = isVeryCompact ? 19.0 : (isCompact ? 21.0 : 24.0);
    final titleSize = isVeryCompact ? 16.0 : (isCompact ? 17.0 : 18.0);
    final subtitleSize = isVeryCompact ? 11.0 : (isCompact ? 11.8 : 12.5);
    final resumeSize = isVeryCompact ? 9.5 : (isCompact ? 10.0 : 10.5);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold)
              .withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          hoverColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: 0.06),
          splashColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                // Noble Quran Icon Badge
                Container(
                  width: badgeDim,
                  height: badgeDim,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary(context).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    FlutterIslamicIcons.quran2,
                    color: AppColors.primary(context),
                    size: iconDim,
                  ),
                ),
                SizedBox(width: isVeryCompact ? 10 : 14),

                // Title & Reading Position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.quran,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.darkAccentGold
                                        : AppColors.lightAccentGold)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'استئناف القراءة',
                                style: TextStyle(
                                  fontSize: resumeSize,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkAccentGold
                                      : const Color(0xFF8B6B38),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        readingSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Chevron
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: isVeryCompact ? 12 : 14,
                  color: (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.lightAccentGold)
                      .withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة ميزة رئيسية ضمن الشبكة الرباعية في الشاشة الرئيسية.
class _GridFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color badgeBackground;
  final VoidCallback onTap;
  final bool isCompact;
  final bool isVeryCompact;

  /// ينشئ بطاقة ميزة رئيسية للشبكة.
  const _GridFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.badgeBackground,
    required this.onTap,
    this.isCompact = false,
    this.isVeryCompact = false,
  });

  /// يبني واجهة بطاقة الميزة مع شارة الأيقونة والعنوان والوصف الفرعي.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padH = isVeryCompact ? 10.0 : 12.0;
    final padV = isVeryCompact ? 7.0 : (isCompact ? 9.0 : 12.0);
    final badgeDim = isVeryCompact ? 34.0 : (isCompact ? 38.0 : 42.0);
    final iconDim = isVeryCompact ? 18.0 : (isCompact ? 20.0 : 22.0);
    final titleSize = isVeryCompact ? 13.5 : (isCompact ? 14.5 : 15.5);
    final subtitleSize = isVeryCompact ? 10.0 : (isCompact ? 10.8 : 11.5);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withValues(alpha: 0.12),
          hoverColor: accentColor.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                // Icon Illustration Badge
                Container(
                  width: badgeDim,
                  height: badgeDim,
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, color: accentColor, size: iconDim),
                  ),
                ),
                SizedBox(width: isVeryCompact ? 8 : 10),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// عنصر أداة ثانوية يظهر في الشريط السفلي للشاشة الرئيسية.
class _SecondaryToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isCompact;
  final bool isVeryCompact;

  /// ينشئ عنصر أداة ثانوية.
  const _SecondaryToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isCompact = false,
    this.isVeryCompact = false,
  });

  /// يبني واجهة زر الأداة الثانوية مع التسمية النصية أسفله.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnDim = isVeryCompact ? 38.0 : (isCompact ? 42.0 : 46.0);
    final iconDim = isVeryCompact ? 17.0 : (isCompact ? 19.0 : 21.0);
    final gap = isVeryCompact ? 3.0 : 5.0;
    final labelSize = isVeryCompact ? 10.0 : (isCompact ? 10.5 : 11.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.15),
            hoverColor: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.08),
            child: SizedBox(
              width: btnDim,
              height: btnDim,
              child: Icon(
                icon,
                size: iconDim,
                color: isDark
                    ? AppColors.darkAccentGold
                    : AppColors.lightPrimary,
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// البطاقة البارزة لقسم الاستغفار والتسبيح (السبحة الإلكترونية ومحراب الذكر).
class _IstighfarTasbeehCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCompact;
  final bool isVeryCompact;

  /// ينشئ بطاقة الاستغفار والتسبيح للشاشة الرئيسية.
  const _IstighfarTasbeehCard({
    required this.onTap,
    this.isCompact = false,
    this.isVeryCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;

    final padH = isVeryCompact ? 12.0 : 16.0;
    final padV = isVeryCompact ? 7.0 : (isCompact ? 9.5 : 12.5);
    final badgeDim = isVeryCompact ? 36.0 : (isCompact ? 40.0 : 46.0);
    final iconDim = isVeryCompact ? 19.0 : (isCompact ? 21.0 : 24.0);
    final titleSize = isVeryCompact ? 15.5 : (isCompact ? 16.5 : 17.5);
    final subtitleSize = isVeryCompact ? 11.0 : (isCompact ? 11.8 : 12.5);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.olive)
              .withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          hoverColor: primaryColor.withValues(alpha: 0.06),
          splashColor: primaryColor.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                // Tasbeeh Icon Badge
                Container(
                  width: badgeDim,
                  height: badgeDim,
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkAccentGold
                            : AppColors.olive)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (isDark
                              ? AppColors.darkAccentGold
                              : AppColors.olive)
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    FlutterIslamicIcons.prayer,
                    color: isDark
                        ? AppColors.darkAccentGold
                        : AppColors.oliveDark,
                    size: iconDim,
                  ),
                ),
                SizedBox(width: isVeryCompact ? 10 : 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.tasbeehAndIstighfar,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.darkAccentGold
                                        : AppColors.olive)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'الورد اليومي',
                                style: TextStyle(
                                  fontSize: isVeryCompact ? 9.5 : 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkAccentGold
                                      : AppColors.oliveDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.tasbeehSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Chevron
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: isVeryCompact ? 12 : 14,
                  color: (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.lightAccentGold)
                      .withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// البطاقة البارزة لقسم الكتب والملازم التدبرية.
class _BooksHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCompact;
  final bool isVeryCompact;

  /// ينشئ بطاقة الكتب والملازم للشاشة الرئيسية.
  const _BooksHeroCard({
    required this.onTap,
    this.isCompact = false,
    this.isVeryCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;

    final padH = isVeryCompact ? 12.0 : 16.0;
    final padV = isVeryCompact ? 7.0 : (isCompact ? 9.5 : 12.5);
    final badgeDim = isVeryCompact ? 36.0 : (isCompact ? 40.0 : 46.0);
    final iconDim = isVeryCompact ? 19.0 : (isCompact ? 21.0 : 24.0);
    final titleSize = isVeryCompact ? 15.5 : (isCompact ? 16.5 : 17.5);
    final subtitleSize = isVeryCompact ? 11.0 : (isCompact ? 11.8 : 12.5);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          hoverColor: primaryColor.withValues(alpha: 0.06),
          splashColor: primaryColor.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                // Books Icon Badge
                Container(
                  width: badgeDim,
                  height: badgeDim,
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: primaryColor,
                    size: iconDim,
                  ),
                ),
                SizedBox(width: isVeryCompact ? 10 : 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.booksAndBooklets,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.darkAccentGold
                                        : AppColors.olive)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'مكتبة المتدبر',
                                style: TextStyle(
                                  fontSize: isVeryCompact ? 9.5 : 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkAccentGold
                                      : AppColors.oliveDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.booksSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Chevron
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: isVeryCompact ? 12 : 14,
                  color: (isDark
                          ? AppColors.darkAccentGold
                          : AppColors.lightAccentGold)
                      .withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// رسام مخصص لرسم قوس إسلامي هادئ خلف عنوان التطبيق في الشاشة الرئيسية.
class _ArchBackgroundPainter extends CustomPainter {
  final Color color;

  /// ينشئ رسام القوس الخلفي باللون المحدد.
  _ArchBackgroundPainter({required this.color});

  /// يرسم مسار القوس الإسلامي على لوحة الرسم.
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Soft Islamic arch silhouette
    path.moveTo(w * 0.1, h);
    path.lineTo(w * 0.1, h * 0.55);
    path.cubicTo(w * 0.1, h * 0.15, w * 0.35, 0, w * 0.5, 0);
    path.cubicTo(w * 0.65, 0, w * 0.9, h * 0.15, w * 0.9, h * 0.55);
    path.lineTo(w * 0.9, h);

    canvas.drawPath(path, paint);
  }

  /// يحدد ما إذا كان يجب إعادة رسم القوس عند تغير اللون.
  @override
  bool shouldRepaint(covariant _ArchBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
