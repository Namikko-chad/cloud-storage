import 'package:cloudsync/presentation/secrets/group_icons.dart';
import 'package:cloudsync/presentation/secrets/secret_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every group preset renders to a PNG the core accepts', () async {
    for (final c in groupPresets) {
      for (final p in c.items) {
        final png = await renderGroupIcon(p.icon, p.color);
        expect(png.length, lessThanOrEqualTo(maxIconBytes), reason: p.en);
      }
    }
  });
}
