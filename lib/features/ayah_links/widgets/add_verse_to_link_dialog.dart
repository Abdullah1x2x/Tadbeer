import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';
import '../data/ayah_link_repository.dart';

/// إضافة آية إلى رابط.
/// حقل بحث واحد يجد الآية بكلماتها أو بالسورة والرقم ("البقرة ٢٥٥")؛ وفارغاً يعرض الآيات المحفوظة والمظلّلة، والاختيار بالسورة والرقم على بعد نقرة. ولا يُختار شيء حتى يختار القارئ آية، ثم تأتي خاطرة اختيارية وزر "أضف إلى الرابط".
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

  /// هل منتقي السورة والرقم مفتوح.
  bool _byNumber = false;
  int _surah = 1;
  int _ayah = 1;
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

  void _choose(Ayah? ayah) => setState(() => _selected = ayah);

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
    if (ayah == null || _isAdded(ayah)) return;
    setState(() => _isAdding = true);
    try {
      final note = _noteController.text.trim();
      await AyahLinkRepository().addVerseToLink(
        widget.linkId,
        ayahId: ayah.id,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.ayahNumber,
        page: ayah.page,
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
    final canAdd = selected != null && !_isAdded(selected) && !_isAdding;

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
                  _Header(title: l10n.addVerseTitle),
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
                    child: FilledButton.icon(
                      onPressed: canAdd ? _submit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: _isAdding
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(AppIcons.link, size: 18),
                      label: Text(l10n.addVerseAction),
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
            onTap: () => _choose(ayah),
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
              onTap: () => _choose(ayah),
            ),
        ],
      ],
    ];
  }

  /// الآية المختارة، وطريقة لتغييرها، والخاطرة الاختيارية.
  List<Widget> _chosen(BuildContext context, AppStrings l10n, Ayah ayah) {
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    final added = _isAdded(ayah);
    final gold = AppColors.accentGold(context);
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
                    l10n.ayahReference(
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
            Text(
              ayah.text,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 17,
                height: 1.9,
              ),
            ),
            if (added) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.warning,
                    size: 16,
                    color: AppColors.statusWarning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.addVerseAlready,
                    style: TextStyle(
                      color: AppColors.statusWarning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (!added)
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
    void pick(int ayah) {
      final value = ayah.clamp(1, surah.ayahCount);
      setState(() => _ayah = value);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: OutlinedButton(
              onPressed: () async {
                final number = await _pickSurah(context, l10n);
                if (number != null) {
                  setState(() {
                    _surah = number;
                    _ayah = 1;
                  });
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
          IconButton(
            tooltip: l10n.decrease,
            onPressed: _ayah > 1 ? () => pick(_ayah - 1) : null,
            icon: const Icon(AppIcons.minusCircle),
          ),
          Text(
            '${l10n.addVerseAyah} ${l10n.digits(_ayah)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            tooltip: l10n.increase,
            onPressed: _ayah < surah.ayahCount ? () => pick(_ayah + 1) : null,
            icon: const Icon(AppIcons.plusCircle),
          ),
          FilledButton.tonal(
            onPressed: () =>
                _choose(QuranRepository.instance.getAyah(_surah, _ayah)),
            child: const Icon(AppIcons.check, size: 18),
          ),
        ],
      ),
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

  const _Header({required this.title});

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
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
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
  final VoidCallback onTap;

  const _AyahTile({
    required this.ayah,
    required this.added,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        ayah.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 15),
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
