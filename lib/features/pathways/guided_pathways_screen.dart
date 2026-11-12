import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/design_system.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/theme.dart';
import '../../data/models/tadbeer_model.dart';
import '../../data/models/user_settings_model.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../../data/storage/user_data_store.dart';
import '../audio/quran_audio.dart';
import '../ayah_links/data/curated_pathways.dart';
import '../continue/last_activity.dart';
import '../onboarding/tour/section_guide.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../quran/screens/quran_screen.dart';
import '../tadbeer/tadbeer_pause_sheet.dart';
import '../tadbeer/tadbeer_questions.dart';

/// تقدّم المسارات الموجّهة: الأيام المكتملة في كل مسار.
class GuidedPathwayProgress {
  GuidedPathwayProgress._();

  static const _key = 'guided_pathways';

  /// الأيام المكتملة في المسار (أرقام آياتها بدءاً من `0`).
  static Set<int> completedDays(String pathwayId, {int? maxDays}) {
    final state = UserDataStore.instance.featureState(_key);
    return {
      for (final d in (state[pathwayId] as List? ?? const []))
        if ((d as num).toInt() >= 0 &&
            (maxDays == null || d.toInt() < maxDays))
          d.toInt(),
    };
  }

  /// هل أتم القارئ جميع أيام [pathway] كاملةً.
  static bool isComplete(CuratedPathway pathway, Set<int> done) {
    final total = pathway.verses.length;
    if (total == 0) return false;
    for (var i = 0; i < total; i++) {
      if (!done.contains(i)) return false;
    }
    return true;
  }

  /// يسجّل إتمام يوم في المسار مع احتسابه في سلسلة النشاط اليومي.
  static Future<void> completeDay(
    String pathwayId,
    int day, {
    DateTime? now,
  }) async {
    final state = UserDataStore.instance.featureState(_key);
    final days = {...completedDays(pathwayId), day}.toList()..sort();
    state[pathwayId] = days;
    await UserDataStore.instance.saveFeatureState(_key, state);
    await UserDataStore.instance.markActiveDay(now: now);
  }

  /// يتراجع عن إتمام يوم في المسار.
  static Future<void> uncompleteDay(String pathwayId, int day) {
    final state = UserDataStore.instance.featureState(_key);
    final days = completedDays(pathwayId)..remove(day);
    if (days.isEmpty) {
      state.remove(pathwayId);
    } else {
      state[pathwayId] = days.toList()..sort();
    }
    return UserDataStore.instance.saveFeatureState(_key, state);
  }

  /// يعيد ضبط أيام المسار للبدء من اليوم الأول مع بقاء الخواطر محفوظة.
  static Future<void> resetPathway(String pathwayId) {
    final state = UserDataStore.instance.featureState(_key);
    state.remove(pathwayId);
    return UserDataStore.instance.saveFeatureState(_key, state);
  }
}

/// المسارات التدبرية الموجّهة وتقدّم كل منها.
class GuidedPathwaysScreen extends StatefulWidget {
  const GuidedPathwaysScreen({super.key});

  @override
  State<GuidedPathwaysScreen> createState() => _GuidedPathwaysScreenState();
}

enum _PathwayStatusFilter { all, inProgress, completed }

class _GuidedPathwaysScreenState extends State<GuidedPathwaysScreen> {
  String? _selectedCategory;
  _PathwayStatusFilter _statusFilter = _PathwayStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final categories = <String>{
      for (final p in CuratedPathwaysRegistry.pathways) p.category,
    }.toList();

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.guidedPathways),
          actions: [GuideButton(topic: GuideTopic.pathways)],
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final filtered = <CuratedPathway>[];
            for (final p in CuratedPathwaysRegistry.pathways) {
              if (_selectedCategory != null && p.category != _selectedCategory) {
                continue;
              }
              final done = GuidedPathwayProgress.completedDays(
                p.id,
                maxDays: p.verses.length,
              );
              final complete = GuidedPathwayProgress.isComplete(p, done);
              if (_statusFilter == _PathwayStatusFilter.inProgress &&
                  (complete || done.isEmpty)) {
                continue;
              }
              if (_statusFilter == _PathwayStatusFilter.completed &&
                  !complete) {
                continue;
              }
              filtered.add(p);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    l10n.guidedPathwaysHint,
                    style: TextStyle(
                      height: 1.6,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.allCategories),
                        selected:
                            _selectedCategory == null &&
                            _statusFilter == _PathwayStatusFilter.all,
                        onSelected: (_) => setState(() {
                          _selectedCategory = null;
                          _statusFilter = _PathwayStatusFilter.all;
                        }),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text(l10n.inProgressFilter),
                        selected:
                            _statusFilter == _PathwayStatusFilter.inProgress,
                        onSelected: (selected) => setState(() {
                          _statusFilter = selected
                              ? _PathwayStatusFilter.inProgress
                              : _PathwayStatusFilter.all;
                        }),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text(l10n.completedFilter),
                        selected:
                            _statusFilter == _PathwayStatusFilter.completed,
                        onSelected: (selected) => setState(() {
                          _statusFilter = selected
                              ? _PathwayStatusFilter.completed
                              : _PathwayStatusFilter.all;
                        }),
                      ),
                      for (final cat in categories) ...[
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) => setState(() {
                            _selectedCategory = selected ? cat : null;
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        l10n.noSearchResults,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ),
                for (final p in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (context) {
                        final total = p.verses.length;
                        final done = GuidedPathwayProgress.completedDays(
                          p.id,
                          maxDays: total,
                        );
                        final complete = GuidedPathwayProgress.isComplete(
                          p,
                          done,
                        );
                        final progress = total == 0
                            ? 0.0
                            : (done.length / total).clamp(0.0, 1.0);
                        return FuturisticCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PathwayJourneyScreen(pathway: p),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.title,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      p.category,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (complete) ...[
                                    const SizedBox(width: 6),
                                    Icon(AppIcons.medal, color: gold),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.description,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.daysOfTotal(done.length, total),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// رحلة مسار: يوم لكل آية، يُفتح كل يوم بعد إتمام ما قبله.
class PathwayJourneyScreen extends StatefulWidget {
  final CuratedPathway pathway;

  const PathwayJourneyScreen({super.key, required this.pathway});

  @override
  State<PathwayJourneyScreen> createState() => _PathwayJourneyScreenState();
}

class _PathwayJourneyScreenState extends State<PathwayJourneyScreen> {
  final GlobalKey _todayKey = GlobalKey();
  final Set<int> _expandedDays = {};
  bool _scrolledToToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        LastActivityStore.record(
          ActivityKind.pathway,
          ref: widget.pathway.id,
          title: widget.pathway.title,
        ),
      );
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    if (_scrolledToToday) return;
    final ctx = _todayKey.currentContext;
    if (ctx == null) return;
    _scrolledToToday = true;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.15,
      duration: AppMotion.duration(
        context,
        const Duration(milliseconds: 350),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _resetPathway(Set<int> previousDays) async {
    await GuidedPathwayProgress.resetPathway(widget.pathway.id);
    if (!mounted) return;
    setState(() {
      _expandedDays.clear();
      _scrolledToToday = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToToday();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.restartPathway),
        action: previousDays.isEmpty
            ? null
            : SnackBarAction(
                label: context.l10n.undo,
                onPressed: () {
                  for (final day in previousDays) {
                    unawaited(
                      GuidedPathwayProgress.completeDay(widget.pathway.id, day),
                    );
                  }
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pathway = widget.pathway;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pathway.title, textDirection: TextDirection.rtl),
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final done = GuidedPathwayProgress.completedDays(
              pathway.id,
              maxDays: pathway.verses.length,
            );
            final complete = GuidedPathwayProgress.isComplete(pathway, done);
            // أول يوم غير مكتمل هو يوم اليوم، وما بعده مقفل.
            final today = List.generate(
              pathway.verses.length,
              (i) => i,
            ).firstWhere((i) => !done.contains(i), orElse: () => -1);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (complete)
                  _CompletionBadge(onRestart: () => _resetPathway(done)),
                for (var i = 0; i < pathway.verses.length; i++)
                  _DayCard(
                    key: i == today ? _todayKey : null,
                    pathwayId: pathway.id,
                    day: i,
                    verse: pathway.verses[i],
                    state: done.contains(i)
                        ? _DayState.done
                        : i == today
                        ? _DayState.today
                        : _DayState.locked,
                    expanded: _expandedDays.contains(i),
                    onToggleExpand: () => setState(() {
                      if (!_expandedDays.remove(i)) {
                        _expandedDays.add(i);
                      }
                    }),
                  ),
                if (!complete)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.pathwayUnlockHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _DayState { done, today, locked }

class _DayCard extends StatelessWidget {
  final String pathwayId;
  final int day;
  final CuratedPathwayVerse verse;
  final _DayState state;
  final bool expanded;
  final VoidCallback onToggleExpand;

  const _DayCard({
    super.key,
    required this.pathwayId,
    required this.day,
    required this.verse,
    required this.state,
    required this.expanded,
    required this.onToggleExpand,
  });

  Widget _buildAyahBody(BuildContext context, Ayah ayah) {
    final fallback = Text(
      '﴿${ayah.text}﴾',
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: UserDataStore.instance.quranFontFamily,
        fontSize: 22,
        height: 2,
      ),
    );
    return UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah
        ? QcfAyahText(
            ayah: ayah,
            fontSize: 22,
            height: 2,
            color: AppColors.textPrimary(context),
            fallback: fallback,
          )
        : fallback;
  }

  Widget _buildQuickUtilities(BuildContext context, Ayah ayah, AppStrings l10n) {
    return ListenableBuilder(
      listenable: QuranAudio.instance,
      builder: (context, _) {
        final audio = QuranAudio.instance;
        final isThis =
            audio.current?.id == ayah.id && (audio.playing || audio.loading);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isThis ? AppIcons.pause : AppIcons.headphones,
                size: 18,
              ),
              tooltip: isThis ? l10n.pauseAudio : l10n.listen,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (isThis) {
                  audio.toggle();
                } else {
                  audio.playAyah(ayah);
                }
              },
            ),
            IconButton(
              icon: const Icon(AppIcons.bookOpen, size: 18),
              tooltip: l10n.goToAyah,
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuranScreen(
                    initialPage: ayah.page,
                    targetSurahNumber: ayah.surahNumber,
                    targetAyahNumber: ayah.ayahNumber,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openTadbeer(BuildContext context, Ayah ayah) async {
    final savedNow = await TadbeerPauseSheet.show(
      context,
      ayah,
      initialQuestion: day % TadbeerItem.questions.length,
    );
    // لا يُتم اليوم إلا عند حفظ إجابة غير فارغة فعلاً في هذه الجلسة.
    if (savedNow == true && state != _DayState.done) {
      await GuidedPathwayProgress.completeDay(pathwayId, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final ayah = QuranRepository.instance.getAyah(verse.surah, verse.ayah);
    final surah = QuranRepository.instance.getSurah(verse.surah);
    final question = TadbeerQuestions.forAyah(
      ayah,
      isArabic: l10n.isArabic,
    )[day % TadbeerItem.questions.length];

    final header = Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state == _DayState.locked
                ? AppColors.border(context)
                : gold.withValues(alpha: state == _DayState.done ? 1 : 0.18),
          ),
          child: state == _DayState.done
              ? const Icon(AppIcons.check, color: Colors.white, size: 20)
              : state == _DayState.locked
              ? Icon(
                  AppIcons.lock,
                  size: 16,
                  color: AppColors.textSecondary(context),
                )
              : Text(
                  l10n.digits(day + 1),
                  style: TextStyle(color: gold, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.dayN(day + 1),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          l10n.ayahReference(surah.name, verse.ayah),
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary(context),
          ),
        ),
        if (state == _DayState.done) ...[
          const SizedBox(width: 4),
          Icon(
            expanded ? AppIcons.caretUp : AppIcons.caretDown,
            size: 16,
            color: AppColors.textSecondary(context),
          ),
        ],
      ],
    );

    if (state == _DayState.locked) {
      return Opacity(
        opacity: 0.55,
        child: Card(
          child: Padding(padding: const EdgeInsets.all(14), child: header),
        ),
      );
    }

    if (state == _DayState.done && !expanded) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggleExpand,
          child: Padding(padding: const EdgeInsets.all(14), child: header),
        ),
      );
    }

    final savedTadbeer = ayah == null
        ? null
        : UserDataStore.instance.getTadbeer(ayah.surahNumber, ayah.ayahNumber);
    final summary = savedTadbeer?.combinedSummary ?? '';

    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state == _DayState.done)
          InkWell(onTap: onToggleExpand, child: header)
        else
          header,
        if (ayah != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _buildQuickUtilities(context, ayah, l10n),
          ),
          _buildAyahBody(context, ayah),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.lightbulb, color: gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verse.note,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          question,
          textAlign: TextAlign.center,
          textDirection: context.currentLanguage.direction,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary(context),
          ),
        ),
        if (state == _DayState.done && summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary(context).withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myReflectionLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: ayah == null
                    ? null
                    : () => _openTadbeer(context, ayah),
                icon: const Icon(AppIcons.flowerLotusFill),
                label: Text(l10n.tadbeerPause),
              ),
            ),
            const SizedBox(width: 10),
            if (state == _DayState.today)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    GuidedPathwayProgress.completeDay(pathwayId, day);
                  },
                  icon: const Icon(AppIcons.check),
                  label: Text(l10n.completeDay),
                ),
              )
            else
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    onToggleExpand();
                    GuidedPathwayProgress.uncompleteDay(pathwayId, day);
                  },
                  icon: const Icon(AppIcons.arrowCounterClockwise, size: 18),
                  label: Text(l10n.undo),
                ),
              ),
          ],
        ),
      ],
    );

    // بطاقة اليوم (أو اليوم المكتمل عند فتحه للمراجعة): الآية والفائدة والسؤال والإجراءات.
    return Card(
      shape: state == _DayState.today
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: gold, width: 1.4),
            )
          : null,
      child: Padding(padding: const EdgeInsets.all(16), child: bodyContent),
    );
  }
}

/// شارة إتمام المسار.
class _CompletionBadge extends StatelessWidget {
  final VoidCallback onRestart;

  const _CompletionBadge({required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.medal,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.pathwayComplete,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(AppIcons.arrowsClockwise, size: 18),
                label: Text(l10n.restartPathway),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

