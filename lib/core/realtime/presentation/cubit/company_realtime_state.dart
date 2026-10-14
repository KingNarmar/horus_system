import '../../../errors/failure.dart';
import '../../domain/entities/company_invalidation_resource.dart';

final class CompanyRealtimeState {
  final String companyId;
  final Map<CompanyInvalidationResource, int> revisions;
  final Failure? failure;

  const CompanyRealtimeState({
    required this.companyId,
    this.revisions = const {},
    this.failure,
  });

  int revisionFor(CompanyInvalidationResource resource) =>
      revisions[resource] ?? 0;
}
