enum CompanyDataResource { customers }

final class CompanyDataChange {
  final String companyId;
  final CompanyDataResource resource;

  const CompanyDataChange({required this.companyId, required this.resource});
}
