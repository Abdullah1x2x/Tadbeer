import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../../quran/qcf/qcf_ayah_text.dart';
import '../../quran/qcf/qcf_layout.dart';
import '../../../data/models/ayah_link_model.dart';
import '../data/ayah_link_repository.dart';

/// إضافة آية إلى رابط.
///
/// حقل بحث واحد يجد الآية بكلماتها أو بالسورة والرقم ("البقرة ٢٥٥")؛ وفارغاً
/// يعرض الآيات المحفوظة والمظلّلة، والاختيار بالسورة والرقم على بعد نقرة. ولا
/// يُختار شيء حتى يختار القارئ آية، ثم تأتي خاطرة اختيارية وزر "أضف إلى
/// الرابط".
class AddVerseToLinkDialog extends StatefulWidget {
  final String linkId;

  /// آيات الرابط الحالية، لتجنب تكرارها.
  final List<int> existingAyahIds;

  const AddVerseToLinkDialog({
    super.key,
    required this.linkId,
    this.existingAyahIds = const [],
  });

  /// يعرضها لوحةً سفلية تتكيف مع لوحة المفاتيح.
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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Ayah> _results = const [];

  /// الآية المختارة؛ لا شيء حتى يختار القارئ.
  Ayah? _selected;
  int? _fromAyahNumber;
  int? _toAyahNumber;

  /// الآيات المحددة للتحديد المتعدد.
  final List<Ayah> _selectedMulti = [];

  /// هل منتقي السورة والرقم مفتوح.
  bool _byNumber = false;
  int _surah = 1;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _results = query.isEmpty
          ? const []
          : QuranRepository.instance.searchAyahs(query, limit: 15);
    });
  }

  bool _isAdded(Ayah ayah) => widget.existingAyahIds.contains(ayah.id);

  void _choose(Ayah? ayah) => setState(() {
    _selected = ayah;
    _fromAyahNumber = ayah?.ayahNumber;
    _toAyahNumber = ayah?.ayahNumber;
  });

  void _toggleMulti(Ayah ayah) {
    setState(() {
      final idx = _selectedMulti.indexWhere((a) => a.id == ayah.id);
      if (idx != -1) {
        _selectedMulti.removeAt(idx);
      } else {
        _selectedMulti.add(ayah);
        _selectedMulti.sort((a, b) {
          if (a.surahNumber != b.surahNumber) {
            return a.surahNumber.compareTo(b.surahNumber);
          }
          return a.ayahNumber.compareTo(b.ayahNumber);
        });
      }
    });
  }

  bool _canMergeMulti() {
    if (_selectedMulti.length < 2) return false;
    final first = _selectedMulti.first;
    for (var i = 0; i < _selectedMulti.length; i++) {
      if (_selectedMulti[i].surahNumber != first.surahNumber) return false;
      if (_selectedMulti[i].ayahNumber != first.ayahNumber + i) return false;
    }
    return true;
  }

  Future<void> _submitMulti({bool asMerged = false}) async {
    if (_selectedMulti.isEmpty || _isAdding) return;
    setState(() => _isAdding = true);
    try {
      final style = UserDataStore.instance.settings.mushafStyle;
      if (asMerged && _canMergeMulti()) {
        final first = _selectedMulti.first;
        final last = _selectedMulti.last;
        await AyahLinkRepository().addVerseToLink(
          widget.linkId,
          ayahId: first.id,
          surahNumber: first.surahNumber,
          ayahNumber: first.ayahNumber,
          toAyahNumber: last.ayahNumber,
          page: QcfLayout.instance.pageFor(first, style),
        );
      } else {
        final verses = [
          for (final a in _selectedMulti)
            AyahLinkVerse(
              ayahId: a.id,
              surahNumber: a.surahNumber,
              ayahNumber: a.ayahNumber,
              page: QcfLayout.instance.pageFor(a, style),
              addedAt: DateTime.now(),
            ),
        ];
        await AyahLinkRepository().addVersesToLink(widget.linkId, verses);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  /// الآيات المحفوظة والمظلّلة، كل آية مرة واحدة.
  List<Ayah> get _savedAyahs {
    final repo = QuranRepository.instance;
    final store = UserDataStore.instance;
    final seen = <String>{};
    final out = <Ayah>[];
    for (final (s, a) in [
      for (final b in store.bookmarks) (b.surahNumber, b.ayahNumber),
      for (final h in store.highlights) (h.surahNumber, h.ayahNumber),
    ]) {
      if (!seen.add('$s:$a')) continue;
      final ayah = repo.getAyah(s, a);
      if (ayah != null) out.add(ayah);
    }
    return out;
  }

  Future<void> _submit() async {
    final ayah = _selected;
    if (ayah == null) return;
    final from = _fromAyahNumber ?? ayah.ayahNumber;
    final to = _toAyahNumber ?? ayah.ayahNumber;
    final startAyah = QuranRepository.instance.getAyah(ayah.surahNumber, from) ?? ayah;
    final style = UserDataStore.instance.settings.mushafStyle;
    setState(() => _isAdding = true);
    try {
      final note = _noteController.text.trim();
      await AyahLinkRepository().addVerseToLink(
        widget.linkId,
        ayahId: startAyah.id,
        surahNumber: startAyah.surahNumber,
        ayahNumber: from,
        toAyahNumber: to > from ? to : null,
        page: QcfLayout.instance.pageFor(startAyah, style),
        note: note.isEmpty ? null : note,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selected;
    final canAdd = selected != null && !_isAdding;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      // Material ليظهر أثر النقر على صفوف القائمة.
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    title: l10n.addVerseTitle,
                    selectedCount: _selectedMulti.length,
                    onClearSelection: () => setState(_selectedMulti.clear),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      children: selected == null
                          ? _choosing(context, l10n)
                          : _chosen(context, l10n, selected),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _selectedMulti.isNotEmpty
                        ? (_canMergeMulti()
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton.icon(
                                    onPressed: _isAdding
                                        ? null
                                        : () => _submitMulti(asMerged: true),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    icon: _isAdding
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(AppIcons.link, size: 18),
                                    label: Text(
                                      l10n.mergeVersesInOneCard(_selectedMulti.length),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: _isAdding
                                        ? null
                                        : () => _submitMulti(asMerged: false),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    child: Text(
                                      l10n.addAsSeparateCards,
                                    ),
                                  ),
                                ],
                              )
                            : FilledButton.icon(
                                onPressed: _isAdding
                                    ? null
                                    : () => _submitMulti(asMerged: false),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                icon: _isAdding
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(AppIcons.link, size: 18),
                                label: Text(
                                  l10n.addSelectedVerses(_selectedMulti.length),
                                ),
                              ))
                        : FilledButton.icon(
                            onPressed: canAdd ? _submit : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            icon: _isAdding
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    selected != null && _isAdded(selected)
                                        ? AppIcons.plus
                                        : AppIcons.link,
                                    size: 18,
                                  ),
                            label: Text(
                              selected != null && _isAdded(selected)
                                  ? l10n.addToLinkAgain
                                  : l10n.addVerseAction,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// البحث، والآيات المحفوظة، ومنتقي السورة والرقم.
  List<Widget> _choosing(BuildContext context, AppStrings l10n) {
    final query = _searchController.text.trim();
    final saved = query.isEmpty && !_byNumber ? _savedAyahs : const <Ayah>[];
    return [
      TextField(
        controller: _searchController,
        autofocus: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.addVerseSearchHint,
          prefixIcon: const Icon(AppIcons.magnifyingGlass, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.clearText,
                  icon: const Icon(AppIcons.x, size: 18),
                  onPressed: _searchController.clear,
                ),
        ),
      ),
      const SizedBox(height: 8),
      if (query.isNotEmpty) ...[
        if (_results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.addVerseNoResults,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
        for (final ayah in _results)
          _AyahTile(
            ayah: ayah,
            added: _isAdded(ayah),
            isSelected: _selectedMulti.any((a) => a.id == ayah.id),
            onCheckboxChanged: (_) => _toggleMulti(ayah),
            onTap: () {
              if (_selectedMulti.isNotEmpty) {
                _toggleMulti(ayah);
              } else {
                _choose(ayah);
              }
            },
          ),
      ] else ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _byNumber = !_byNumber),
            icon: Icon(
              _byNumber ? AppIcons.caretUp : AppIcons.listNumbers,
              size: 18,
            ),
            label: Text(l10n.addVersePickBySurah),
          ),
        ),
        if (_byNumber) _numberPicker(context, l10n),
        if (saved.isNotEmpty) ...[
          const SizedBox(height: 4),
          _SectionTitle(l10n.addVerseFromSaved),
          for (final ayah in saved)
            _AyahTile(
              ayah: ayah,
              added: _isAdded(ayah),
              isSelected: _selectedMulti.any((a) => a.id == ayah.id),
              onCheckboxChanged: (_) => _toggleMulti(ayah),
              onTap: () {
                if (_selectedMulti.isNotEmpty) {
                  _toggleMulti(ayah);
                } else {
                  _choose(ayah);
                }
              },
            ),
        ],
      ],
    ];
  }

  /// الآية المختارة، وطريقة لتغييرها، والخاطرة الاختيارية.
  List<Widget> _chosen(BuildContext context, AppStrings l10n, Ayah ayah) {
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    final fromAyahNum = _fromAyahNumber ?? ayah.ayahNumber;
    final toAyahNum = _toAyahNumber ?? ayah.ayahNumber;
    final isRange = fromAyahNum < toAyahNum;
    final added = _isAdded(ayah);
    final gold = AppColors.accentGold(context);
    final isMadinah =
        UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah;

    return [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: added
                ? AppColors.statusWarning
                : gold.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isRange
                        ? l10n.ayahRangeReference(surah.name, l10n.digits(fromAyahNum), l10n.digits(toAyahNum))
                        : l10n.ayahReference(
                            surah.name,
                            l10n.digits(ayah.ayahNumber),
                          ),
                    style: TextStyle(fontWeight: FontWeight.bold, color: gold),
                  ),
                ),
                TextButton(
                  onPressed: () => _choose(null),
                  child: Text(l10n.addVerseChange),
                ),
              ],
            ),
            if (isRange) ...[
              Builder(
                builder: (ctx) {
                  final rangeAyahs = [
                    for (int a = fromAyahNum; a <= toAyahNum; a++)
                      QuranRepository.instance.getAyah(ayah.surahNumber, a),
                  ].whereType<Ayah>().toList();

                  return Column(
                    children: [
                      for (final a in rangeAyahs)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: isMadinah
                              ? QcfAyahText(
                                  ayah: a,
                                  fontSize: 16,
                                  height: 1.8,
                                  color: AppColors.textPrimary(context),
                                  fallback: Text(
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
            ] else ...[
              isMadinah
                  ? QcfAyahText(
                      ayah: ayah,
                      fontSize: 17,
                      height: 1.9,
                      color: AppColors.textPrimary(context),
                      fallback: Text(
                        ayah.text,
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontFamily: UserDataStore.instance.quranFontFamily,
                          fontSize: 17,
                          height: 1.9,
                        ),
                      ),
                    )
                  : Text(
                      ayah.text,
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontFamily: UserDataStore.instance.quranFontFamily,
                        fontSize: 17,
                        height: 1.9,
                      ),
                    ),
            ],
            if (added) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.statusWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.statusWarning.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      AppIcons.warning,
                      size: 16,
                      color: AppColors.statusWarning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.addVerseAlready,
                      style: const TextStyle(
                        color: AppColors.statusWarning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (fromAyahNum > 1)
                  ActionChip(
                    avatar: const Icon(AppIcons.caretUp, size: 16),
                    label: Text(
                      l10n.includePreviousAyah(l10n.digits(fromAyahNum - 1)),
                    ),
                    onPressed: () {
                      setState(() {
                        _fromAyahNumber = fromAyahNum - 1;
                      });
                    },
                  ),
                if (fromAyahNum < ayah.ayahNumber)
                  ActionChip(
                    avatar: const Icon(AppIcons.x, size: 14),
                    label: Text(
                      l10n.excludeAyah(l10n.digits(fromAyahNum)),
                    ),
                    onPressed: () {
                      setState(() {
                        _fromAyahNumber = fromAyahNum + 1;
                      });
                    },
                  ),
                if (toAyahNum < surah.ayahCount)
                  ActionChip(
                    avatar: const Icon(AppIcons.caretDown, size: 16),
                    label: Text(
                      l10n.includeNextAyah(l10n.digits(toAyahNum + 1)),
                    ),
                    onPressed: () {
                      setState(() {
                        _toAyahNumber = toAyahNum + 1;
                      });
                    },
                  ),
                if (toAyahNum > ayah.ayahNumber)
                  ActionChip(
                    avatar: const Icon(AppIcons.x, size: 14),
                    label: Text(
                      l10n.excludeAyah(l10n.digits(toAyahNum)),
                    ),
                    onPressed: () {
                      setState(() {
                        _toAyahNumber = toAyahNum - 1;
                      });
                    },
                  ),
              ],
            ),
            if (ayah.ayahNumber > 1 && !isRange) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                  icon: const Icon(AppIcons.arrowLeft, size: 16),
                  label: Text(
                    l10n.selectPreviousAyahOnly(l10n.digits(ayah.ayahNumber - 1)),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    final prev = QuranRepository.instance.getAyah(
                      ayah.surahNumber,
                      ayah.ayahNumber - 1,
                    );
                    if (prev != null) _choose(prev);
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        l10n.rangeFromLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: fromAyahNum,
                        isDense: true,
                        items: [
                          for (int a = 1; a <= toAyahNum; a++)
                            DropdownMenuItem(
                              value: a,
                              child: Text(l10n.digits(a)),
                            ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _fromAyahNumber = val);
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: toAyahNum,
                        isDense: true,
                        items: [
                          for (int a = fromAyahNum; a <= surah.ayahCount; a++)
                            DropdownMenuItem(
                              value: a,
                              child: Text(l10n.digits(a)),
                            ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _toAyahNumber = val);
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
      TextField(
        controller: _noteController,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(labelText: l10n.addVerseNote),
      ),
    ];
  }

  Widget _numberPicker(BuildContext context, AppStrings l10n) {
    final surah = QuranRepository.instance.getSurah(_surah);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () async {
                final number = await _pickSurah(context, l10n);
                if (number != null && mounted) {
                  setState(() => _surah = number);
                  // فتح منتقي الآيات المرئي تلقائياً بعد اختيار السورة
                  final pickedAyah = await _pickAyahFromSurah(
                    this.context,
                    l10n,
                    number,
                  );
                  if (pickedAyah != null && mounted) {
                    _choose(pickedAyah);
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.addVerseSurah}: ${surah.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(AppIcons.caretDown, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final pickedAyah = await _pickAyahFromSurah(
                context,
                l10n,
                _surah,
              );
              if (pickedAyah != null && mounted) {
                _choose(pickedAyah);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            icon: const Icon(AppIcons.listNumbers, size: 18),
            label: Text(l10n.addVerseAyah),
          ),
        ],
      ),
    );
  }

  /// منتقي مرئي لآيات السورة يعرض رقم الآية مع نصها الكامل لاختيارها بنقرة واحدة.
  Future<Ayah?> _pickAyahFromSurah(
    BuildContext context,
    AppStrings l10n,
    int surahNumber,
  ) {
    final surah = QuranRepository.instance.getSurah(surahNumber);
    final ayahs = List.generate(
      surah.ayahCount,
      (i) => QuranRepository.instance.getAyah(surahNumber, i + 1),
    ).whereType<Ayah>().toList();

    return showModalBottomSheet<Ayah>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.surahTitle(surah.name)} (${l10n.ayahCount(surah.ayahCount)})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.x),
                      tooltip: l10n.close,
                      onPressed: () => Navigator.pop(sheet),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: ayahs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final ayah = ayahs[i];
                    final added = _isAdded(ayah);
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: added
                            ? AppColors.statusWarning.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.primary
                                  .withValues(alpha: 0.1),
                        child: Text(
                          l10n.digits(ayah.ayahNumber),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: added
                                ? AppColors.statusWarning
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        ayah.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: UserDataStore.instance.quranFontFamily,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: added
                          ? Text(
                              l10n.addVerseAlready,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.statusWarning,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.pop(sheet, ayah),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// قائمة السور الـ114 مع بحث؛ يعيد رقم المختارة.
  Future<int?> _pickSurah(BuildContext context, AppStrings l10n) {
    final surahs = QuranRepository.instance.surahs;
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) {
        var filter = '';
        return StatefulBuilder(
          builder: (context, setSheet) {
            final norm = ArabicSearchNormalizer.normalize(filter);
            final shown = filter.isEmpty
                ? surahs
                : surahs
                      .where(
                        (s) =>
                            ArabicSearchNormalizer.normalize(s.name)
                                .contains(norm) ||
                            '${s.number}'.contains(filter),
                      )
                      .toList();
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.addVerseSearchSurah,
                        prefixIcon: const Icon(AppIcons.magnifyingGlass),
                      ),
                      onChanged: (v) => setSheet(() => filter = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final s = shown[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text(
                              l10n.digits(s.number),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          title: Text(l10n.surahTitle(s.name)),
                          subtitle: Text(
                            '${s.isMeccan ? l10n.meccan : l10n.medinan} · ${l10n.ayahCount(s.ayahCount)}',
                          ),
                          selected: s.number == _surah,
                          onTap: () => Navigator.pop(sheet, s.number),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int selectedCount;
  final VoidCallback? onClearSelection;

  const _Header({
    required this.title,
    this.selectedCount = 0,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 8, 4),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedCount > 0
                      ? context.l10n.multiSelectedCount(selectedCount)
                      : title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (selectedCount > 0 && onClearSelection != null)
                TextButton(
                  onPressed: onClearSelection,
                  child: Text(
                    context.l10n.deselect,
                  ),
                ),
              IconButton(
                tooltip: context.l10n.close,
                icon: const Icon(AppIcons.x, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary(context),
      ),
    ),
  );
}

/// آية في قائمة: مرجعها وبداية نصها.
class _AyahTile extends StatelessWidget {
  final Ayah ayah;
  final bool added;
  final bool isSelected;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback onTap;

  const _AyahTile({
    required this.ayah,
    required this.added,
    this.isSelected = false,
    this.onCheckboxChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Checkbox(
        value: isSelected,
        onChanged: onCheckboxChanged,
      ),
      title: Text(
        ayah.text,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: UserDataStore.instance.quranFontFamily,
          fontSize: 16,
          height: 1.6,
        ),
      ),
      subtitle: Text(
        added
            ? '${l10n.ayahReference(surah.name, l10n.digits(ayah.ayahNumber))} · ${l10n.addVerseAlready}'
            : l10n.ayahReference(surah.name, l10n.digits(ayah.ayahNumber)),
        style: TextStyle(
          fontSize: 12,
          color: added
              ? AppColors.statusWarning
              : AppColors.accentGold(context),
        ),
      ),
      trailing: const Icon(AppIcons.caretRight, size: 16),
      onTap: onTap,
    );
  }
}
