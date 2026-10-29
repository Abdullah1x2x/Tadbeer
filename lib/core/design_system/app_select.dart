import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../utils/arabic_search_normalizer.dart';
import 'app_icons.dart';

class AppSelectOption<T> {
  final T value;
  final String label;

  /// نمط اسم الخيار، كعرض الخط باسمه نفسه.
  final TextStyle? style;

  const AppSelectOption({required this.value, required this.label, this.style});
}

/// حقل الاختيار الموحّد: يعرض القيمة الحالية ويفتح الخيارات في لوحة سفلية.
///
/// اللوحة تحدد الخيار الحالي وتمرّر إليه، ويمكن البحث فيها للقوائم الطويلة.
class AppSelectField<T> extends StatelessWidget {
  /// عنوان اللوحة، واسم الحقل لقارئ الشاشة.
  final String title;
  final List<AppSelectOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  /// يُظهر مربع بحث في اللوحة.
  final bool searchable;
  final String? searchHint;

  /// كبسولة صغيرة لطرف عنصر القائمة بدل حقل كامل.
  final bool compact;

  const AppSelectField({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icon,
    this.searchable = false,
    this.searchHint,
    this.compact = false,
  });

  AppSelectOption<T>? get _current {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final chosen = await showModalBottomSheet<AppSelectOption<T>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SelectSheet<T>(
        title: title,
        options: options,
        value: value,
        searchable: searchable,
        searchHint: searchHint,
      ),
    );
    if (chosen != null && chosen.value != value) {
      HapticFeedback.selectionClick();
      onChanged(chosen.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final current = _current;
    final caret = Container(
      width: compact ? 22 : 26,
      height: compact ? 22 : 26,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(AppIcons.caretDown, size: compact ? 13 : 15, color: primary),
    );
    return Semantics(
      button: true,
      label: title,
      value: current?.label,
      child: Material(
        color: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 20 : 14),
          side: BorderSide(color: AppColors.border(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              compact ? 12 : 12,
              compact ? 6 : 10,
              compact ? 6 : 10,
              compact ? 6 : 10,
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                if (icon != null && !compact) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  fit: compact ? FlexFit.loose : FlexFit.tight,
                  child: Text(
                    current?.label ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (current?.style ?? const TextStyle()).copyWith(
                      fontSize: compact ? 13.5 : 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                caret,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectSheet<T> extends StatefulWidget {
  final String title;
  final List<AppSelectOption<T>> options;
  final T value;
  final bool searchable;
  final String? searchHint;

  const _SelectSheet({
    required this.title,
    required this.options,
    required this.value,
    required this.searchable,
    required this.searchHint,
  });

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
  static const _rowHeight = 54.0;

  String _query = '';
  late final ScrollController _scroll = ScrollController(
    // تفتح على الخيار الحالي، أسفل الأعلى بصفين.
    initialScrollOffset: () {
      final i = widget.options.indexWhere((o) => o.value == widget.value);
      return i <= 2 ? 0.0 : (i - 2) * _rowHeight;
    }(),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// نص المقارنة في البحث: حروف موحّدة وأرقام بنظام واحد، فيجد «2» «٢. البقرة».
  static String _key(String text) => ArabicSearchNormalizer.normalize(
    ArabicSearchNormalizer.convertDigits(text),
  );

  List<AppSelectOption<T>> get _shown {
    final q = _key(_query.trim());
    if (q.isEmpty) return widget.options;
    return [
      for (final o in widget.options)
        if (_key(o.label).contains(q)) o,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final gold = AppColors.accentGold(context);
    final shown = _shown;
    final height = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(AppIcons.magnifyingGlass, size: 20),
                    isDense: true,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                controller: _query.isEmpty ? _scroll : null,
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: shown.length,
                itemExtent: _rowHeight,
                itemBuilder: (context, i) {
                  final option = shown[i];
                  final selected = option.value == widget.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color: selected
                          ? primary.withValues(alpha: 0.09)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: selected
                            ? BorderSide(color: gold.withValues(alpha: 0.6))
                            : BorderSide.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: (option.style ?? const TextStyle())
                                      .copyWith(
                                        fontSize: 15.5,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: selected
                                            ? primary
                                            : AppColors.textPrimary(context),
                                      ),
                                ),
                              ),
                              if (selected)
                                Icon(
                                  AppIcons.checkCircleFill,
                                  size: 22,
                                  color: gold,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
