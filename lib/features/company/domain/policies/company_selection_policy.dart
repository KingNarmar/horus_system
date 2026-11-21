import '../entities/current_company_context.dart';

/// Chooses only a company present in a fresh, authoritative membership list.
abstract final class CompanySelectionPolicy {
  static String chooseCompanyId({
    required List<CurrentCompanyContext> activeContexts,
    String? preferredCompanyId,
  }) {
    // The caller handles the empty membership list before this policy.
    final preferred = preferredCompanyId?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      for (final context in activeContexts) {
        if (context.companyId == preferred) return context.companyId;
      }
    }
    return activeContexts.first.companyId;
  }
}
