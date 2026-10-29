import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_icons.dart';
import '../../data/storage/user_data_store.dart';
import '../../data/quran/quran_repository.dart';

/// بطاقة في الرئيسية تسأل القارئ عمّا التزم به في وقفة سابقة.
///
/// تعرض أحدث التزام كُتب قبل اليوم (انظر `UserDataStore.pendingCommitment`) مرة
/// واحدة: «فعلته» يسجّله منجزاً، و«ليس بعد» يطويه بلا تعليق. ولا تظهر إن لم
/// يوجد التزام.
class CommitmentCard extends StatelessWidget {
  /// المسافة تحت البطاقة حين تظهر.
  final double gap;

  const CommitmentCard({super.key, this.gap = 0});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) {
        final item = UserDataStore.instance.pendingCommitment();
        if (item == null) return const SizedBox.shrink();
        final l10n = context.l10n;
        final store = UserDataStore.instance;
        final surah = QuranRepository.instance.getSurah(item.surahNumber);
        final gold = AppColors.accentGold(context);
        final reference = l10n.ayahReference(surah.name, item.ayahNumber);
        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: gold.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.sealCheck, size: 18, color: gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.commitmentSaidAt(reference),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '«${item.commitment}»',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.commitmentQuestion,
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => store.setCommitmentAsked(
                        item.surahNumber,
                        item.ayahNumber,
                      ),
                      child: Text(l10n.commitmentNotYet),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: () => store.setCommitmentDone(
                        item.surahNumber,
                        item.ayahNumber,
                        done: true,
                      ),
                      icon: const Icon(AppIcons.check, size: 16),
                      label: Text(l10n.commitmentDid),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
