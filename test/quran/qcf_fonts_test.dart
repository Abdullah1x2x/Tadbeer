import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';

void main() {
  Future<void> send(WidgetTester tester, String type) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.system.name,
        SystemChannels.system.codec.encodeMessage({'type': type}),
        (_) {},
      );

  testWidgets('a loaded page font does not relayout the app', (tester) async {
    var relayouts = 0;
    void count() => relayouts++;
    PaintingBinding.instance.systemFonts.addListener(count);
    addTearDown(() {
      PaintingBinding.instance.systemFonts.removeListener(count);
      SystemChannels.system.setMessageHandler(
        (m) => tester.binding.handleSystemMessage(m as Object),
      );
    });

    await send(tester, 'fontsChange');
    expect(relayouts, 1, reason: 'the engine message relayouts by default');

    QcfFonts.ignoreFontChanges();
    await send(tester, 'fontsChange');
    expect(relayouts, 1);
  });
}
