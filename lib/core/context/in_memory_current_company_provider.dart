import 'current_company_provider.dart';

class InMemoryCurrentCompanyProvider implements CurrentCompanyProvider {
  String? _currentCompanyId;

  @override
  String? get currentCompanyId => _currentCompanyId;

  @override
  String requireCurrentCompanyId() {
    final companyId = _currentCompanyId;

    if (companyId == null || companyId.trim().isEmpty) {
      throw const MissingCompanyContextException();
    }

    return companyId;
  }

  @override
  void setCurrentCompanyId(String companyId) {
    final normalizedCompanyId = companyId.trim();

    if (normalizedCompanyId.isEmpty) {
      throw const MissingCompanyContextException();
    }

    _currentCompanyId = normalizedCompanyId;
  }

  @override
  void clear() {
    _currentCompanyId = null;
  }
}
