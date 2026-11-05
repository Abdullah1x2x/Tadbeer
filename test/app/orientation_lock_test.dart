import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/bootstrap.dart';

void main() {
  /// The orientations the app asked for, or null if it asked for none.
  Future<List<dynamic>?> requested(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.display.size = screen;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.display.reset);
    List<dynamic>? asked;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          asked = call.arguments as List<dynamic>;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    lockPhonesToPortrait();
    await tester.pump();
    return asked;
  }

  testWidgets('a phone stays upright', (tester) async {
    expect(await requested(tester, const Size(412, 915)), [
      'DeviceOrientation.portraitUp',
    ]);
  });

  testWidgets('a phone held sideways at launch is still a phone', (
    tester,
  ) async {
    expect(await requested(tester, const Size(915, 412)), [
      'DeviceOrientation.portraitUp',
    ]);
  });

  testWidgets('a tablet keeps rotating', (tester) async {
    expect(await requested(tester, const Size(800, 1280)), isNull);
  });
}
