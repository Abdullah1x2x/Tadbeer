import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../quran/data/quran_repository.dart';
import 'memorization_model.dart';

/// شاشة الحفظ: الإحصاءات، ومراجعة اليوم، واختيار سورة للحفظ.
class MemorizationScreen extends StatelessWidget {
  /// ينشئ شاشة الحفظ.
  const MemorizationScreen({super.key});

  void _startSession(BuildContext context, List<(int, int)> verses) {
    if (verses.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HifzSessionScreen(verses: verses)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final repo = QuranRepository.instance;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.memorization)),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final due = HifzStore.dueToday();
            final memorized = HifzStore.memorizedCount();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                              Icons.psychology_rounded,
                              color: gold,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.versesMemorized(memorized),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
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
                          icon: const Icon(Icons.replay_rounded),
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
                for (var s = 1; s <= 114; s++)
                  Builder(
                    builder: (context) {
                      final surah = repo.getSurah(s);
                      final done = HifzStore.memorizedInSurah(s);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _startSession(context, [
                            for (var a = 1; a <= surah.ayahCount; a++) (s, a),
                          ]),
                          leading: CircleAvatar(
                            backgroundColor: gold.withValues(alpha: 0.14),
                            child: Text(
                              ArabicSearchNormalizer.toArabicDigits(s),
                              style: TextStyle(
                                color: gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            surah.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: done == 0
                              ? null
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: done / surah.ayahCount,
                                    minHeight: 5,
                                  ),
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// جلسة حفظ أو مراجعة: آية مخفية تُكشف ثم يقيّم المستخدم تذكّره.
class HifzSessionScreen extends StatefulWidget {
  /// الآيات بالترتيب (سورة، آية).
  final List<(int, int)> verses;

  /// ينشئ جلسة حفظ.
  const HifzSessionScreen({super.key, required this.verses});

  @override
  State<HifzSessionScreen> createState() => _HifzSessionScreenState();
}

class _HifzSessionScreenState extends State<HifzSessionScreen> {
  int _index = 0;
  bool _revealed = false;
  int _remembered = 0;

  bool get _finished => _index >= widget.verses.length;

  Future<void> _grade(bool remembered) async {
    final (s, a) = widget.verses[_index];
    HapticFeedback.selectionClick();
    await HifzStore.grade(s, a, remembered: remembered);
    if (!mounted) return;
    setState(() {
      if (remembered) _remembered++;
      _index++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.memorization),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: _index / widget.verses.length,
              minHeight: 4,
            ),
          ),
        ),
        body: _finished
            ? EmptyState(
                icon: Icons.emoji_events_rounded,
                title: l10n.sessionDone,
                hint: l10n.sessionSummary(_remembered, widget.verses.length),
                actionLabel: l10n.close,
                actionIcon: Icons.check_rounded,
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
    final words = ayah.text.split(' ');
    final font = UserDataStore.instance.quranFontFamily;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.ayahReference(surah.name, a)}  ·  '
            '${l10n.digits(_index + 1)}/${l10n.digits(widget.verses.length)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: InkWell(
                onTap: _revealed
                    ? null
                    : () => setState(() => _revealed = true),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _revealed
                            ? Text(
                                '${ayah.text} ﴿${ArabicSearchNormalizer.toArabicDigits(a)}﴾',
                                key: const ValueKey('full'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: font,
                                  fontSize: 26,
                                  height: 2.1,
                                ),
                              )
                            : Column(
                                key: const ValueKey('hidden'),
                                children: [
                                  // Only the first word is shown as a cue.
                                  Text(
                                    '${words.first} …',
                                    textAlign: TextAlign.center,
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
                                      for (var i = 1; i < words.length; i++)
                                        Container(
                                          width: 18.0 + words[i].length * 5,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.border(context),
                                            borderRadius: BorderRadius.circular(
                                              6,
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
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _revealed ? 1 : 0.4,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _revealed ? () => _grade(false) : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.needsReview),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _revealed ? () => _grade(true) : null,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.mastered),
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
