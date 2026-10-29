import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../data/storage/user_data_store.dart';
import '../data/ayah_link_repository.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import 'create_link_dialog.dart';
import '../../../core/design_system/app_icons.dart';

/// لوحة لإضافة آية من المصحف إلى رابط موجود أو جديد.
class AyahLinkPickerDialog extends StatefulWidget {
  final Ayah ayah;

  const AyahLinkPickerDialog({super.key, required this.ayah});

  static Future<void> show(BuildContext context, Ayah ayah) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AyahLinkPickerDialog(ayah: ayah),
    );
  }

  @override
  State<AyahLinkPickerDialog> createState() => _AyahLinkPickerDialogState();
}

class _AyahLinkPickerDialogState extends State<AyahLinkPickerDialog> {
  final AyahLinkRepository _repo = AyahLinkRepository();

  /// يضيف الآية إلى الرابط، ثم يغلق ويؤكد.
  Future<void> _addVerseToLink(String linkId, String linkTitle) async {
    await _repo.addVerseToLink(
      linkId,
      ayahId: widget.ayah.id,
      surahNumber: widget.ayah.surahNumber,
      ayahNumber: widget.ayah.ayahNumber,
      page: widget.ayah.page,
    );

    if (mounted) {
      Navigator.pop(context);
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.verseAddedToLink(linkTitle)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// ينشئ رابطاً جديداً ويضيف الآية إليه.
  Future<void> _createNewLinkAndAdd() async {
    final created = await CreateLinkDialog.show(context);
    if (created != null && mounted) {
      await _addVerseToLink(created.id, created.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surah = QuranRepository.instance.getSurah(widget.ayah.surahNumber);

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: ListenableBuilder(
        listenable: UserDataStore.instance,
        builder: (context, _) {
          final allLinks = _repo.allLinks;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppIcons.graph,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.addToAyahLink,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: context.l10n.close,
                          icon: const Icon(AppIcons.x, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.ayahReference(surah.name, widget.ayah.ayahNumber),
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.plus,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l10n.newAyahLink,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      l10n.createLinkWithVerseHint,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: _createNewLinkAndAdd,
                  ),

                  const Divider(height: 1),

                  if (allLinks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            AppIcons.graph,
                            size: 40,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.noAyahLinksYet,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: allLinks.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final link = allLinks[index];
                          final isAlreadyLinked = link.containsAyah(
                            widget.ayah.surahNumber,
                            widget.ayah.ayahNumber,
                          );

                          return ListTile(
                            leading: Icon(
                              isAlreadyLinked
                                  ? AppIcons.checkCircleFill
                                  : AppIcons.circle,
                              color: isAlreadyLinked
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              size: 22,
                            ),
                            title: Text(
                              link.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${l10n.linkedAyahsCount(link.verses.length)}${link.description != null ? ' · ${link.description}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.nightSubtitle
                                    : AppColors.daySubtitle,
                              ),
                            ),
                            trailing: isAlreadyLinked
                                ? Text(
                                    l10n.alreadyAdded,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  )
                                : Icon(AppIcons.caretRight, size: 14),
                            onTap: isAlreadyLinked
                                ? null
                                : () => _addVerseToLink(link.id, link.title),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
