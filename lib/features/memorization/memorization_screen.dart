import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/design_system.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/models/user_settings_model.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../../data/storage/user_data_store.dart';
import '../audio/quran_audio.dart';
import '../continue/last_activity.dart';
import '../onboarding/tour/section_guide.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../quran/screens/quran_screen.dart';
import 'memorization_model.dart';

enum _SurahFilter { all, inProgress, completed }

/// شاشة الحفظ: الإحصاءات، ومراجعة اليوم، وبحث/تصفية السور وبدء جلسة.
class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SurahFilter _filter = _SurahFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSession(
    BuildContext context,
    List<(int, int)> verses, {
    int initialIndex = 0,
    int? trackSurahNumber,
  }) {
    if (verses.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HifzSessionScreen(
          verses: verses,
          initialIndex: initialIndex,
          trackSurahNumber: trackSurahNumber,
        ),
      ),
    );
  }

  void _openSurahOptions(
    BuildContext context,
    Surah surah,
    HifzSummary summary,
  ) {
    final s = surah.number;
    final done = summary.memorizedInSurah(s);
    final inProgress = summary.inProgressInSurah(s);
    final tracked = summary.trackedInSurah(s);
    final dueInSurahCount = summary.dueInSurah(s);
    final dueInSurah = [
      for (final v in summary.due)
        if (v.$1 == s) v,
    ];
    final lastHifz = LastActivityStore.recent()
        .where((a) => a.kind == ActivityKind.hifz && a.ref == '$s')
        .firstOrNull;
    final resumeAyah =
        lastHifz != null &&
            lastHifz.position > 1 &&
            lastHifz.position <= surah.ayahCount
        ? lastHifz.position
        : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _SurahSessionSheet(
        surah: surah,
        memorizedCount: done,
        inProgressCount: inProgress,
        dueCount: dueInSurahCount,
        trackedVerses: tracked,
        dueVerses: dueInSurah,
        resumeAyah: resumeAyah,
        onLaunch: (verses, {initialIndex = 0}) {
          Navigator.pop(sheetCtx);
          if (verses.isEmpty) return;
          final firstAyah = verses[initialIndex.clamp(0, verses.length - 1)].$2;
          unawaited(
            LastActivityStore.record(
              ActivityKind.hifz,
              ref: '$s',
              title: surah.name,
              position: firstAyah,
            ),
          );
          _startSession(
            context,
            verses,
            initialIndex: initialIndex,
            trackSurahNumber: s,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final repo = QuranRepository.instance;
    final normalizedQuery = ArabicSearchNormalizer.normalize(_query);
    final digitsQuery = ArabicSearchNormalizer.toEnglishDigits(_query.trim());

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.memorization),
          actions: [GuideButton(topic: GuideTopic.memorization)],
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final summary = HifzStore.summary();
            final due = summary.due;
            final memorized = summary.memorizedCount;
            final inProgress = summary.inProgressCount;

            final surahs = <Surah>[];
            for (var s = 1; s <= 114; s++) {
              final surah = repo.getSurah(s);
              final done = summary.memorizedInSurah(s);
              final learning = summary.inProgressInSurah(s);

              if (_filter == _SurahFilter.inProgress &&
                  (learning == 0 && (done == 0 || done >= surah.ayahCount))) {
                continue;
              }
              if (_filter == _SurahFilter.completed && done < surah.ayahCount) {
                continue;
              }
              if (normalizedQuery.isNotEmpty || digitsQuery.isNotEmpty) {
                final matchName =
                    normalizedQuery.isNotEmpty &&
                    ArabicSearchNormalizer.normalize(
                      surah.name,
                    ).contains(normalizedQuery);
                final matchNum =
                    digitsQuery.isNotEmpty && '$s'.contains(digitsQuery);
                if (!matchName && !matchNum) continue;
              }
              surahs.add(surah);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: 1 + (surahs.isEmpty ? 1 : surahs.length),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    AppIcons.brainFill,
                                    color: gold,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.versesMemorized(memorized),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (inProgress > 0)
                                          Text(
                                            l10n.versesInProgress(inProgress),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: gold,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.memorizationHint,
                                style: TextStyle(
                                  height: 1.6,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: due.isEmpty
                                    ? null
                                    : () => _startSession(context, due),
                                icon: const Icon(
                                  AppIcons.arrowCounterClockwise,
                                ),
                                label: Text(
                                  due.isEmpty
                                      ? l10n.nothingDueToday
                                      : l10n.reviewToday(due.length),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 6,
                          bottom: 8,
                        ),
                        child: Text(
                          l10n.chooseSurahToMemorize,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: l10n.searchSurahHint,
                          prefixIcon: const Icon(AppIcons.magnifyingGlass),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(AppIcons.x),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(l10n.allCategories),
                              selected: _filter == _SurahFilter.all,
                              onSelected: (_) =>
                                  setState(() => _filter = _SurahFilter.all),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: Text(l10n.inHifzProgress),
                              selected: _filter == _SurahFilter.inProgress,
                              onSelected: (selected) => setState(
                                () => _filter = selected
                                    ? _SurahFilter.inProgress
                                    : _SurahFilter.all,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: Text(l10n.completedFilter),
                              selected: _filter == _SurahFilter.completed,
                              onSelected: (selected) => setState(
                                () => _filter = selected
                                    ? _SurahFilter.completed
                                    : _SurahFilter.all,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }

                if (surahs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        l10n.noSearchResults,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  );
                }

                final surah = surahs[index - 1];
                final s = surah.number;
                final done = summary.memorizedInSurah(s);
                final learning = summary.inProgressInSurah(s);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _openSurahOptions(context, surah, summary),
                    leading: CircleAvatar(
                      backgroundColor: gold.withValues(alpha: 0.14),
                      child: Text(
                        l10n.digits(s),
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      surah.name,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: (done == 0 && learning == 0)
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (learning > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    l10n.inProgressShort(learning),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: gold,
                                    ),
                                  ),
                                ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (done / surah.ayahCount).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                    trailing: Text(
                      l10n.versesOfTotal(done, surah.ayahCount),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SurahSessionSheet extends StatefulWidget {
  final Surah surah;
  final int memorizedCount;
  final int inProgressCount;
  final int dueCount;
  final List<(int, int)> trackedVerses;
  final List<(int, int)> dueVerses;
  final int? resumeAyah;
  final void Function(List<(int, int)> verses, {int initialIndex}) onLaunch;

  const _SurahSessionSheet({
    required this.surah,
    required this.memorizedCount,
    required this.inProgressCount,
    required this.dueCount,
    required this.trackedVerses,
    required this.dueVerses,
    required this.resumeAyah,
    required this.onLaunch,
  });

  @override
  State<_SurahSessionSheet> createState() => _SurahSessionSheetState();
}

class _SurahSessionSheetState extends State<_SurahSessionSheet> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: '1');
    _toController = TextEditingController(text: '${widget.surah.ayahCount}');
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _launchRange() {
    final maxAyah = widget.surah.ayahCount;
    final fromRaw =
        int.tryParse(
          ArabicSearchNormalizer.toEnglishDigits(_fromController.text.trim()),
        ) ??
        1;
    final toRaw =
        int.tryParse(
          ArabicSearchNormalizer.toEnglishDigits(_toController.text.trim()),
        ) ??
        maxAyah;
    final start = fromRaw.clamp(1, maxAyah);
    final end = toRaw.clamp(start, maxAyah);
    final s = widget.surah.number;
    widget.onLaunch([for (var a = start; a <= end; a++) (s, a)]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = widget.surah.number;
    final total = widget.surah.ayahCount;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.surah.name,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.versesOfTotal(widget.memorizedCount, total)}'
                  '${widget.inProgressCount > 0 ? '  ·  ${l10n.inProgressShort(widget.inProgressCount)}' : ''}',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
                const SizedBox(height: 14),
                if (widget.dueVerses.isNotEmpty) ...[
                  FilledButton.icon(
                    onPressed: () => widget.onLaunch(widget.dueVerses),
                    icon: const Icon(AppIcons.arrowCounterClockwise),
                    label: Text(l10n.surahDueVerses(widget.dueCount)),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.trackedVerses.isNotEmpty &&
                    widget.trackedVerses.length > widget.dueVerses.length) ...[
                  OutlinedButton.icon(
                    onPressed: () => widget.onLaunch(widget.trackedVerses),
                    icon: const Icon(AppIcons.brainFill),
                    label: Text(
                      l10n.surahTrackedVerses(widget.trackedVerses.length),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.resumeAyah != null) ...[
                  OutlinedButton.icon(
                    onPressed: () => widget.onLaunch(
                      [for (var a = 1; a <= total; a++) (s, a)],
                      initialIndex: widget.resumeAyah! - 1,
                    ),
                    icon: const Icon(AppIcons.playFill, size: 16),
                    label: Text(l10n.continueFromAyah(widget.resumeAyah!)),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                Text(
                  l10n.customAyahRange,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.rangeFromLabel,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _toController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.rangeToLabel,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _launchRange,
                  icon: const Icon(AppIcons.check),
                  label: Text(l10n.startSession),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// جلسة حفظ أو مراجعة: آية مخفية تُكشف، ثم يقيّم القارئ تذكّره.
class HifzSessionScreen extends StatefulWidget {
  /// الآيات بالترتيب (سورة، آية).
  final List<(int, int)> verses;

  /// فهرس البداية عند استئناف جلسة سابقة.
  final int initialIndex;

  /// رقم السورة عند فتح الجلسة على سورة واحدة لتحديث «أكمل من حيث توقفت».
  final int? trackSurahNumber;

  const HifzSessionScreen({
    super.key,
    required this.verses,
    this.initialIndex = 0,
    this.trackSurahNumber,
  });

  @override
  State<HifzSessionScreen> createState() => _HifzSessionScreenState();
}

class _HifzSessionScreenState extends State<HifzSessionScreen> {
  static const int _maxHiddenPills = 20;

  late int _index;
  bool _revealed = false;
  int _hintWords = 1;
  int _remembered = 0;

  /// تقييم جارٍ، فلا يُقيَّم الآية نقرٌ ثانٍ سريع ولا تُتخطّى التي بعدها.
  bool _grading = false;

  @override
  void initState() {
    super.initState();
    _index = widget.verses.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.verses.length - 1);
  }

  bool get _finished => _index >= widget.verses.length;

  Future<void> _grade(bool remembered) async {
    if (_grading || _finished) return;
    _grading = true;
    final (s, a) = widget.verses[_index];
    unawaited(HapticFeedback.selectionClick());
    try {
      await HifzStore.grade(s, a, remembered: remembered);
      if (widget.trackSurahNumber != null) {
        final nextIdx = _index + 1;
        final nextPos = nextIdx < widget.verses.length
            ? widget.verses[nextIdx].$2
            : 1;
        final surahName = QuranRepository.instance
            .getSurah(widget.trackSurahNumber!)
            .name;
        await LastActivityStore.record(
          ActivityKind.hifz,
          ref: '${widget.trackSurahNumber}',
          title: surahName,
          position: nextPos,
        );
      }
    } finally {
      _grading = false;
    }
    if (!mounted) return;
    setState(() {
      if (remembered) _remembered++;
      _index++;
      _revealed = false;
      _hintWords = 1;
    });
  }

  Future<void> _removeCurrentVerse(int surah, int ayah) async {
    await HifzStore.remove(surah, ayah);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.removeFromHifz),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () => unawaited(HifzStore.toggle(surah, ayah)),
        ),
      ),
    );
  }

  Widget _buildRevealedAyah(BuildContext context, Ayah ayah, int ayahNum) {
    final font = UserDataStore.instance.quranFontFamily;
    final fallback = Text(
      '${ayah.text} ﴿${ArabicSearchNormalizer.toArabicDigits(ayahNum)}﴾',
      key: const ValueKey('full'),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(fontFamily: font, fontSize: 26, height: 2.1),
    );
    if (UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah) {
      return KeyedSubtree(
        key: const ValueKey('full'),
        child: QcfAyahText(
          ayah: ayah,
          fontSize: 26,
          height: 2.1,
          color: AppColors.textPrimary(context),
          fallback: fallback,
        ),
      );
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final total = widget.verses.length;
    final progressValue = total == 0 ? 1.0 : (_index / total).clamp(0.0, 1.0);

    final summaryText = _remembered >= total && total > 0
        ? l10n.sessionSummaryAllMastered(total)
        : total == 0
        ? l10n.nothingDueToday
        : l10n.sessionSummary(_remembered, total);

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.memorization),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 4,
            ),
          ),
        ),
        body: _finished
            ? EmptyState(
                icon: AppIcons.trophy,
                title: l10n.sessionDone,
                hint: summaryText,
                actionLabel: l10n.close,
                actionIcon: AppIcons.check,
                onAction: () => Navigator.pop(context),
              )
            : _buildCard(context, l10n, gold),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppStrings l10n, Color gold) {
    final (s, a) = widget.verses[_index];
    final ayah = QuranRepository.instance.getAyah(s, a);
    final surah = QuranRepository.instance.getSurah(s);
    if (ayah == null) return const SizedBox.shrink();

    final words = hifzWordsOf(ayah.text);
    final singleWord = words.length <= 1;
    final visibleCount = singleWord ? 1 : _hintWords.clamp(1, words.length);
    final hintPrefix = singleWord
        ? (words.isEmpty ? ayah.text : hifzSingleWordHint(words.first))
        : words.take(visibleCount).join(' ');
    final hiddenWordStart = singleWord ? 0 : visibleCount;
    final hiddenCount = math.max(0, words.length - hiddenWordStart);
    final pillCount = math.min(hiddenCount, _maxHiddenPills);
    final extraHidden = hiddenCount - pillCount;
    final font = UserDataStore.instance.quranFontFamily;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  '${l10n.ayahReference(surah.name, a)}  ·  '
                  '${l10n.digits(_index + 1)}/${l10n.digits(widget.verses.length)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.bookOpen, size: 19),
                tooltip: l10n.goToAyah,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuranScreen(
                      initialPage: ayah.page,
                      targetSurahNumber: s,
                      targetAyahNumber: a,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              child: InkWell(
                onTap: _revealed
                    ? null
                    : () => setState(() => _revealed = true),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ListenableBuilder(
                        listenable: QuranAudio.instance,
                        builder: (context, _) {
                          final audio = QuranAudio.instance;
                          final isThis =
                              audio.current?.id == ayah.id &&
                              (audio.playing || audio.loading);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (HifzStore.contains(s, a))
                                IconButton(
                                  icon: const Icon(AppIcons.trash, size: 18),
                                  tooltip: l10n.removeFromHifz,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _removeCurrentVerse(s, a),
                                ),
                              IconButton(
                                icon: Icon(
                                  isThis ? AppIcons.pause : AppIcons.headphones,
                                  size: 19,
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
                            ],
                          );
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _revealed
                                  ? _buildRevealedAyah(context, ayah, a)
                                  : Column(
                                      key: const ValueKey('hidden'),
                                      children: [
                                        Text(
                                          '$hintPrefix …',
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                            fontFamily: font,
                                            fontSize: 26,
                                            height: 2.1,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 6,
                                          runSpacing: 8,
                                          children: [
                                            for (
                                              var i = 0;
                                              i < pillCount;
                                              i++
                                            )
                                              Container(
                                                width:
                                                    18.0 +
                                                    words[hiddenWordStart + i]
                                                            .length *
                                                        5,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: AppColors.border(
                                                    context,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                            if (extraHidden > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: gold.withValues(
                                                    alpha: 0.14,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  l10n.moreWordsCount(
                                                    extraHidden,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: gold,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          l10n.tapToReveal,
                                          style: TextStyle(color: gold),
                                        ),
                                        if (!singleWord && hiddenCount > 1) ...[
                                          const SizedBox(height: 8),
                                          TextButton.icon(
                                            onPressed: () => setState(() {
                                              if (_hintWords + 1 >=
                                                  words.length) {
                                                _revealed = true;
                                              } else {
                                                _hintWords++;
                                              }
                                            }),
                                            icon: const Icon(
                                              AppIcons.eye,
                                              size: 16,
                                            ),
                                            label: Text(l10n.revealNextWord),
                                          ),
                                        ],
                                      ],
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
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_revealed && !_grading)
                      ? () => _grade(false)
                      : null,
                  icon: const Icon(AppIcons.arrowClockwise),
                  label: Text(l10n.needsReview),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_revealed && !_grading)
                      ? () => _grade(true)
                      : null,
                  icon: const Icon(AppIcons.check),
                  label: Text(l10n.mastered),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

