import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/storage/user_data_store.dart';
import '../../settings/user_settings_model.dart';

/// تكبير خط النص المتدفق: زرّا تصغير وتكبير بينهما النسبة الحالية.
///
/// The flowing text sizes itself to the screen; this enlarges it from there
/// in steps of 10%, up to [UserSettings.maxFlowingTextScale].
class TextScaleControl extends StatelessWidget {
  /// ينشئ عنصر تكبير الخط.
  const TextScaleControl({super.key});

  static const _step = 0.1;

  void _set(double scale) {
    HapticFeedback.selectionClick();
    final store = UserDataStore.instance;
    // Rounded to whole steps, so repeated taps never drift.
    final rounded = (scale * 10).round() / 10;
    store.updateSettings(store.settings.copyWith(flowingTextScale: rounded));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) {
        final scale = UserDataStore.instance.settings.flowingTextScale;
        final canShrink = scale > UserSettings.minFlowingTextScale + 0.01;
        final canGrow = scale < UserSettings.maxFlowingTextScale - 0.01;
        Widget button(IconData icon, String tip, VoidCallback? onTap) =>
            IconButton.filledTonal(
              tooltip: tip,
              onPressed: onTap,
              icon: Icon(icon, size: 18),
            );
        return Row(
          children: [
            Icon(AppIcons.textAa, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.enlargeText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            button(
              AppIcons.minus,
              l10n.textSmaller,
              canShrink ? () => _set(scale - _step) : null,
            ),
            SizedBox(
              width: 56,
              child: Text(
                l10n.percent((scale * 100).round()),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            button(
              AppIcons.plus,
              l10n.textLarger,
              canGrow ? () => _set(scale + _step) : null,
            ),
          ],
        );
      },
    );
  }
}
