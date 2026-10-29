import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_icons.dart';
import 'app_tokens.dart';

/// حقل البحث أعلى القوائم، بزر يمسح النص.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;

  final String hintText;

  /// تلميح زر المسح بلغة الواجهة.
  final String clearTooltip;

  /// يُستدعى بالنص الجديد، وبنص فارغ عند المسح.
  final ValueChanged<String> onChanged;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.comsilk,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: AppColors.border(context),
          width: AppTokens.borderHairline,
        ),
        boxShadow: AppTokens.cardShadow(isDark: isDark),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 14,
              color: isDark ? AppColors.nightSubtitle : AppColors.daySubtitle,
            ),
            prefixIcon: Icon(
              AppIcons.magnifyingGlass,
              color: AppColors.cyberEmerald,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    tooltip: clearTooltip,
                    icon: const Icon(AppIcons.x, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
