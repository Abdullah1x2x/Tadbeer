import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../ayah_link_repository.dart';
import '../../quran/data/quran_models.dart';
import '../../quran/data/quran_repository.dart';

/// نافذة حوار لاختيار آية قرآنية وإضافتها مع ملاحظة تدبرية إلى رابط الآيات.
///
/// Dialog allowing user to select a verified Quran Ayah and add it to an Ayah Link.
class AddVerseToLinkDialog extends StatefulWidget {
  /// معرّف رابط الآيات المراد إضافة الآية إليه.
  final String linkId;

  /// قائمة معرّفات الآيات المضافة مسبقاً في هذا الرابط.
  final List<int> existingAyahIds;

  /// ينشئ نافذة حوار إضافة آية إلى الرابط.
  const AddVerseToLinkDialog({
    super.key,
    required this.linkId,
    this.existingAyahIds = const [],
  });

  /// يعرض نافذة حوار اختيار الآية وإضافتها إلى الرابط.
  static Future<bool?> show(
    BuildContext context, {
    required String linkId,
    List<int> existingAyahIds = const [],
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AddVerseToLinkDialog(
        linkId: linkId,
        existingAyahIds: existingAyahIds,
      ),
    );
  }

  /// ينشئ حالة نافذة حوار إضافة الآية.
  @override
  State<AddVerseToLinkDialog> createState() => _AddVerseToLinkDialogState();
}

/// الحالة الداخلية لنافذة إضافة آية إلى رابط الآيات.
class _AddVerseToLinkDialogState extends State<AddVerseToLinkDialog> {
  late int _selectedSurahNumber;
  late int _selectedAyahNumber;
  final TextEditingController _noteController = TextEditingController();
  bool _isAdding = false;

  /// يهيئ السورة والآية الافتراضية عند فتح النافذة.
  @override
  void initState() {
    super.initState();
    _selectedSurahNumber = 1;
    _selectedAyahNumber = 1;
  }

  /// يحرر موارد متحكم حقل الملاحظة عند إغلاق النافذة.
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// يعيد بيانات السورة المختارة حالياً.
  Surah get _currentSurah =>
      QuranRepository.instance.getSurah(_selectedSurahNumber);

  /// يعيد بيانات الآية المختارة حالياً.
  Ayah? get _currentAyah => QuranRepository.instance.getAyah(
    _selectedSurahNumber,
    _selectedAyahNumber,
  );

  /// يتحقق مما إذا كانت الآية المختارة مضافة مسبقاً في الرابط.
  bool get _isAlreadyAdded {
    final ayah = _currentAyah;
    if (ayah == null) return false;
    return widget.existingAyahIds.contains(ayah.id);
  }

  /// يحفظ الآية المختارة وملاحظتها في الرابط ثم يغلق النافذة.
  Future<void> _submit() async {
    final ayah = _currentAyah;
    if (ayah == null || _isAlreadyAdded) return;

    setState(() => _isAdding = true);
    try {
      final repo = AyahLinkRepository();
      final note = _noteController.text.trim();
      await repo.addVerseToLink(
        widget.linkId,
        ayahId: ayah.id,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.ayahNumber,
        page: ayah.page,
        note: note.isEmpty ? null : note,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  /// يبني واجهة نافذة اختيار السورة والآية ومعاينة النص القرآني.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahs = QuranRepository.instance.surahs;
    final ayah = _currentAyah;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: AlertDialog(
        backgroundColor: AppColors.background(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.bookmark_add_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.addVerse,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Surah & Ayah Pickers
              Row(
                children: [
                  // Surah dropdown
                  Expanded(
                    flex: 3,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.isArabic ? 'السورة' : 'Surah',
                        filled: true,
                        fillColor: AppColors.surface(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.border(context),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedSurahNumber,
                          isExpanded: true,
                          items: surahs.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.number,
                              child: Text(
                                '${s.number}. ${s.name}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (newSurah) {
                            if (newSurah != null) {
                              setState(() {
                                _selectedSurahNumber = newSurah;
                                _selectedAyahNumber = 1;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Ayah Number dropdown
                  Expanded(
                    flex: 2,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.isArabic ? 'الآية' : 'Verse',
                        filled: true,
                        fillColor: AppColors.surface(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.border(context),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedAyahNumber,
                          isExpanded: true,
                          items:
                              List.generate(
                                _currentSurah.ayahCount,
                                (i) => i + 1,
                              ).map((n) {
                                return DropdownMenuItem<int>(
                                  value: n,
                                  child: Text(
                                    l10n.isArabic
                                        ? ArabicSearchNormalizer.toArabicDigits(n)
                                        : '$n',
                                  ),
                                );
                              }).toList(),
                          onChanged: (n) {
                            if (n != null) {
                              setState(() => _selectedAyahNumber = n);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Verse Preview
              if (ayah != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '﴿ ${ayah.text} ﴾',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 15,
                          height: 1.8,
                          color: isDark
                              ? AppColors.nightQuranText
                              : AppColors.dayQuranText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.surahAyahPageReference(
                          _currentSurah.name,
                          l10n.isArabic
                              ? ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)
                              : ayah.ayahNumber,
                          l10n.isArabic
                              ? ArabicSearchNormalizer.toArabicDigits(ayah.page)
                              : ayah.page,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.nightSubtitle
                              : AppColors.daySubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isAlreadyAdded) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.isArabic
                        ? 'هذه الآية مضافة بالفعل لهذا الرابط'
                        : 'This verse is already added to this link',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 14),
              ],

              // Note field
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.isArabic
                      ? 'ملاحظتك على هذه الآية في هذا الرابط (اختيارية)'
                      : 'Your note on this verse (optional)',
                  hintText: l10n.isArabic
                      ? 'سجل ما لفت نظرك في ربط هذه الآية...'
                      : 'Record your thoughts on linking this verse...',
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: (_isAlreadyAdded || _isAdding) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isAdding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.isArabic ? 'إضافة إلى الرابط' : 'Add to Link',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
