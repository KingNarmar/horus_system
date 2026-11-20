import '../constants/iana_canonical_time_zone_ids.dart';

/// Pure company-business selection policy shared by Domain, Data and SQL.
/// Legacy identifiers remain readable but cannot be selected anew.
final class BusinessTimeZoneSelectionPolicy {
  const BusinessTimeZoneSelectionPolicy();

  bool isSelectable(String zoneId) =>
      IanaCanonicalTimeZoneIds.values.contains(zoneId);
}
