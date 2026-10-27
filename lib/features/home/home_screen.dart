import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/main_shell.dart';
import '../../app/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../books/books_screen.dart';
import '../continue/continue_card.dart';
import '../daily/ayah_of_day_card.dart';
import '../journey/journey_screen.dart';

import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../notes/notes_screen.dart';
import '../tadbeer/commitment_card.dart';
import '../tadbeer/my_reflections_screen.dart';
import '../quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import '../search/search_provider.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/design_system/app_icons.dart';

/// الشاشة الرئيسية لتطبيق تدبير وتضم لوحة الوصول السريع للمصحف وأدوات التدبر.
///
/// Serene, elegant Islamic dashboard for Tadbeer (تَدْبِير).
///
/// From the top: the ayah of the day, what the reader committed to, the
/// Mushaf with the reading journey, where they left off, their reflections
/// and notes, and the books. Everything else is in the bar or «المزيد».
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

                final paddingH = isVeryCompact
                    ? 14.0
                    : (isCompact ? 18.0 : 20.0);
                final paddingV = isVeryCompact ? 6.0 : 10.0;
                final gap = isVeryCompact ? 8.0 : (isCompact ? 10.0 : 12.0);

                // The page fits the screen and does not scroll: the ayah
                // card takes whatever height the other cards leave. Only
                // when that is too little for the day's longest ayah (a
                // short screen with every card showing, or very large
                // text) does the page grow past the screen and scroll.
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(overscroll: false),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingH,
                      vertical: paddingV,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 580,
                          minHeight: h - paddingV * 2,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTopBar(
                                context,
                                l10n,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: gap * 0.6),
                              _buildGlobalSearchBar(
                                context,
                                l10n,
                                isDark,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                              SizedBox(height: gap),

                              // آية اليوم مع سؤال تدبر، بما بقي من الارتفاع
                              Expanded(
                                child: _HeightFloor(
                                  heightFor: (width) =>
                                      AyahOfTheDayCard.minHeight(
                                        context,
                                        width,
                                      ),
                                  child: const AyahOfTheDayCard(),
                                ),
                              ),
                              SizedBox(height: gap),

                              // سؤال عمّا التزم به القارئ في وقفة سابقة
                              CommitmentCard(gap: gap),

                              // المصحف ورحلة القراءة
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
                              SizedBox(height: gap),

                              // آخر ما توقف عنده القارئ (يختفي إن لم يوجد)
                              ContinueCard(limit: 1, gap: gap),

                              // وقفاتي والملاحظات والكتب
                              _buildShortcuts(
                                context,
                                l10n,
                                isDark,
                                gap: gap,
                                slim: isVeryCompact,
                              ),
                            ],
                          ),
                        ),
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

  /// يبني الشريط العلوي: اسم التطبيق وزر الإعدادات.
  Widget _buildTopBar(
    BuildContext context,
    AppStrings l10n,
    bool isDark, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.appName,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: isVeryCompact ? 22 : (isCompact ? 24 : 26),
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightPrimary,
            ),
          ),
        ),
        FuturisticIconButton(
          icon: AppIcons.gear,
          tooltip: l10n.settings,
          size: isVeryCompact ? 36 : (isCompact ? 40 : 42),
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

  /// يبني صف الاختصارات: وقفاتي والملاحظات وكتب وملازم.
  Widget _buildShortcuts(
    BuildContext context,
    AppStrings l10n,
    bool isDark, {
    required double gap,
    required bool slim,
  }) {
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    final gold = AppColors.accentGold(context);
    final primary = AppColors.primary(context);
    return Row(
      children: [
        Expanded(
          // Counts the reader's reflections as they write them.
          child: ListenableBuilder(
            listenable: UserDataStore.instance,
            builder: (context, _) {
              final count = UserDataStore.instance.tadbeerItems.length;
              return _ShortcutTile(
                icon: AppIcons.flowerLotusFill,
                title: l10n.myReflections,
                count: count == 0 ? null : l10n.digits(count),
                semanticsLabel: count == 0
                    ? null
                    : '${l10n.myReflections}، '
                          '${l10n.reflectionsCount(count, l10n.digits(count))}',
                accent: gold,
                slim: slim,
                onTap: () => open(const MyReflectionsScreen()),
              );
            },
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _ShortcutTile(
            icon: AppIcons.notePencil,
            title: l10n.notes,
            accent: primary,
            slim: slim,
            onTap: () => open(const NotesScreen()),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _ShortcutTile(
            icon: AppIcons.bookOpenTextFill,
            title: l10n.booksAndBooklets,
            accent: primary,
            slim: slim,
            onTap: () => open(const BooksScreen()),
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                            label: UserDataStore.instance.readingNotStarted
                                ? context.l10n.khatmaStartNow
                                : context.l10n.resumeReading,
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
          Divider(
            height: isVeryCompact ? 12 : 16,
            color: goldAccent.withValues(alpha: 0.18),
          ),
          _ReadingJourneyRow(isVeryCompact: isVeryCompact),
        ],
      ),
    );
  }
}

/// سطر رحلة القراءة في بطاقة المصحف: الأيام المتتالية وورد اليوم وتقدم
/// الختمة، ويفتح «رحلتي».
class _ReadingJourneyRow extends StatelessWidget {
  final bool isVeryCompact;

  const _ReadingJourneyRow({required this.isVeryCompact});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final journey = UserDataStore.instance.journey;
    final now = DateTime.now();
    final plan = journey.plan;
    final streak = journey.streak(now);
    final secondary = AppColors.textSecondary(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JourneyScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Semantics(
              label: '${l10n.digits(streak)} ${l10n.streakDays}',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.fire,
                    color: const Color(0xFFE07A3F),
                    size: isVeryCompact ? 17 : 19,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.digits(streak),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan == null
                        ? '${l10n.myJourney} · ${l10n.startKhatmaTitle}'
                        : '${l10n.myJourney} · ${l10n.pagesOfTarget(journey.portionPagesOn(now), plan.pagesPerDay)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: secondary),
                  ),
                  if (plan != null) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: plan.progress,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(AppIcons.chartLineUp, size: 16, color: secondary),
          ],
        ),
      ),
    );
  }
}

/// اختصار صغير في أسفل الرئيسية: أيقونة واسم، وعدد إن وُجد.
class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  /// A small count beside the icon, such as the reflections written.
  final String? count;

  /// What a screen reader says, when it differs from [title].
  final String? semanticsLabel;

  /// The icon beside the name rather than above it, for a short screen.
  final bool slim;

  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
    this.count,
    this.semanticsLabel,
    this.slim = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: semanticsLabel ?? title,
      excludeSemantics: true,
      child: FuturisticCard(
        onTap: onTap,
        accentColor: accent,
        borderRadius: AppTokens.radiusLg,
        padding: EdgeInsets.symmetric(horizontal: slim ? 4 : 6, vertical: 10),
        child: Flex(
          direction: slim ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // On a short screen a bare icon leaves the name room.
                if (slim)
                  Icon(icon, color: accent, size: 18)
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    count!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(width: slim ? 4 : 6, height: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: slim ? 13.5 : 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reports [heightFor] at the given width as its child's intrinsic
/// height, so an [IntrinsicHeight] page counts the ayah card at the least
/// height it needs; the card itself fills whatever height it is given.
class _HeightFloor extends SingleChildRenderObjectWidget {
  final double Function(double width) heightFor;

  const _HeightFloor({required this.heightFor, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightFloor(heightFor);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightFloor renderObject,
  ) => renderObject.heightFor = heightFor;
}

class _RenderHeightFloor extends RenderProxyBox {
  _RenderHeightFloor(this.heightFor);

  double Function(double width) heightFor;

  @override
  double computeMinIntrinsicHeight(double width) => heightFor(width);

  @override
  double computeMaxIntrinsicHeight(double width) => heightFor(width);

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;
}
