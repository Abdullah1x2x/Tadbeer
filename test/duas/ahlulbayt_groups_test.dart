import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/duas/data/ahlulbayt_duas_repository.dart';

void main() {
  test('every dua sits in exactly one filter group', () {
    for (final dua in AhlulbaytDuasRepository.defaultDuas) {
      final groups = [
        for (final MapEntry(:key, :value) in ahlulbaytDuaGroups.entries)
          if (value.any((k) => dua.category.contains(k))) key,
      ];
      expect(groups, hasLength(1), reason: '${dua.title}: $groups');
    }
  });
}
