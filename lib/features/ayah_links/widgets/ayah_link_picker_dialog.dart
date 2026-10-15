import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/storage/user_data_store.dart';
import '../ayah_link_repository.dart';
import '../../quran/data/quran_models.dart';
import '../../quran/data/quran_repository.dart';
import 'create_link_dialog.dart';

/// لوحة سفلية تتيح للمستخدم ربط آية قرآنية من المصحف برابط آيات موجود أو جديد.
///
/// Modal bottom sheet allowing user to link an Ayah from the Mushaf action sheet
/// into an existing Ayah Link or newly created Ayah Link.
class AyahLinkPickerDialog extends StatefulWidget {
  /// الآية القرآنية المراد إضافتها إلى رابط الآيات.
  final Ayah ayah;

  /// ينشئ لوحة اختيار رابط الآيات.
  const AyahLinkPickerDialog({super.key, required this.ayah});

  /// يعرض اللوحة السفلية لاختيار رابط الآيات.
  static Future<void> show(BuildContext context, Ayah ayah) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AyahLinkPickerDialog(ayah: ayah),
    );
  }

  /// ينشئ حالة لوحة اختيار رابط الآيات.
  @override
  State<AyahLinkPickerDialog> createState() => _AyahLinkPickerDialogState();
}

/// الحالة الداخلية للوحة اختيار رابط الآيات وإدارة الإضافة والإنشاء السريع.
class _AyahLinkPickerDialogState extends State<AyahLinkPickerDialog> {
  final AyahLinkRepository _repo = AyahLinkRepository();

  /// يضيف الآية الحالية إلى الرابط المحدد ثم يغلق اللوحة ويعرض إشعار التأكيد.
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
          content: Text(
            l10n.isArabic
                ? 'تمت إضافة الآية إلى رابط «$linkTitle»'
                : 'Verse added to link "$linkTitle"',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// يفتح نافذة إنشاء رابط آيات جديد ثم يضيف الآية الحالية إليه مباشرة.
  Future<void> _createNewLinkAndAdd() async {
    final created = await CreateLinkDialog.show(context);
    if (created != null && mounted) {
      await _addVerseToLink(created.id, created.title);
    }
  }

  /// يبني واجهة اللوحة السفلية مع قائمة روابط الآيات المتاحة.
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
                  // Handle bar
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

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.hub_outlined,
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
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Verse info pill
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
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // New Link Button
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
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
                      l10n.isArabic
                          ? 'إنشاء رابط جديد وربط هذه الآية به مباشرة'
                          : 'Create a new link and add this verse directly',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: _createNewLinkAndAdd,
                  ),

                  const Divider(height: 1),

                  // Links List
                  if (allLinks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.hub_outlined,
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
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
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
                                    l10n.isArabic ? 'مضافة بالفعل' : 'Already added',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  )
                                : Icon(
                                    context.currentLanguage.direction == TextDirection.rtl
                                        ? Icons.arrow_back_ios_new_rounded
                                        : Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                  ),
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
