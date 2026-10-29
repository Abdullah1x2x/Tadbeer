import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/ornaments.dart';
import '../../data/storage/user_data_store.dart';

/// يسأل القارئ عن اسمه عند أول فتح، لتناديه به التذكيرات.
/// الاسم اختياري، ويبقى على الجهاز، ويُغيّر من الإعدادات.
class NameScreen extends StatefulWidget {
  /// الشاشة التالية.
  final WidgetBuilder next;

  const NameScreen({super.key, required this.next});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _name = TextEditingController(
    text: UserDataStore.instance.settings.userName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _go({required bool keep}) async {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    if (keep) await UserDataStore.instance.setUserName(_name.text);
    navigator.pushReplacement(MaterialPageRoute(builder: widget.next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        body: PatternBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        AppIcons.handHeart,
                        size: 48,
                        color: AppColors.accentGold(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.askNameTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: OrnamentDivider(width: 120, starSize: 5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.askNameHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _name,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        maxLength: 30,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: l10n.askNameField,
                          counterText: '',
                        ),
                        onSubmitted: (_) => _go(keep: true),
                      ),
                      const SizedBox(height: 20),
                      ListenableBuilder(
                        listenable: _name,
                        builder: (context, _) => FilledButton(
                          onPressed: _name.text.trim().isEmpty
                              ? null
                              : () => _go(keep: true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(l10n.continueLabel),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _go(keep: false),
                        child: Text(l10n.skipStep),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
