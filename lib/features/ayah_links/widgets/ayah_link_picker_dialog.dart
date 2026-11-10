import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/theme/theme.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/storage/user_data_store.dart';
import '../../quran/qcf/qcf_ayah_text.dart';
import '../data/ayah_link_repository.dart';
import 'create_link_dialog.dart';

/// لوحة لإضافة آية أو نطاق آيات متتالية من المصحف إلى رابط موجود أو جديد.
class AyahLinkPickerDialog extends StatefulWidget {
  final Ayah ayah;

  const AyahLinkPickerDialog({super.key, required this.ayah});

  static Future<void> show(BuildContext context, Ayah ayah) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AyahLinkPickerDialog(ayah: ayah),
    );
  }

  @override
  State<AyahLinkPickerDialog> createState() => _AyahLinkPickerDialogState();
}

class _AyahLinkPickerDialogState extends State<AyahLinkPickerDialog> {
  final AyahLinkRepository _repo = AyahLinkRepository();
  final TextEditingController _noteController = TextEditingController();

  late Ayah _currentAyah;
  late int _fromAyahNumber;
  late int _toAyahNumber;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentAyah = widget.ayah;
    _fromAyahNumber = widget.ayah.ayahNumber;
    _toAyahNumber = widget.ayah.ayahNumber;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _switchAyah(Ayah ayah) {
    setState(() {
      _currentAyah = ayah;
      _fromAyahNumber = ayah.ayahNumber;
      _toAyahNumber = ayah.ayahNumber;
    });
  }

  /// يضيف الآية أو نطاق الآيات إلى الرابط مع الخاطرة، ثم يغلق ويؤكد.
  Future<void> _addVerseToLink(String linkId, String linkTitle) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final startAyah = QuranRepository.instance.getAyah(
            _currentAyah.surahNumber,
            _fromAyahNumber,
          ) ??
          _currentAyah;

      final noteText = _noteController.text.trim();

      await _repo.addVerseToLink(
        linkId,
        ayahId: startAyah.id,
        surahNumber: startAyah.surahNumber,
        ayahNumber: _fromAyahNumber,
        toAyahNumber: _toAyahNumber > _fromAyahNumber ? _toAyahNumber : null,
        page: startAyah.page,
        note: noteText.isEmpty ? null : noteText,
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// ينشئ رابطاً جديداً ويضيف الآية أو نطاق الآيات إليه.
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
    final surah = QuranRepository.instance.getSurah(_currentAyah.surahNumber);
    final isMadinah = UserDataStore.instance.settings.mushafStyle ==
        MushafStyle.madinah;
    final isRange = _toAyahNumber > _fromAyahNumber;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final gold = Theme.of(context).colorScheme.primary;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: ListenableBuilder(
        listenable: UserDataStore.instance,
        builder: (context, _) {
          final allLinks = _repo.allLinks;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.graph,
                                color: gold,
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
                            tooltip: l10n.close,
                            icon: const Icon(AppIcons.x, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          // Ayah preview & range box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      AppIcons.bookOpenFill,
                                      size: 16,
                                      color: gold,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isRange
                                            ? l10n.ayahRangeReference(surah.name, l10n.digits(_fromAyahNumber), l10n.digits(_toAyahNumber))
                                            : l10n.ayahReference(
                                                surah.name,
                                                l10n.digits(_currentAyah.ayahNumber),
                                              ),
                                        style: TextStyle(
                                          fontFamily: 'IBMPlexSansArabic',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: gold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Verse texts preview
                                Builder(
                                  builder: (ctx) {
                                    final rangeAyahs = [
                                      for (int a = _fromAyahNumber;
                                          a <= _toAyahNumber;
                                          a++)
                                        QuranRepository.instance.getAyah(
                                          _currentAyah.surahNumber,
                                          a,
                                        ),
                                    ].whereType<Ayah>().toList();

                                    return Column(
                                      children: [
                                        for (final a in rangeAyahs)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: isMadinah
                                                ? QcfAyahText(
                                                    ayah: a,
                                                    fontSize: 16,
                                                    height: 1.8,
                                                    color: AppColors.textPrimary(
                                                      context,
                                                    ),
                                                    fallback: Text(
                                                      '﴿ ${a.text} ﴾ [${l10n.digits(a.ayahNumber)}]',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            UserDataStore
                                                                .instance
                                                                .quranFontFamily,
                                                        fontSize: 16,
                                                        height: 1.8,
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    '﴿ ${a.text} ﴾ [${l10n.digits(a.ayahNumber)}]',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: UserDataStore
                                                          .instance
                                                          .quranFontFamily,
                                                      fontSize: 16,
                                                      height: 1.8,
                                                    ),
                                                  ),
                                          ),
                                      ],
                                    );
                                  },
                                ),

                                const Divider(height: 16),

                                // Quick chips to expand/trim range
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (_fromAyahNumber > 1)
                                      ActionChip(
                                        avatar: const Icon(
                                          AppIcons.caretUp,
                                          size: 16,
                                        ),
                                        label: Text(
                                          l10n.includePreviousAyahShort(l10n.digits(_fromAyahNumber - 1)),
                                        ),
                                        onPressed: () {
                                          setState(() => _fromAyahNumber -= 1);
                                        },
                                      ),
                                    if (_fromAyahNumber <
                                        _currentAyah.ayahNumber)
                                      ActionChip(
                                        avatar: const Icon(
                                          AppIcons.x,
                                          size: 14,
                                        ),
                                        label: Text(
                                          l10n.excludeAyah(l10n.digits(_fromAyahNumber)),
                                        ),
                                        onPressed: () {
                                          setState(() => _fromAyahNumber += 1);
                                        },
                                      ),
                                    if (_toAyahNumber < surah.ayahCount)
                                      ActionChip(
                                        avatar: const Icon(
                                          AppIcons.caretDown,
                                          size: 16,
                                        ),
                                        label: Text(
                                          l10n.includeNextAyahShort(l10n.digits(_toAyahNumber + 1)),
                                        ),
                                        onPressed: () {
                                          setState(() => _toAyahNumber += 1);
                                        },
                                      ),
                                    if (_toAyahNumber > _currentAyah.ayahNumber)
                                      ActionChip(
                                        avatar: const Icon(
                                          AppIcons.x,
                                          size: 14,
                                        ),
                                        label: Text(
                                          l10n.excludeAyah(l10n.digits(_toAyahNumber)),
                                        ),
                                        onPressed: () {
                                          setState(() => _toAyahNumber -= 1);
                                        },
                                      ),
                                  ],
                                ),

                                // Quick switch to previous ayah only button
                                if (_currentAyah.ayahNumber > 1 && !isRange) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                      ),
                                      icon: const Icon(
                                        AppIcons.arrowLeft,
                                        size: 16,
                                      ),
                                      label: Text(
                                        l10n.selectPreviousAyahOnly(l10n.digits(_currentAyah.ayahNumber - 1)),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        final prev =
                                            QuranRepository.instance.getAyah(
                                          _currentAyah.surahNumber,
                                          _currentAyah.ayahNumber - 1,
                                        );
                                        if (prev != null) _switchAyah(prev);
                                      },
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 8),

                                // Manual Dropdowns for range
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            l10n.rangeFromLabel,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          DropdownButton<int>(
                                            value: _fromAyahNumber,
                                            isDense: true,
                                            items: [
                                              for (int a = 1;
                                                  a <= _toAyahNumber;
                                                  a++)
                                                DropdownMenuItem(
                                                  value: a,
                                                  child: Text(l10n.digits(a)),
                                                ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(
                                                  () => _fromAyahNumber = val,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            l10n.rangeToLabel,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          DropdownButton<int>(
                                            value: _toAyahNumber,
                                            isDense: true,
                                            items: [
                                              for (int a = _fromAyahNumber;
                                                  a <= surah.ayahCount;
                                                  a++)
                                                DropdownMenuItem(
                                                  value: a,
                                                  child: Text(l10n.digits(a)),
                                                ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(
                                                  () => _toAyahNumber = val,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Optional reflection note field
                          TextField(
                            controller: _noteController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: l10n.linkReflectionNoteHint,
                              prefixIcon:
                                  const Icon(AppIcons.notePencil, size: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Create new link tile
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: gold.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  AppIcons.plus,
                                  color: gold,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                l10n.newAyahLink,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: gold,
                                ),
                              ),
                              subtitle: Text(
                                l10n.createLinkWithVerseHint,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap:
                                  _isSubmitting ? null : _createNewLinkAndAdd,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Existing links section
                          Text(
                            l10n.addToExistingLinkCount(allLinks.length),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.nightSubtitle
                                  : AppColors.daySubtitle,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (allLinks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      AppIcons.graph,
                                      size: 36,
                                      color: Colors.grey.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 8),
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
                              ),
                            )
                          else
                            for (final link in allLinks) ...[
                              () {
                                final isAlreadyLinked = [
                                  for (var a = _fromAyahNumber;
                                      a <= _toAyahNumber;
                                      a++)
                                    a,
                                ].any(
                                  (a) => link.containsAyah(
                                    _currentAyah.surahNumber,
                                    a,
                                  ),
                                );

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isAlreadyLinked
                                          ? AppColors.statusWarning.withValues(alpha: 0.05)
                                          : AppColors.surface(context),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isAlreadyLinked
                                            ? AppColors.statusWarning.withValues(alpha: 0.4)
                                            : AppColors.border(context),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        isAlreadyLinked
                                            ? AppIcons.checkCircleFill
                                            : AppIcons.circle,
                                        color: isAlreadyLinked
                                            ? AppColors.statusWarning
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
                                      trailing: _isSubmitting
                                          ? const SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isAlreadyLinked) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .statusWarning
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: AppColors
                                                            .statusWarning
                                                            .withValues(
                                                                alpha: 0.4),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          AppIcons.warning,
                                                          size: 12,
                                                          color: AppColors
                                                              .statusWarning,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          l10n.alreadyAdded,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .statusWarning,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                const Icon(
                                                  AppIcons.caretRight,
                                                  size: 14,
                                                ),
                                              ],
                                            ),
                                      onTap: _isSubmitting
                                          ? null
                                          : () => _addVerseToLink(
                                                link.id,
                                                link.title,
                                              ),
                                    ),
                                  );
                              }(),
                            ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
