/// موقع القارئ لحساب القبلة: من GPS دون إنترنت، مع حفظ آخر موقع.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../data/storage/user_data_store.dart';

/// نتيجة محاولة تحديد الموقع.
sealed class QiblaFix {
  const QiblaFix();
}

/// موقع معروف.
final class QiblaLocated extends QiblaFix {
  final double latitude;
  final double longitude;

  /// هل هذا آخر موقع محفوظ، لا موقع جديد.
  final bool saved;

  const QiblaLocated(this.latitude, this.longitude, {this.saved = false});
}

/// خدمة الموقع متوقفة في الجهاز.
final class QiblaLocationOff extends QiblaFix {
  const QiblaLocationOff();
}

/// لم يسمح القارئ بالوصول إلى الموقع؛ [forever] إن رفض نهائياً.
final class QiblaPermissionDenied extends QiblaFix {
  final bool forever;

  const QiblaPermissionDenied({required this.forever});
}

/// تعذّر الحصول على الموقع لسبب آخر.
final class QiblaLocationFailed extends QiblaFix {
  const QiblaLocationFailed();
}

/// مصدر الموقع لشاشة القبلة، ويُستبدل في الاختبارات.
class QiblaLocator {
  const QiblaLocator();

  static const _key = 'qibla_location';

  /// آخر موقع محفوظ، لإجابة فورية دون اتصال.
  QiblaLocated? saved() {
    final s = UserDataStore.instance.featureState(_key);
    final lat = (s['lat'] as num?)?.toDouble();
    final lon = (s['lon'] as num?)?.toDouble();
    return lat == null || lon == null
        ? null
        : QiblaLocated(lat, lon, saved: true);
  }

  /// يحدد موقع القارئ، ويطلب الإذن حين يمكنه ذلك.
  /// دقة المدينة تكفي للقبلة، فيُستخدم الموقع التقريبي من GPS دون حاجة للإنترنت.
  Future<QiblaFix> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const QiblaLocationOff();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const QiblaPermissionDenied(forever: false);
      }
      if (permission == LocationPermission.deniedForever) {
        return const QiblaPermissionDenied(forever: true);
      }
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return const QiblaLocationFailed();
      await UserDataStore.instance.saveFeatureState(_key, {
        'lat': position.latitude,
        'lon': position.longitude,
      });
      return QiblaLocated(position.latitude, position.longitude);
    } on Exception {
      return const QiblaLocationFailed();
    }
  }

  /// يفتح مفتاح الموقع في النظام.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// يفتح إعدادات التطبيق، للسماح بإذن رُفض نهائياً.
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
