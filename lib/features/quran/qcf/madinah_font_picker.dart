import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/storage/user_data_store.dart';

/// يختار خط صفحات مصحف المدينة.
class MadinahFontPicker extends StatelessWidget {
  const MadinahFontPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<MadinahFont>(
      segments: [
        ButtonSegment(
          value: MadinahFont.kingFahd,
          label: Text(l10n.madinahFontKingFahd),
        ),
        ButtonSegment(
          value: MadinahFont.digitalKhatt,
          label: Text(l10n.madinahFontDigitalKhatt),
        ),
      ],
      selected: {UserDataStore.instance.settings.madinahFont},
      showSelectedIcon: false,
      onSelectionChanged: (v) => UserDataStore.instance.setMadinahFont(v.first),
    );
  }
}
