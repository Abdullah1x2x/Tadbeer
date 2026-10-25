import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../ayah_link_repository.dart';
import '../../quran/data/quran_models.dart';
import '../../quran/data/quran_repository.dart';

/// أوضاع اختيار الآية في نافذة الإضافة لرابط الآيات.
enum _AddVerseMode {
  search, // بحث فوري بنص الآية أو مرجعها
  manual, // تحديد يدوي باختيار السورة ورقم الآية
  saved, // اختيار من المحفوظات أو المميزة
}

/// نافذة سفلية تفاعلية وحديثة لاختيار آية قرآنية وإضافتها مع ملاحظة تدبرية إلى رابط الآيات.
///
/// Interactive bottom sheet modal enabling users to add an Ayah to a Link
/// via smart search, manual picker, or saved bookmarks/highlights.
class AddVerseToLinkDialog extends StatefulWidget {
  /// معرّف رابط الآيات المراد إضافة الآية إليه.
  final String linkId;

  /// قائمة معرّفات الآيات المضافة مسبقاً في هذا الرابط لتفادي التكرار.
  final List<int> existingAyahIds;

  /// ينشئ نافذة إضافة آية إلى الرابط.
  const AddVerseToLinkDialog({
    super.key,
    required this.linkId,
    this.existingAyahIds = const [],
  });

  /// يعرض نافذة اختيار الآية كلوحة سفلية متكيفة مع لوحة المفاتيح.
  static Future<bool?> show(
    BuildContext context, {
    required String linkId,
    List<int> existingAyahIds = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AddVerseToLinkDialog(
        linkId: linkId,
        existingAyahIds: existingAyahIds,
      ),
    );
  }

  @override
  State<AddVerseToLinkDialog> createState() => _AddVerseToLinkDialogState();
}

class _AddVerseToLinkDialogState extends State<AddVerseToLinkDialog> {
  _AddVerseMode _currentMode = _AddVerseMode.search;

  late int _selectedSurahNumber;
  late int _selectedAyahNumber;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ayahNumberController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Ayah> _searchResults = [];
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _selectedSurahNumber = 1;
    _selectedAyahNumber = 1;
    _ayahNumberController.text = '1';
    _searchController.addListener(_onSearchQueryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    _ayahNumberController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// ينفذ البحث القرآني الفوري عند تغير نص البحث.
  void _onSearchQueryChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    final results = QuranRepository.instance.searchAyahs(query, limit: 15);
    if (mounted) {
      setState(() {
        _searchResults = results;
        if (results.length == 1) {
          _selectAyah(results.first, updateSearchText: false);
        }
      });
    }
  }

  /// يعيد بيانات السورة المختارة حالياً.
  Surah get _currentSurah =>
      QuranRepository.instance.getSurah(_selectedSurahNumber);

  /// يعيد بيانات الآية المختارة حالياً.
  Ayah? get _currentAyah => QuranRepository.instance.getAyah(
        _selectedSurahNumber,
        _selectedAyahNumber,
      );

  /// يتحقق مما إذا كانت الآية المختارة مضافة مسبقاً في هذا الرابط.
  bool get _isAlreadyAdded {
    final ayah = _currentAyah;
    if (ayah == null) return false;
    return widget.existingAyahIds.contains(ayah.id);
  }

  /// يحدد آية معينة ويحدث حقول العرض.
  void _selectAyah(Ayah ayah, {bool updateSearchText = false}) {
    setState(() {
      _selectedSurahNumber = ayah.surahNumber;
      _selectedAyahNumber = ayah.ayahNumber;
      _ayahNumberController.text = '${ayah.ayahNumber}';
      if (updateSearchText) {
        final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
        _searchController.removeListener(_onSearchQueryChanged);
        _searchController.text = '${surah.name} ${ayah.ayahNumber}';
        _searchController.addListener(_onSearchQueryChanged);
        _searchResults = [];
      }
    });
  }

  /// يفتح نافذة سريعة للبحث واختيار السورة من بين ١١٤ سورة.
  Future<void> _showSurahPickerModal() async {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahs = QuranRepository.instance.surahs;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerCtx) {
        String filter = '';
        return StatefulBuilder(
          builder: (ctx, setPickerState) {
            final filteredSurahs = filter.isEmpty
                ? surahs
                : surahs.where((s) {
                    final normFilter = ArabicSearchNormalizer.normalize(filter);
                    final normName = ArabicSearchNormalizer.normalize(s.name);
                    final numberStr = '${s.number}';
                    return normName.contains(normFilter) || numberStr.contains(filter);
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.comsilkLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: l10n.isArabic
                              ? 'ابحث باسم السورة أو رقمها...'
                              : 'Search surah name or number...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: AppColors.surface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border(context)),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onChanged: (val) => setPickerState(() => filter = val),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredSurahs.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: AppColors.border(context).withValues(alpha: 0.4),
                        ),
                        itemBuilder: (_, idx) {
                          final s = filteredSurahs[idx];
                          final isSelected = s.number == _selectedSurahNumber;
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : (isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05)),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                l10n.isArabic
                                    ? ArabicSearchNormalizer.toArabicDigits(s.number)
                                    : '${s.number}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                            ),
                            title: Text(
                              l10n.surahTitle(s.name),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${s.isMeccan ? l10n.meccan : l10n.medinan} · ${l10n.ayahCount(s.ayahCount)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded,
                                    color: Theme.of(context).colorScheme.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedSurahNumber = s.number;
                                _selectedAyahNumber = 1;
                                _ayahNumberController.text = '1';
                              });
                              Navigator.pop(pickerCtx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// يحفظ الآية المختارة وملاحظتها التدبرية في الرابط ويغلق النافذة.
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ayah = _currentAyah;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.comsilkLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. مقبض السحب ورأس النافذة
                _buildHeader(context, l10n, primaryColor),

                // 2. محدد طريقة الاختيار (بحث فوري / يدوي / محفوظاتي)
                _buildModeSegmentedControl(context, l10n, isDark, primaryColor),

                // 3. المحتوى المتغير حسب الوضع المختار
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentMode == _AddVerseMode.search)
                          _buildSearchSection(context, l10n, isDark, primaryColor)
                        else if (_currentMode == _AddVerseMode.manual)
                          _buildManualSection(context, l10n, isDark, primaryColor)
                        else
                          _buildSavedSection(context, l10n, isDark, primaryColor),

                        const SizedBox(height: 12),

                        // 4. بطاقة معاينة الآية المختارة
                        if (ayah != null)
                          _buildSelectedAyahCard(context, ayah, l10n, isDark, primaryColor),

                        const SizedBox(height: 14),

                        // 5. حقل الملاحظة التدبرية
                        _buildNoteField(context, l10n),
                      ],
                    ),
                  ),
                ),

                // 6. شريط أزرار الإجراءات (إلغاء / إضافة إلى الرابط)
                _buildBottomActionBar(context, l10n, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings l10n, Color primaryColor) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bookmark_add_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.isArabic ? 'إضافة آية إلى الرابط' : 'Add Verse to Link',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                tooltip: l10n.close,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildModeSegmentedControl(
    BuildContext context,
    AppStrings l10n,
    bool isDark,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _buildTabButton(
              title: l10n.isArabic ? 'بحث فوري' : 'Quick Search',
              icon: Icons.search_rounded,
              mode: _AddVerseMode.search,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
            _buildTabButton(
              title: l10n.isArabic ? 'تحديد يدوي' : 'Manual Picker',
              icon: Icons.tune_rounded,
              mode: _AddVerseMode.manual,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
            _buildTabButton(
              title: l10n.isArabic ? 'محفوظاتي' : 'My Saved',
              icon: Icons.bookmarks_outlined,
              mode: _AddVerseMode.saved,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required _AddVerseMode mode,
    required Color primaryColor,
    required bool isDark,
  }) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? primaryColor.withValues(alpha: 0.25) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? primaryColor : Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    AppStrings l10n,
    bool isDark,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.isArabic
                ? 'اكتب اسم السورة ورقم الآية (مثل: البقرة 255) أو نص الآية...'
                : 'Type surah and verse (e.g. Baqarah 255) or text...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.nightSubtitle : AppColors.lightTextSecondary,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _searchResults.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: AppColors.border(context).withValues(alpha: 0.5),
              ),
              itemBuilder: (_, idx) {
                final ayahItem = _searchResults[idx];
                final isSelected = ayahItem.surahNumber == _selectedSurahNumber &&
                    ayahItem.ayahNumber == _selectedAyahNumber;
                final isAlready = widget.existingAyahIds.contains(ayahItem.id);
                final surahName =
                    QuranRepository.instance.getSurah(ayahItem.surahNumber).name;

                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$surahName : ${ayahItem.ayahNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isAlready)
                        Text(
                          l10n.isArabic ? '(مضافة بالفعل)' : '(Already added)',
                          style: const TextStyle(fontSize: 10.5, color: Colors.orange),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    ayahItem.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 13),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: primaryColor, size: 18)
                      : null,
                  onTap: () => _selectAyah(ayahItem, updateSearchText: false),
                );
              },
            ),
          ),
        ] else if (_searchController.text.trim().isEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildQuickChip('البقرة 255 (آية الكرسي)', 2, 255),
              _buildQuickChip('الكهف 10', 18, 10),
              _buildQuickChip('الإخلاص 1', 112, 1),
              _buildQuickChip('الفاتحة 1', 1, 1),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickChip(String label, int surah, int ayah) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        final target = QuranRepository.instance.getAyah(surah, ayah);
        if (target != null) {
          _selectAyah(target, updateSearchText: true);
        }
      },
    );
  }

  Widget _buildManualSection(
    BuildContext context,
    AppStrings l10n,
    bool isDark,
    Color primaryColor,
  ) {
    final surah = _currentSurah;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // زر اختيار السورة
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: _showSurahPickerModal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.isArabic
                                  ? 'السورة (انقر للاختيار)'
                                  : 'Surah (tap to pick)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? AppColors.nightSubtitle
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              '${surah.number}. ${l10n.surahTitle(surah.name)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // حقل رقم الآية مع أزرار الزيادة والنقصان
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.isArabic
                          ? 'رقم الآية (1-${surah.ayahCount})'
                          : 'Verse (1-${surah.ayahCount})',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.nightSubtitle
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 20),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: _selectedAyahNumber > 1
                              ? () {
                                  setState(() {
                                    _selectedAyahNumber--;
                                    _ayahNumberController.text =
                                        '$_selectedAyahNumber';
                                  });
                                }
                              : null,
                        ),
                        SizedBox(
                          width: 44,
                          child: TextField(
                            controller: _ayahNumberController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(
                                  ArabicSearchNormalizer.toEnglishDigits(val));
                              if (parsed != null &&
                                  parsed >= 1 &&
                                  parsed <= surah.ayahCount) {
                                setState(() => _selectedAyahNumber = parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 20),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: _selectedAyahNumber < surah.ayahCount
                              ? () {
                                  setState(() {
                                    _selectedAyahNumber++;
                                    _ayahNumberController.text =
                                        '$_selectedAyahNumber';
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavedSection(
    BuildContext context,
    AppStrings l10n,
    bool isDark,
    Color primaryColor,
  ) {
    final bookmarks = UserDataStore.instance.bookmarks;
    final highlights = UserDataStore.instance.highlights;

    final savedAyahs = <Ayah>[];
    final seenKeys = <String>{};

    for (final b in bookmarks) {
      final key = '${b.surahNumber}:${b.ayahNumber}';
      if (seenKeys.add(key)) {
        final a = QuranRepository.instance.getAyah(b.surahNumber, b.ayahNumber);
        if (a != null) savedAyahs.add(a);
      }
    }
    for (final h in highlights) {
      final key = '${h.surahNumber}:${h.ayahNumber}';
      if (seenKeys.add(key)) {
        final a = QuranRepository.instance.getAyah(h.surahNumber, h.ayahNumber);
        if (a != null) savedAyahs.add(a);
      }
    }

    if (savedAyahs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          children: [
            Icon(Icons.bookmarks_outlined,
                size: 36, color: Colors.grey.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(
              l10n.isArabic
                  ? 'لا توجد آيات محفوظة أو مميزة بعد'
                  : 'No saved or highlighted verses yet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.isArabic
                  ? 'يمكنك حفظ الآيات أو تمييزها أثناء قراءة المصحف لتظهر هنا مباشرة.'
                  : 'Bookmark or highlight verses while reading to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color:
                    isDark ? AppColors.nightSubtitle : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: savedAyahs.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AppColors.border(context).withValues(alpha: 0.5),
        ),
        itemBuilder: (_, idx) {
          final a = savedAyahs[idx];
          final isSelected = a.surahNumber == _selectedSurahNumber &&
              a.ayahNumber == _selectedAyahNumber;
          final isAlready = widget.existingAyahIds.contains(a.id);
          final surahName =
              QuranRepository.instance.getSurah(a.surahNumber).name;

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Row(
              children: [
                Text(
                  '$surahName · آية ${a.ayahNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (isAlready) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.isArabic ? '(مضافة بالفعل)' : '(Already added)',
                    style: const TextStyle(fontSize: 10.5, color: Colors.orange),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              a.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 13),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: primaryColor, size: 18)
                : null,
            onTap: () => _selectAyah(a, updateSearchText: true),
          );
        },
      ),
    );
  }

  Widget _buildSelectedAyahCard(
    BuildContext context,
    Ayah ayah,
    AppStrings l10n,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAlreadyAdded
              ? Colors.orange.withValues(alpha: 0.7)
              : primaryColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.surahAyahPageReference(
                    QuranRepository.instance.getSurah(ayah.surahNumber).name,
                    l10n.isArabic
                        ? ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)
                        : ayah.ayahNumber,
                    l10n.isArabic
                        ? ArabicSearchNormalizer.toArabicDigits(ayah.page)
                        : ayah.page,
                  ),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              if (_isAlreadyAdded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 13, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        l10n.isArabic ? 'مضافة مسبقاً' : 'Already in link',
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '﴿ ${ayah.text} ﴾',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 16,
              height: 1.85,
              color: isDark ? AppColors.nightQuranText : AppColors.dayQuranText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField(BuildContext context, AppStrings l10n) {
    return TextField(
      controller: _noteController,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: l10n.isArabic
            ? 'ملاحظتك التدبرية على الآية في هذا الرابط (اختيارية)'
            : 'Your reflection note on this verse (optional)',
        hintText: l10n.isArabic
            ? 'سجل ما لفت نظرك أو الفكرة الرابطة بين هذه الآية وموضوع الرابط...'
            : 'Record your reflection or connection for this verse...',
        hintStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: AppColors.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    AppStrings l10n,
    Color primaryColor,
  ) {
    final canSubmit = !_isAlreadyAdded && !_isAdding && _currentAyah != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canSubmit ? _submit : null,
              icon: _isAdding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_link_rounded, size: 18),
              label: Text(
                l10n.isArabic ? 'إضافة إلى الرابط' : 'Add to Link',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
