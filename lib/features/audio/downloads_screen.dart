import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/app_select.dart';
import '../quran/data/quran_repository.dart';
import 'audio_downloads.dart';
import 'quran_audio.dart';
import 'reciters.dart';

/// شاشة تنزيل التلاوات: كل سورة بصوت القارئ المختار، تُنزَّل أو تُحذف.
class RecitationDownloadsScreen extends StatefulWidget {
  /// ينشئ شاشة التنزيلات.
  const RecitationDownloadsScreen({super.key});

  @override
  State<RecitationDownloadsScreen> createState() =>
      _RecitationDownloadsScreenState();
}

class _RecitationDownloadsScreenState extends State<RecitationDownloadsScreen> {
  /// The reciter whose downloads are shown; the one chosen for listening.
  late Reciter _reciter = QuranAudio.instance.reciter;
  late Future<int> _bytes = AudioDownloads.instance.bytesOf(_reciter);

  @override
  void initState() {
    super.initState();
    AudioDownloads.instance.ready().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _refreshSize() =>
      setState(() => _bytes = AudioDownloads.instance.bytesOf(_reciter));

  Future<void> _download(int surah) async {
    HapticFeedback.selectionClick();
    await AudioDownloads.instance.downloadSurah(_reciter, surah);
    if (mounted) _refreshSize();
  }

  /// The surahs of Juz Amma (an-Naba to an-Nas), one after another.
  Future<void> _downloadJuzAmma() async {
    HapticFeedback.selectionClick();
    for (var s = 78; s <= 114; s++) {
      if (!mounted) return;
      if (AudioDownloads.instance.isDownloaded(_reciter, s)) continue;
      if (!await AudioDownloads.instance.downloadSurah(_reciter, s)) break;
      if (mounted) _refreshSize();
    }
  }

  Future<void> _deleteAll() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllDownloads),
        content: Text(l10n.deleteAllDownloadsConfirm(_reciter.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AudioDownloads.instance.deleteAll(_reciter);
    if (mounted) _refreshSize();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final downloads = AudioDownloads.instance;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.recitationDownloads)),
        body: ListenableBuilder(
          listenable: downloads,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AppSelectField<String>(
                title: l10n.reciterLabel,
                icon: AppIcons.headphones,
                value: _reciter.id,
                options: [
                  for (final r in reciters)
                    AppSelectOption(
                      value: r.id,
                      label: r.lowQuality
                          ? '${r.name} (${l10n.lowerQuality})'
                          : r.name,
                    ),
                ],
                onChanged: (id) => setState(() {
                  _reciter = reciterById(id);
                  _bytes = downloads.bytesOf(_reciter);
                }),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.downloadsHint,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<int>(
                      future: _bytes,
                      builder: (context, snap) => Text(
                        // One decimal, so a few small files still show.
                        l10n.downloadsSize(
                          l10n
                              .digits(
                                ((snap.data ?? 0) / 1048576).toStringAsFixed(1),
                              )
                              .replaceAll('.', l10n.isArabic ? '٫' : '.'),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _deleteAll,
                    icon: const Icon(AppIcons.trash, size: 18),
                    label: Text(l10n.deleteAllDownloads),
                  ),
                ],
              ),
              FilledButton.tonalIcon(
                onPressed: _downloadJuzAmma,
                icon: const Icon(AppIcons.downloadSimple),
                label: Text(l10n.downloadJuzAmma),
              ),
              const SizedBox(height: 8),
              for (var s = 1; s <= 114; s++)
                _SurahRow(
                  surah: s,
                  reciter: _reciter,
                  onDownload: () => _download(s),
                  onDeleted: _refreshSize,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  final int surah;
  final Reciter reciter;
  final VoidCallback onDownload;
  final VoidCallback onDeleted;

  const _SurahRow({
    required this.surah,
    required this.reciter,
    required this.onDownload,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final downloads = AudioDownloads.instance;
    final info = QuranRepository.instance.getSurah(surah);
    final progress = downloads.progressOf(reciter, surah);
    final done = downloads.isDownloaded(reciter, surah);
    final failed = downloads.failed.contains((reciter.id, surah));
    final gold = AppColors.accentGold(context);
    final String subtitle;
    if (progress != null) {
      subtitle = l10n.percent((progress * 100).round());
    } else if (failed) {
      subtitle = l10n.downloadFailed;
    } else if (done) {
      subtitle = l10n.downloadedLabel;
    } else {
      subtitle = l10n.ayahCount(info.ayahCount);
    }
    final Widget trailing;
    if (progress != null) {
      trailing = IconButton(
        tooltip: l10n.cancelDownload,
        onPressed: () => downloads.cancel(reciter, surah),
        icon: SizedBox.square(
          dimension: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: progress, strokeWidth: 2.5),
              const Icon(AppIcons.x, size: 12),
            ],
          ),
        ),
      );
    } else if (done) {
      trailing = IconButton(
        tooltip: l10n.deleteDownload,
        onPressed: () async {
          await downloads.deleteSurah(reciter, surah);
          onDeleted();
        },
        icon: Icon(AppIcons.checkCircleFill, color: gold),
      );
    } else {
      trailing = IconButton(
        tooltip: l10n.downloadSurah,
        onPressed: onDownload,
        icon: const Icon(AppIcons.downloadSimple),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: gold.withValues(alpha: 0.14),
        child: Text(
          l10n.digits(surah),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      title: Text(
        'سورة ${info.name}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: failed
              ? Theme.of(context).colorScheme.error
              : AppColors.textSecondary(context),
        ),
      ),
      trailing: trailing,
    );
  }
}
