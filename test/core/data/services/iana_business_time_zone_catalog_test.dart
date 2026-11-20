import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:horus_system/core/data/constants/iana_canonical_time_zone_ids.dart';
import 'package:horus_system/core/data/services/iana_business_time_zone_catalog.dart';

void main() {
  const catalog = IanaBusinessTimeZoneCatalog();

  setUpAll(tz_data.initializeTimeZones);

  test('every selectable IANA 2025c zone is actually resolvable', () {
    expect(IanaCanonicalTimeZoneIds.values.length, 420);
    for (final name in IanaCanonicalTimeZoneIds.values) {
      expect(catalog.isSelectable(name), isTrue);
      expect(() => tz.getLocation(name), returnsNormally, reason: name);
    }
  });

  test('legacy aliases remain convertible but cannot be newly selected', () {
    expect(catalog.isSelectable('Egypt'), isFalse);
    expect(catalog.isSelectable('posix/Egypt'), isFalse);
    expect(catalog.canonicalForLookup('Egypt'), 'Africa/Cairo');
    expect(catalog.canonicalForLookup('posix/Egypt'), 'Africa/Cairo');
    expect(catalog.canonicalForLookup('right/Egypt'), 'Africa/Cairo');
    expect(catalog.canonicalForLookup('US/Eastern'), 'America/New_York');
    expect(catalog.canonicalForLookup('Nonexistent/Zone'), isNull);
  });
}
