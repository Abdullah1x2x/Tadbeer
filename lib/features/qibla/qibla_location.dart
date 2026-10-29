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

  /// Whether this is the last saved location rather than a fresh one.
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

/// The location source behind the Qibla screen, replaceable in tests.
class QiblaLocator {
  const QiblaLocator();

  static const _key = 'qibla_location';

  /// The last location saved from a fix, for an instant answer offline.
  QiblaLocated? saved() {
    final s = UserDataStore.instance.featureState(_key);
    final lat = (s['lat'] as num?)?.toDouble();
    final lon = (s['lon'] as num?)?.toDouble();
    return lat == null || lon == null
        ? null
        : QiblaLocated(lat, lon, saved: true);
  }

  /// Finds the reader's location, asking for permission when it may.
  ///
  /// A city-level fix is enough for the Qibla, so the coarse location is
  /// used; it comes from GPS or the network without needing the internet.
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

  /// Opens the system's location switch.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens the app's settings, to allow a permission refused for good.
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
