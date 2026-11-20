import '../constants/iana_canonical_time_zone_ids.dart';
import '../constants/iana_time_zone_aliases.dart';

/// Canonical IANA 2025c selection and legacy persisted zone resolution.
final class IanaBusinessTimeZoneCatalog {
  const IanaBusinessTimeZoneCatalog();

  bool isSelectable(String zone) =>
      IanaCanonicalTimeZoneIds.values.contains(zone);

  /// Preserve legacy companies, without relying on a device UTC offset.
  String? canonicalForLookup(String raw) {
    var zone = raw.trim();
    if (zone.startsWith('posix/')) {
      zone = zone.substring('posix/'.length);
    } else if (zone.startsWith('right/')) {
      zone = zone.substring('right/'.length);
    }

    for (var depth = 0; depth < 12; depth++) {
      if (isSelectable(zone)) return zone;
      final target = IanaTimeZoneAliases.values[zone];
      if (target == null || target == zone) return null;
      zone = target;
    }
    return null;
  }
}
