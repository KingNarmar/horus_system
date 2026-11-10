/// Stable codes used across resource features; never expose raw SQL errors.
abstract final class QuotaFailureCodes {
  static const reached = 'quota_limit_reached';
  static const unavailable = 'quota_entitlement_unavailable';
  static const corrupt = 'quota_projection_invalid';
  static const permissionDenied = 'quota_permission_denied';
}
