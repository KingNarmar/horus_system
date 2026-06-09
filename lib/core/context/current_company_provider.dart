abstract class CurrentCompanyProvider {
  String? get currentCompanyId;

  String requireCurrentCompanyId();

  void setCurrentCompanyId(String companyId);

  void clear();
}

class MissingCompanyContextException implements Exception {
  final String message;

  const MissingCompanyContextException({
    this.message = 'Current company context is required.',
  });

  @override
  String toString() => message;
}
