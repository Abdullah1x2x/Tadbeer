import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/motion/app_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppMotion Tokens & Accessibility', () {
    test('Motion tokens have correct values', () {
      expect(AppMotion.fast, const Duration(milliseconds: 120));
      expect(AppMotion.normal, const Duration(milliseconds: 200));
      expect(AppMotion.slow, const Duration(milliseconds: 350));
      expect(AppMotion.emphasized, Curves.easeOutCubic);
      expect(AppMotion.standard, Curves.easeInOutCubic);
    });

    testWidgets('shouldAnimate respects MediaQuery.disableAnimations', (
      tester,
    ) async {
      bool? animated;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              animated = AppMotion.shouldAnimate(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(animated, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                animated = AppMotion.shouldAnimate(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(animated, isFalse);
    });
  });

  group('ScaleOnPress Widget Tests', () {
    testWidgets('Scales down on press down and restores on press up', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScaleOnPress(
                pressedScale: 0.95,
                child: GestureDetector(
                  onTap: () => tapped = true,
                  child: Container(
                    key: const Key('target'),
                    width: 100,
                    height: 100,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final animatedScaleFinder = find.byType(AnimatedScale);
      expect(animatedScaleFinder, findsOneWidget);

      AnimatedScale scaleWidget = tester.widget<AnimatedScale>(
        animatedScaleFinder,
      );
      expect(scaleWidget.scale, 1.0);

      // Press down
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('target'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      scaleWidget = tester.widget<AnimatedScale>(animatedScaleFinder);
      expect(scaleWidget.scale, 0.95);

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      scaleWidget = tester.widget<AnimatedScale>(animatedScaleFinder);
      expect(scaleWidget.scale, 1.0);
      expect(tapped, isTrue);
    });

    testWidgets('Does not scale when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScaleOnPress(
                enabled: false,
                pressedScale: 0.95,
                child: Container(
                  key: const Key('disabled_target'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // When disabled, AnimatedScale is avoided completely
      expect(find.byType(AnimatedScale), findsNothing);
      expect(find.byKey(const Key('disabled_target')), findsOneWidget);
    });

    testWidgets('ScaleOnPress cancels scaling on pointer cancel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScaleOnPress(
                pressedScale: 0.95,
                child: Container(
                  key: const Key('cancel_target'),
                  width: 100,
                  height: 100,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('cancel_target'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      AnimatedScale scaleWidget = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(scaleWidget.scale, 0.95);

      await gesture.cancel();
      await tester.pumpAndSettle();

      scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 1.0);
    });
  });

  group('AppMotion.showSmoothDialog', () {
    testWidgets('Opens dialog with smooth transition and dismisses', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppMotion.showSmoothDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('عنوان الحوار'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, 'ok'),
                            child: const Text('موافق'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('فتح'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();

      expect(find.text('عنوان الحوار'), findsOneWidget);
      expect(find.text('موافق'), findsOneWidget);

      await tester.tap(find.text('موافق'));
      await tester.pumpAndSettle();

      expect(find.text('عنوان الحوار'), findsNothing);
    });
  });
}
