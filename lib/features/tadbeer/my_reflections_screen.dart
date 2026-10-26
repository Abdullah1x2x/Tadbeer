import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/design_system.dart';
import '../../core/storage/user_data_store.dart';
import '../quran/data/quran_repository.dart';
import '../quran/screens/quran_screen.dart';
import 'tadbeer_model.dart';
import 'tadbeer_pause_sheet.dart';

/// شاشة «وقفاتي»: كل ما كتبه القارئ عند الآيات، وما التزم به منها.
class MyReflectionsScreen extends StatelessWidget {
  /// ينشئ شاشة وقفاتي.
  const MyReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.myReflections),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.reflectionsAll),
                Tab(text: l10n.reflectionsCommitments),
              ],
            ),
          ),
          // Each tab listens to the store itself: a const child would not
          // rebuild under a builder here.
          body: const TabBarView(children: [_AllTab(), _CommitmentsTab()]),
        ),
      ),
    );
  }
}

/// Opens the reflection on [t] to read it or carry on writing.
Future<void> _open(BuildContext context, TadbeerItem t) async {
  final ayah = QuranRepository.instance.getAyah(t.surahNumber, t.ayahNumber);
  if (ayah != null) await TadbeerPauseSheet.show(context, ayah);
}

class _AllTab extends StatelessWidget {
  const _AllTab();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: UserDataStore.instance,
    builder: (context, _) => _list(context),
  );

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      for (final t in UserDataStore.instance.tadbeerItems)
        if (!t.isEmpty) t,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (items.isEmpty) {
      return EmptyState(
        icon: AppIcons.flowerLotus,
        title: l10n.noReflectionsYet,
        hint: l10n.noReflectionsHint,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, i) => _ReflectionCard(item: items[i]),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final TadbeerItem item;

  const _ReflectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final surah = QuranRepository.instance.getSurah(item.surahNumber);
    final commitment = item.commitment;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () => _open(context, item),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 4, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.flowerLotusFill, size: 18, color: gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.ayahReference(surah.name, item.ayahNumber),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    l10n.shortDate(item.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.goToAyah,
                    icon: const Icon(AppIcons.bookOpen, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuranScreen(
                          targetSurahNumber: item.surahNumber,
                          targetAyahNumber: item.ayahNumber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Text(
                  item.combinedSummary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.6),
                ),
              ),
              if (commitment != null) ...[
                const SizedBox(height: 8),
                _CommitmentChip(done: item.commitmentDone),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether the reader did what they committed to, as a small label.
class _CommitmentChip extends StatelessWidget {
  final bool done;

  const _CommitmentChip({required this.done});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = done
        ? AppColors.primary(context)
        : AppColors.textSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? AppIcons.checkCircleFill : AppIcons.circle,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${l10n.reflectionsCommitments}: '
          '${done ? l10n.commitmentDid : l10n.commitmentPending}',
          style: TextStyle(fontSize: 12.5, color: color),
        ),
      ],
    );
  }
}

class _CommitmentsTab extends StatelessWidget {
  const _CommitmentsTab();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: UserDataStore.instance,
    builder: (context, _) => _list(context),
  );

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    DateTime at(TadbeerItem t) => t.commitmentAt ?? t.updatedAt;
    // What is still to do comes first, the latest on top.
    final items =
        [
          for (final t in UserDataStore.instance.tadbeerItems)
            if (t.commitment != null) t,
        ]..sort((a, b) {
          if (a.commitmentDone != b.commitmentDone) {
            return a.commitmentDone ? 1 : -1;
          }
          return at(b).compareTo(at(a));
        });
    if (items.isEmpty) {
      return EmptyState(
        icon: AppIcons.sealCheck,
        title: l10n.reflectionsCommitments,
        hint: l10n.noCommitmentsYet,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, i) => _CommitmentTile(item: items[i]),
    );
  }
}

class _CommitmentTile extends StatelessWidget {
  final TadbeerItem item;

  const _CommitmentTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surah = QuranRepository.instance.getSurah(item.surahNumber);
    final done = item.commitmentDone;
    final primary = AppColors.primary(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () => _open(context, item),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 10, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: done ? l10n.commitmentNotYet : l10n.commitmentDid,
                isSelected: done,
                icon: Icon(
                  AppIcons.circle,
                  color: AppColors.textSecondary(context),
                ),
                selectedIcon: Icon(AppIcons.checkCircleFill, color: primary),
                onPressed: () => UserDataStore.instance.setCommitmentDone(
                  item.surahNumber,
                  item.ayahNumber,
                  done: !done,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      item.commitment!,
                      style: TextStyle(
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        color: done ? AppColors.textSecondary(context) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.ayahReference(surah.name, item.ayahNumber)}'
                      ' · ${l10n.shortDate(item.commitmentAt ?? item.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
