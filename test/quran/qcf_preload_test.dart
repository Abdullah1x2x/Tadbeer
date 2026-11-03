import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';

void main() {
  test('every page loads once, nearest to the reading page first', () {
    final order = QcfFonts.preloadOrder(300);
    expect(order.length, QcfFonts.pageCount);
    expect(order.toSet().length, QcfFonts.pageCount);
    expect(order.take(5), [300, 301, 299, 302, 298]);
  });

  test('the order stays complete at both ends of the Mushaf', () {
    expect(QcfFonts.preloadOrder(1).take(3), [1, 2, 3]);
    expect(QcfFonts.preloadOrder(604).take(3), [604, 603, 602]);
    expect(QcfFonts.preloadOrder(604).toSet().length, QcfFonts.pageCount);
  });
}
