import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../backup/backup_screen.dart';
import '../reminders/reminders_screen.dart';
import 'user_settings_model.dart';

/// شاشة الإعدادات لإدارة المظهر ونوع وحجم خط المصحف واللغة وإعادة تعيين البيانات.
///
/// Settings screen for managing appearance, Quran font scale, language, and data reset.
class SettingsScreen extends StatelessWidget {
  /// ينشئ شاشة الإعدادات.
  const SettingsScreen({super.key});

  /// يبني واجهة شاشة الإعدادات مقسمة إلى بطاقات منظمة.
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.settings,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final settings = UserDataStore.instance.settings;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. المظهر (Appearance)
                _buildSectionHeader(context, l10n.appearance),
                _buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.themeMode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: isDark ? 0.22 : 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _getActiveThemeLabel(
                                  settings.themeMode,
                                  isDark,
                                  context.currentLanguage == AppLanguage.arabic,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildThemeOptionButton(
                                context: context,
                                mode: ThemeMode.light,
                                currentMode: settings.themeMode,
                                label: l10n.light,
                                icon: Icons.light_mode_rounded,
                                isDark: isDark,
                                onSelect: () {
                                  UserDataStore.instance.updateSettings(
                                    settings.copyWith(
                                      themeMode: ThemeMode.light,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOptionButton(
                                context: context,
                                mode: ThemeMode.dark,
                                currentMode: settings.themeMode,
                                label: l10n.dark,
                                icon: Icons.dark_mode_rounded,
                                isDark: isDark,
                                onSelect: () {
                                  UserDataStore.instance.updateSettings(
                                    settings.copyWith(
                                      themeMode: ThemeMode.dark,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOptionButton(
                                context: context,
                                mode: ThemeMode.system,
                                currentMode: settings.themeMode,
                                label: context.currentLanguage ==
                                        AppLanguage.arabic
                                    ? 'تلقائي'
                                    : 'System',
                                icon: Icons.brightness_auto_rounded,
                                isDark: isDark,
                                onSelect: () {
                                  UserDataStore.instance.updateSettings(
                                    settings.copyWith(
                                      themeMode: ThemeMode.system,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getThemeExplanation(
                                  settings.themeMode,
                                  isDark,
                                  context.currentLanguage == AppLanguage.arabic,
                                ),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.5,
                                  color: isDark
                                      ? AppColors.nightSubtitle
                                      : AppColors.daySubtitle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 2. الخط والقراءة (Typography & Reading)
                _buildSectionHeader(context, l10n.typographyAndReading),
                _buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.font_download_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.quranFontFamily,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final fontOpt in QuranFontFamilyOption.values) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                UserDataStore.instance.setQuranFontFamily(
                                  fontOpt,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: settings.quranFontFamily == fontOpt
                                      ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(
                                              alpha: isDark ? 0.22 : 0.10,
                                            )
                                      : (isDark
                                            ? AppColors.darkSurface
                                            : AppColors.lightBackground),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: settings.quranFontFamily == fontOpt
                                        ? Theme.of(context).colorScheme.primary
                                        : (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder),
                                    width: settings.quranFontFamily == fontOpt
                                        ? 1.4
                                        : 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      settings.quranFontFamily == fontOpt
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 20,
                                      color: settings.quranFontFamily == fontOpt
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : (isDark
                                                ? AppColors.nightSubtitle
                                                : AppColors.daySubtitle),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fontOpt.getLabel(
                                              context.currentLanguage ==
                                                  AppLanguage.arabic,
                                            ),
                                            style: TextStyle(
                                              fontWeight:
                                                  settings.quranFontFamily ==
                                                      fontOpt
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            fontOpt.getSubtitle(
                                              context.currentLanguage ==
                                                  AppLanguage.arabic,
                                            ),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark
                                                  ? AppColors.nightSubtitle
                                                  : AppColors.daySubtitle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.format_size_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.fontSize,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              l10n.fontSizePoints(
                                context.currentLanguage == AppLanguage.arabic
                                    ? ArabicSearchNormalizer.toArabicDigits(
                                        settings.quranFontSize.round(),
                                      )
                                    : settings.quranFontSize.round(),
                              ),
                              style: TextStyle(
                                fontFamily: context.currentLanguage == AppLanguage.arabic ? 'Amiri' : null,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: settings.quranFontSize,
                          min: UserSettings.minQuranFontSize,
                          max: UserSettings.maxQuranFontSize,
                          divisions: 16,
                          label: '${settings.quranFontSize.round()}',
                          onChanged: (newSize) {
                            UserDataStore.instance.setQuranFontSize(newSize);
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.mushafBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ\u00A0\u00A0ۛ فِيهِ\u00A0\u00A0ۛ هُدًى لِّلْمُتَّقِينَ ﴿٢﴾ أُو۟لَٰٓئِكَ عَلَىٰ هُدًى مِّن رَّبِّهِمْ\u00A0\u00A0ۖ وَأُو۟لَٰٓئِكَ هُمُ ٱلْمُفْلِحُونَ ﴿٥﴾',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: settings.quranFontFamilyName,
                              fontSize: settings.quranFontSize,
                              height: 1.85,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.mushafQuranText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: TextButton.icon(
                                  onPressed:
                                      settings.quranFontSize ==
                                          UserSettings.defaultQuranFontSize
                                      ? null
                                      : () => UserDataStore.instance.setQuranFontSize(
                                          UserSettings.defaultQuranFontSize,
                                        ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: Text(
                                    l10n.resetToDefaultWithVal(
                                      context.currentLanguage == AppLanguage.arabic
                                          ? '٢٠'
                                          : '20',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. التطبيق (Application)
                _buildSectionHeader(context, l10n.applicationSection),
                _buildCard(
                  context: context,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.language_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          l10n.languageTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          settings.languageCode == 'ar'
                              ? 'العربية (افتراضي)'
                              : 'English',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: settings.languageCode,
                          underline: const SizedBox(),
                          onChanged: (code) {
                            if (code != null) {
                              UserDataStore.instance.updateSettings(
                                settings.copyWith(languageCode: code),
                              );
                              AppLocalizationScope.of(
                                context,
                              ).onLanguageChanged(AppLanguage.fromCode(code));
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.alarm_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          l10n.reminders,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.dailyRemindersSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_left_rounded, size: 20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RemindersScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. البيانات (Data)
                _buildSectionHeader(context, l10n.dataSection),
                _buildCard(
                  context: context,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.security_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          l10n.backup,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.backupSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_left_rounded, size: 20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BackupScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          l10n.resetData,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        subtitle: Text(
                          l10n.resetDataSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        onTap: () => _confirmResetData(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. حول (About)
                _buildSectionHeader(context, l10n.about),
                _buildCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.appName,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightPrimaryDark,
                                  ),
                                ),
                                Text(
                                  l10n.versionInfo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.nightSubtitle
                                        : AppColors.daySubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.aboutContent,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Text(
                          l10n.sourcesAndCredits,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• نص القرآن الكريم: مشروع تنزيل (Tanzil Project - https://tanzil.net) بالنص العثماني المعتمد برخصة المشاع الإبداعي (CC BY 3.0 — يُمنع التعديل).\n'
                          '• الخطوط القرآنية المفتوحة المصدر: خط شهرزاد الجديد (Scheherazade New)، خط نوتو نسخ (Noto Naskh Arabic)، خط هرمتان (Harmattan)، خط لطيف (Lateef)، وخط أميري القرآني (AmiriQuran & Amiri) برخصة الخطوط المفتوحة SIL Open Font License 1.1.\n'
                          '• معاني كلمات القرآن: الموسوعة القرآنية (Quranpedia.net — نسخة البيانات 2026-10-10) وأمهات المعاجم اللغوية التراثية والمعاصرة (لسان العرب لابن منظور، مقاييس اللغة لابن فارس، التبيان لابن الهائم، تذكرة الأريب لابن الجوزي، مفردات الراغب الأصفهاني، والمعجم الوسيط).\n'
                          '• ترخيص التطبيق: مشروع مفتوح المصدر مرخص تحت رخصة MIT License.\n'
                          '• الخصوصية والأمان المحلي: التطبيق يعمل محلياً بالكامل (100% Offline) دون أي اتصال خارجي أو خوادم أو تتبع أو إعلانات.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            color: isDark
                                ? AppColors.nightSubtitle
                                : AppColors.daySubtitle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            showLicensePage(
                              context: context,
                              applicationName: l10n.appName,
                              applicationVersion: '1.0.0',
                              applicationLegalese:
                                  'Copyright © 2026 Tadbeer Project Contributors (MIT License)\n'
                                  'Quran Text: Tanzil.net (CC BY 3.0)\n'
                                  'Word Meanings Dataset: Quranpedia.net (Version 2026-10-10)\n'
                                  'Fonts: SIL Open Font License 1.1',
                            );
                          },
                          icon: const Icon(Icons.policy_outlined, size: 18),
                          label: Text(l10n.openSourceLicenses),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// يعرض نافذة تأكيد لإعادة تعيين جميع بيانات المستخدم إلى الوضع الافتراضي.
  Future<void> _confirmResetData(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(l10n.resetData),
          ],
        ),
        content: Text(l10n.resetWarningMessage),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, false),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: Text(l10n.confirmReset),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await UserDataStore.instance.resetAllUserData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  /// يبني عنوان قسم فرعي داخل شاشة الإعدادات.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// يبني حاوية بطاقة موحدة المظهر لتجميع عناصر الإعدادات.
  Widget _buildCard({required Widget child, required BuildContext context}) {
    return Material(
      color: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// يبني زراً تفاعلياً لأحد خيارات سمة المظهر (فاتح / داكن / تلقائي).
  Widget _buildThemeOptionButton({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onSelect,
  }) {
    final isSelected = currentMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onSelect();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: isDark ? 0.24 : 0.12)
                  : (isDark
                      ? AppColors.darkSurface
                      : AppColors.lightBackground),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
                width: isSelected ? 1.8 : 0.9,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? primaryColor
                      : (isDark
                          ? AppColors.nightSubtitle
                          : AppColors.daySubtitle),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? primaryColor
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// إرجاع التسمية التوضيحية للسمة المفعّلة حالياً مع توضيح حالة مظهر الجهاز عند تفعيل الوضع التلقائي.
  String _getActiveThemeLabel(
    ThemeMode mode,
    bool isDark,
    bool isArabic,
  ) {
    switch (mode) {
      case ThemeMode.light:
        return isArabic ? 'فاتح' : 'Light';
      case ThemeMode.dark:
        return isArabic ? 'داكن' : 'Dark';
      case ThemeMode.system:
        final resolved = isDark
            ? (isArabic ? 'داكن' : 'Dark')
            : (isArabic ? 'فاتح' : 'Light');
        return isArabic ? 'تلقائي ($resolved)' : 'System ($resolved)';
    }
  }

  /// إرجاع النص الإرشادي التوضيحي لمزايا السمة المحددة.
  String _getThemeExplanation(
    ThemeMode mode,
    bool isDark,
    bool isArabic,
  ) {
    if (mode == ThemeMode.light) {
      return isArabic
          ? 'الوضع النهاري: ألوان ورقية مستوحاة من ورق المصحف الشريف لقراءة نهارية مريحة وواضحة.'
          : 'Light Mode: Calm parchment tones inspired by the Medina Mushaf for comfortable daytime reading.';
    } else if (mode == ThemeMode.dark) {
      return isArabic
          ? 'الوضع الليلي: ألوان داكنة زمردية صُممت خصيصاً لتقليل إجهاد النظر والسطوع أثناء التلاوة والتدبر الطويل.'
          : 'Dark Mode: Subdued, deep forest tones engineered to minimize eye fatigue during extended nighttime reading.';
    } else {
      final current = isDark
          ? (isArabic ? 'داكن' : 'Dark')
          : (isArabic ? 'فاتح' : 'Light');
      return isArabic
          ? 'الوضع التلقائي: يتزامن مظهر التطبيق آلياً مع إعدادات هاتفك (المظهر المفعّل حالياً في جهازك: $current).'
          : 'System Mode: Automatically synchronizes with your device settings (Currently active: $current).';
    }
  }
}
