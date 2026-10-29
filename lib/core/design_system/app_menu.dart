import 'package:flutter/material.dart';

import 'app_icons.dart';

/// عنصر موحّد في قوائم «⋮»: أيقونة في دائرة ملونة واسم بجانبها، وبالأحمر لما يحذف.
/// شكل القائمة نفسه من PopupMenuThemeData في الثيم؛ هذا يوحّد ارتفاع العناصر ومسافاتها.
PopupMenuItem<T> appMenuItem<T>({
  T? value,
  VoidCallback? onTap,
  required IconData icon,
  required String label,
  bool destructive = false,
}) {
  return PopupMenuItem<T>(
    value: value,
    onTap: onTap,
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Builder(
      builder: (context) {
        final colour = destructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: colour),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: destructive ? TextStyle(color: colour) : null,
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// زر «⋮» الذي يفتح هذه القوائم، بنفس الشكل في كل مكان.
const appMenuIcon = Icon(AppIcons.dotsThreeVertical, size: 22);
