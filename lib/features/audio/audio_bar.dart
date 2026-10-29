import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_icons.dart';
import '../../data/quran/quran_repository.dart';
import 'downloads_screen.dart';
import 'quran_audio.dart';
import 'reciters.dart';

/// شريط التلاوة في المصحف: الآية المسموعة وأزرار التحكم.
///
/// يظهر ما دامت التلاوة جارية أو موقوفة مؤقتاً، ويذكر الآية والقارئ، ويقول حين
/// يتوقف للتدبر.
class AudioBar extends StatelessWidget {
  const AudioBar({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = QuranAudio.instance;
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final ayah = audio.current;
        if (ayah == null) return const SizedBox.shrink();
        final l10n = context.l10n;
        final primary = Theme.of(context).colorScheme.primary;
        final gold = AppColors.accentGold(context);
        final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
        Widget control(
          IconData icon,
          String tip,
          VoidCallback onTap, {
          bool main = false,
        }) => IconButton(
          tooltip: tip,
          onPressed: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          style: main
              ? IconButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                )
              : null,
          icon: Icon(icon, size: main ? 22 : 20),
        );
        final Widget playButton = audio.loading && !audio.resting
            ? SizedBox.square(
                dimension: 48,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: primary,
                  ),
                ),
              )
            : control(
                audio.playing ? AppIcons.pauseFill : AppIcons.playFill,
                audio.playing ? l10n.pauseAudio : l10n.playAudio,
                audio.toggle,
                main: true,
              );
        return Material(
          color: AppColors.surface(context),
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: gold.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                control(
                  AppIcons.skipBackFill,
                  l10n.previousAyah,
                  audio.previous,
                ),
                playButton,
                control(AppIcons.skipForwardFill, l10n.nextAyah, audio.next),
                // متابعة التلاوة أو الوقوف عند آية واحدة.
                IconButton(
                  tooltip: audio.continuous
                      ? l10n.continuousRecitation
                      : l10n.singleAyahRecitation,
                  isSelected: !audio.continuous,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    audio.setContinuous(!audio.continuous);
                  },
                  icon: Icon(
                    audio.continuous ? AppIcons.repeat : AppIcons.repeatOnce,
                    size: 20,
                    color: audio.continuous ? null : gold,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.ayahReference(surah.name, ayah.ayahNumber),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          audio.resting
                              ? l10n.resting
                              : audio.finished
                              ? l10n.ayahFinished
                              : audio.reciter.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: audio.resting || audio.finished
                                ? gold
                                : AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                control(
                  AppIcons.slidersHorizontal,
                  l10n.audioSettings,
                  () => AudioSettingsSheet.show(context),
                ),
                control(AppIcons.x, l10n.stopAudio, audio.stop),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// إعدادات التلاوة: القارئ، والتكرار، والوقفة بعد كل آية.
class AudioSettingsSheet extends StatelessWidget {
  const AudioSettingsSheet._();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const AudioSettingsSheet._(),
  );

  static const _repeats = [1, 2, 3, 5, 10];
  static const _pauses = [0, 3, 5, 10, 20];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final audio = QuranAudio.instance;
    final gold = AppColors.accentGold(context);
    Widget heading(IconData icon, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: gold),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                l10n.audioSettings,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              heading(AppIcons.headphones, l10n.reciterLabel),
              RadioGroup<String>(
                groupValue: audio.reciter.id,
                onChanged: (id) {
                  if (id == null) return;
                  HapticFeedback.selectionClick();
                  audio.setReciter(reciterById(id));
                },
                child: Column(
                  children: [
                    for (final r in reciters)
                      RadioListTile<String>(
                        value: r.id,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.name),
                        subtitle: r.lowQuality
                            ? Text(
                                l10n.lowerQuality,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              heading(AppIcons.repeat, l10n.repeatEachAyah),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in _repeats)
                    ChoiceChip(
                      label: Text('×${l10n.digits(n)}'),
                      selected: audio.repeat == n,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        audio.setRepeat(n);
                      },
                    ),
                ],
              ),
              heading(AppIcons.hourglassMedium, l10n.pauseAfterAyah),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _pauses)
                    ChoiceChip(
                      label: Text(s == 0 ? l10n.noPause : l10n.secondsShort(s)),
                      selected: audio.pauseSeconds == s,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        audio.setPauseSeconds(s);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(AppIcons.downloadSimple, color: gold),
                title: Text(l10n.downloadForOffline),
                trailing: const Icon(AppIcons.caretRight),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecitationDownloadsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.audioSource,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
