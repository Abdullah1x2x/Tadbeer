/// حساب اتجاه القبلة والمسافة إلى الكعبة من موقع القارئ.
///
/// هندسة الدائرة العظمى، فيعمل دون إنترنت وبدقة في أي مكان على الأرض؛ الشاشة
/// تضيف الموقع والبوصلة فقط.
library;

import 'dart:math' as math;

/// موقع الكعبة المشرّفة.
const kaabaLatitude = 21.422487;
const kaabaLongitude = 39.826206;

/// متوسط نصف قطر الأرض بالكيلومترات.
const _earthRadiusKm = 6371.0;

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

/// اتجاه القبلة من [latitude] و[longitude]: درجات من الشمال الحقيقي مع عقارب
/// الساعة (٠ إلى أقل من ٣٦٠).
double qiblaBearing(double latitude, double longitude) {
  final phi = _rad(latitude);
  final phiK = _rad(kaabaLatitude);
  final dLambda = _rad(kaabaLongitude - longitude);
  final y = math.sin(dLambda);
  final x = math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(dLambda);
  return (_deg(math.atan2(y, x)) + 360) % 360;
}

/// المسافة إلى الكعبة بالكيلومترات على سطح الأرض.
double distanceToKaabaKm(double latitude, double longitude) {
  final phi1 = _rad(latitude);
  final phi2 = _rad(kaabaLatitude);
  final dPhi = phi2 - phi1;
  final dLambda = _rad(kaabaLongitude - longitude);
  final a =
      math.pow(math.sin(dPhi / 2), 2) +
      math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
}

/// الدوران من [heading] إلى [bearing] بين -180 و180: موجب يميناً، وسالب يساراً.
double turnTo(double bearing, double heading) =>
    ((bearing - heading + 540) % 360) - 180;
