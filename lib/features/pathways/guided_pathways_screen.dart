import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../ayah_links/curated_pathways.dart';
import '../quran/data/quran_repository.dart';
import '../tadbeer/tadbeer_model.dart';
import '../tadbeer/tadbeer_pause_sheet.dart';

/// تقدم المسارات الموجّهة: الأيام المكتملة لكل مسار.
class GuidedPathwayProgress {
  GuidedPathwayProgress._();

  static const _key = 'guided_pathways';

  /// الأيام المكتملة (فهارس الآيات) في المسار.
  static Set<int> completedDays(String pathwayId) {
    final state = UserDataStore.instance.featureState(_key);
    return {
      for (final d in (state[pathwayId] as List? ?? const []))
        (d as num).toInt(),
    };
  }

  /// يسجّل إتمام يوم في المسار.
  static Future<void> completeDay(String pathwayId, int day) {
    final state = UserDataStore.instance.featureState(_key);
    final days = {...completedDays(pathwayId), day}.toList()..sort();
    state[pathwayId] = days;
    return UserDataStore.instance.saveFeatureState(_key, state);
  }
}

/// قائمة المسارات التدبرية الموجّهة مع تقدم كل مسار.
class GuidedPathwaysScreen extends StatelessWidget {
  /// ينشئ شاشة المسارات الموجّهة.
  const GuidedPathwaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.guidedPathways)),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.guidedPathwaysHint,
                  style: TextStyle(
                    height: 1.6,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
              for (final p in CuratedPathwaysRegistry.pathways)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Builder(
                    builder: (context) {
                      final done = GuidedPathwayProgress.completedDays(p.id);
                      final total = p.verses.length;
                      final complete = done.length >= total;
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
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (complete)
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: gold,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.description,
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
                                      value: done.length / total,
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
          ),
        ),
      ),
    );
  }
}

/// رحلة مسار واحد: يوم لكل آية، يُفتح كل يوم بعد إتمام الذي قبله.
class PathwayJourneyScreen extends StatelessWidget {
  /// المسار المعروض.
  final CuratedPathway pathway;

  /// ينشئ شاشة رحلة المسار.
  const PathwayJourneyScreen({super.key, required this.pathway});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(title: Text(pathway.title)),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final done = GuidedPathwayProgress.completedDays(pathway.id);
            final complete = done.length >= pathway.verses.length;
            // The first unfinished day is today's; later days stay locked.
            final today = List.generate(
              pathway.verses.length,
              (i) => i,
            ).firstWhere((i) => !done.contains(i), orElse: () => -1);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (complete) const _CompletionBadge(),
                for (var i = 0; i < pathway.verses.length; i++)
                  _DayCard(
                    pathwayId: pathway.id,
                    day: i,
                    verse: pathway.verses[i],
                    state: done.contains(i)
                        ? _DayState.done
                        : i == today
                        ? _DayState.today
                        : _DayState.locked,
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

  const _DayCard({
    required this.pathwayId,
    required this.day,
    required this.verse,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final ayah = QuranRepository.instance.getAyah(verse.surah, verse.ayah);
    final surah = QuranRepository.instance.getSurah(verse.surah);
    final question = TadbeerItem.questions[day % TadbeerItem.questions.length];

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
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : state == _DayState.locked
              ? Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: AppColors.textSecondary(context),
                )
              : Text(
                  ArabicSearchNormalizer.toArabicDigits(day + 1),
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
      ],
    );

    if (state != _DayState.today) {
      return Opacity(
        opacity: state == _DayState.locked ? 0.55 : 1,
        child: Card(
          child: Padding(padding: const EdgeInsets.all(14), child: header),
        ),
      );
    }

    // Today's card: verse, insight, question and actions.
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: gold, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 14),
            if (ayah != null)
              Text(
                '﴿${ayah.text}﴾',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: UserDataStore.instance.quranFontFamily,
                  fontSize: 22,
                  height: 2,
                ),
              ),
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
                  Icon(Icons.lightbulb_outline_rounded, color: gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      verse.note,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary(context),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: ayah == null
                        ? null
                        : () => TadbeerPauseSheet.show(context, ayah),
                    icon: const Icon(Icons.spa_rounded),
                    label: Text(l10n.tadbeerPause),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      GuidedPathwayProgress.completeDay(pathwayId, day);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.completeDay),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة إتمام المسار بظهور نابض.
class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge();

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
                  Icons.workspace_premium_rounded,
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
            ],
          ),
        ),
      ),
    );
  }
}
