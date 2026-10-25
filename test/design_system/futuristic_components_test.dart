import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/design_system/design_system.dart';

void main() {
  group('FuturisticBadge Tests', () {
    testWidgets('renders label and custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticBadge(
                label: 'نشط',
                color: AppColors.cyberEmerald,
              ),
            ),
          ),
        ),
      );

      expect(find.text('نشط'), findsOneWidget);
    });

    testWidgets('renders icon and dot when enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticBadge(
                label: 'مباشر',
                icon: Icons.flash_on,
                showDot: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('مباشر'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });
  });

  group('FuturisticButton Tests', () {
    testWidgets('triggers onPressed when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticButton(
                label: 'حفظ التغييرات',
                icon: Icons.check,
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('حفظ التغييرات'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byType(FuturisticButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticButton(
                label: 'تحميل',
                isLoading: true,
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('تحميل'), findsOneWidget);
    });

    testWidgets('renders secondary variant correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticButton.secondary(
                label: 'إلغاء',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('إلغاء'), findsOneWidget);
    });
  });

  group('FuturisticIconButton Tests', () {
    testWidgets('renders icon and responds to taps', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticIconButton(
                icon: Icons.bookmark,
                tooltip: 'إشارة',
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.bookmark), findsOneWidget);

      await tester.tap(find.byType(FuturisticIconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not trigger onPressed when isEnabled is false', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticIconButton(
                icon: Icons.chevron_left,
                tooltip: 'السابق',
                isEnabled: false,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FuturisticIconButton));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  group('FuturisticCard Tests', () {
    testWidgets('renders child content and handles tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticCard(
                accentColor: AppColors.cyberEmerald,
                showTopAccentGlow: true,
                onTap: () {
                  tapped = true;
                },
                child: const Text('بطاقة اختبارية'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('بطاقة اختبارية'), findsOneWidget);

      await tester.tap(find.byType(FuturisticCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
