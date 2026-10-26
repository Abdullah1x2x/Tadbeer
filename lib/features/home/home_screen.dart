import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/main_shell.dart';
import '../../app/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../ayah_links/ayah_links_screen.dart';
import '../books/books_screen.dart';
import '../continue/continue_card.dart';
import '../daily/ayah_of_day_card.dart';
import '../duas/duas_screen.dart';
import '../journey/journey_summary_card.dart';

import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../notes/notes_screen.dart';
import '../quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import '../search/search_provider.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../tasbeeh/tasbeeh_screen.dart';
import '../word_meanings/word_meanings_screen.dart';
import '../../core/design_system/app_icons.dart';

/// الشاشة الرئيسية لتطبيق تدبير وتضم لوحة الوصول السريع للمصحف وأدوات التدبر.
///
/// Serene, elegant Islamic dashboard for Tadbeer (تَدْبِير).
///
/// Features:
/// - Distinctive Brand Header with 'IBMPlexSansArabic' calligraphy and subtle spiritual arch
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
        body: PatternBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final isCompact = h < 740;
                final isVeryCompact = h < 640;

                // Spacing tokens
                final paddingH = isVeryCompact
                    ? 14.0
                    : (isCompact ? 18.0 : 20.0);
                final paddingV = isVeryCompact
                    ? 6.0
                    : (isCompact ? 10.0 : 14.0);

                final spaceTopBar = isVeryCompact
                    ? 4.0
                    : (isCompact ? 6.0 : 10.0);
                final spaceBrandToSearch = isVeryCompact
                    ? 6.0
                    : (isCompact ? 10.0 : 14.0);
                final spaceSearchToHero = isVeryCompact
                    ? 8.0
                    : (isCompact ? 12.0 : 16.0);
                final spaceHeroToCore = isVeryCompact
                    ? 8.0
                    : (isCompact ? 10.0 : 14.0);

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

                          // آية اليوم مع سؤال تدبر
                          const AyahOfTheDayCard(),
                          SizedBox(height: spaceHeroToCore),

                          // 1. Featured Quran Hero Card
                          _QuranHeroCard(
                            onTap: () {
                              if (MainShell.selectTab(
                                context,
                                ShellTab.quran,
                              )) {
                                return;
                              }
                              final pos =
                                  UserDataStore.instance.readingPosition;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QuranScreen(initialPage: pos.page),
                                ),
                              );
                            },
                            isCompact: isCompact,
                            isVeryCompact: isVeryCompact,
                          ),
                          SizedBox(height: spaceHeroToCore),

                          // رحلة القراءة: الأيام المتتالية وورد اليوم
                          const JourneySummaryCard(),
                          SizedBox(height: spaceHeroToCore),

                          // آخر أذكار وكتاب وحفظ ومسار (يختفي إن لم يوجد)
                          const ContinueCard(),
                          SizedBox(height: spaceHeroToCore),

                          // 2. قسم استغفار وتسبيح (السبحة الإلكترونية ومحراب الذكر)
                          _IstighfarTasbeehCard(
                            onTap: () {
                              if (MainShell.selectTab(
                                context,
                                ShellTab.tasbeeh,
                              )) {
                                return;
                              }
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
      ),
    );
  }

  /// يبني الشريط العلوي للشاشة مع زر الإعدادات الهندسي المستقبلي.
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
        // Settings Button with squircle futuristic styling
        FuturisticIconButton(
          icon: AppIcons.gear,
          tooltip: l10n.settings,
          size: isVeryCompact ? 36 : (isCompact ? 40 : 44),
          iconSize: isVeryCompact ? 18 : (isCompact ? 19 : 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
    // Kept modest so the main cards appear without scrolling.
    final titleSize = isVeryCompact ? 25.0 : (isCompact ? 28.0 : 32.0);
    final taglineSize = isVeryCompact ? 12.0 : (isCompact ? 12.5 : 13.5);
    final archW = isVeryCompact ? 110.0 : (isCompact ? 128.0 : 150.0);
    final archH = isVeryCompact ? 40.0 : (isCompact ? 48.0 : 58.0);
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
              padding: EdgeInsets.only(
                top: isVeryCompact ? 4 : (isCompact ? 6 : 10),
              ),
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
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      AppIcons.leaf,
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
        if (!isVeryCompact) ...[
          const SizedBox(height: 4),
          OrnamentDivider(width: isCompact ? 110 : 130, starSize: 5),
        ],
      ],
    );
  }

  /// يبني شريط الانتقال السريع إلى شاشة البحث الشامل مع زر تصفية تفاعلي وتصميم مستقبلي.
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

    return FuturisticCard(
      borderRadius: AppTokens.radiusLg,
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: Row(
          children: [
            Icon(AppIcons.magnifyingGlass, color: primaryColor, size: iconSize),
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
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceXxs),
                    child: Icon(
                      AppIcons.slidersHorizontal,
                      size: isVeryCompact ? 18 : 20,
                      color: primaryColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            child: SingleChildScrollView(
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
                      Icon(
                        AppIcons.slidersHorizontal,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.filterSearchTitle,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
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
                        avatar: const Icon(AppIcons.globe, size: 16),
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
                                builder: (_) =>
                                    SearchScreen(initialProviderId: p.id),
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
          ),
        );
      },
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
                subtitle: l10n.quranAndSunnahDuas,
                accentColor: AppColors.accentGold(context),
                badgeBackground: AppColors.accentGold(context)
                    .withValues(alpha: isDark ? 0.20 : 0.12),
                isCompact: isCompact,
                isVeryCompact: isVeryCompact,
                onTap: () {
                  if (MainShell.selectTab(context, ShellTab.duas)) return;
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
                icon: AppIcons.books,
                title: l10n.wordMeanings,
                subtitle: l10n.wordsOfQuran,
                accentColor: AppColors.primary(context),
                badgeBackground: AppColors.primary(context)
                    .withValues(alpha: isDark ? 0.20 : 0.12),
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
                icon: AppIcons.notePencil,
                title: l10n.notes,
                subtitle: l10n.yourThoughtsAndReflections,
                accentColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                badgeBackground:
                    (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        .withValues(alpha: isDark ? 0.20 : 0.12),
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
                icon: AppIcons.graphFill,
                title: l10n.ayahLinks,
                subtitle: l10n.connectionsAndThemes,
                accentColor: AppColors.accentGold(context),
                badgeBackground: AppColors.accentGold(context)
                    .withValues(alpha: isDark ? 0.20 : 0.12),
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
}

/// البطاقة البارزة للمصحف الشريف بتصميم رقمي مستقبلي مع حالة استئناف القراءة.
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
    // Follows the reading position as it moves while reading.
    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pos = UserDataStore.instance.readingPosition;
    final surah = QuranRepository.instance.getSurah(pos.surahNumber);
    final readingSubtitle = context.l10n.readingPosition(
      surah.name,
      context.currentLanguage == AppLanguage.arabic
          ? ArabicSearchNormalizer.toArabicDigits(pos.page)
          : pos.page,
    );

    final padH = isVeryCompact ? 12.0 : 16.0;
    final padV = isVeryCompact ? 7.0 : (isCompact ? 9.5 : 13.0);
    final badgeDim = isVeryCompact ? 36.0 : (isCompact ? 40.0 : 46.0);
    final iconDim = isVeryCompact ? 19.0 : (isCompact ? 21.0 : 24.0);
    final titleSize = isVeryCompact ? 16.0 : (isCompact ? 17.0 : 18.0);
    final subtitleSize = isVeryCompact ? 11.0 : (isCompact ? 11.8 : 12.5);
    final goldAccent = AppColors.accentGold(context);

    return FuturisticCard(
      onTap: onTap,
      showTopAccentGlow: true,
      accentColor: goldAccent,
      borderRadius: AppTokens.radiusXl,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Row(
        children: [
          // Noble Quran Icon Badge with geometric futuristic styling
          Container(
            width: badgeDim,
            height: badgeDim,
            decoration: BoxDecoration(
              color: AppColors.primary(context)
                  .withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: goldAccent.withValues(alpha: isDark ? 0.45 : 0.35),
                width: AppTokens.borderRegular,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: goldAccent.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              FlutterIslamicIcons.quran2,
              color: isDark ? goldAccent : AppColors.primary(context),
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
                      const SizedBox(width: AppTokens.spaceXs),
                      FuturisticBadge(
                        label: context.l10n.resumeReading,
                        color: goldAccent,
                        showDot: true,
                        isCompact: isVeryCompact,
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
            AppIcons.caretLeft,
            size: isVeryCompact ? 12 : 14,
            color: goldAccent.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}

/// بطاقة ميزة رئيسية ضمن الشبكة الرباعية بتصميم رقمي مستقبلي.
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

    return FuturisticCard(
      onTap: onTap,
      accentColor: accentColor,
      borderRadius: AppTokens.radiusLg,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Row(
        children: [
          // Icon Illustration Badge with geometric squircle container
          Container(
            width: badgeDim,
            height: badgeDim,
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                width: AppTokens.borderHairline,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.12),
                        blurRadius: 6,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
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
    );
  }
}

/// البطاقة البارزة لقسم الاستغفار والتسبيح بتصميم رقمي مستقبلي.
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
    final l10n = context.l10n;
    final emeraldAccent = isDark ? AppColors.cyberEmerald : AppColors.olive;

    final padH = isVeryCompact ? 12.0 : 16.0;
    final padV = isVeryCompact ? 7.0 : (isCompact ? 9.5 : 12.5);
    final badgeDim = isVeryCompact ? 36.0 : (isCompact ? 40.0 : 46.0);
    final iconDim = isVeryCompact ? 19.0 : (isCompact ? 21.0 : 24.0);
    final titleSize = isVeryCompact ? 15.5 : (isCompact ? 16.5 : 17.5);
    final subtitleSize = isVeryCompact ? 11.0 : (isCompact ? 11.8 : 12.5);

    return FuturisticCard(
      onTap: onTap,
      showTopAccentGlow: true,
      accentColor: emeraldAccent,
      borderRadius: AppTokens.radiusXl,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Row(
        children: [
          // Tasbeeh Icon Badge
          Container(
            width: badgeDim,
            height: badgeDim,
            decoration: BoxDecoration(
              color: emeraldAccent.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: emeraldAccent.withValues(alpha: isDark ? 0.45 : 0.35),
                width: AppTokens.borderRegular,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: emeraldAccent.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              FlutterIslamicIcons.tasbih2,
              color: isDark ? emeraldAccent : AppColors.oliveDark,
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
                      const SizedBox(width: AppTokens.spaceXs),
                      FuturisticBadge(
                        label: l10n.dailyPortion,
                        color: emeraldAccent,
                        showDot: true,
                        isCompact: isVeryCompact,
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
            AppIcons.caretLeft,
            size: isVeryCompact ? 12 : 14,
            color: emeraldAccent.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

/// البطاقة البارزة لقسم الكتب والملازم التدبرية بتصميم رقمي مستقبلي.
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

    return FuturisticCard(
      onTap: onTap,
      showTopAccentGlow: true,
      accentColor: primaryColor,
      borderRadius: AppTokens.radiusXl,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Row(
        children: [
          // Books Icon Badge
          Container(
            width: badgeDim,
            height: badgeDim,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.35),
                width: AppTokens.borderRegular,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              AppIcons.bookOpenTextFill,
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
                      const SizedBox(width: AppTokens.spaceXs),
                      FuturisticBadge(
                        label: l10n.tadbeerLibrary,
                        color: primaryColor,
                        isCompact: isVeryCompact,
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
            AppIcons.caretLeft,
            size: isVeryCompact ? 12 : 14,
            color:
                (isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold)
                    .withValues(alpha: 0.8),
          ),
        ],
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
