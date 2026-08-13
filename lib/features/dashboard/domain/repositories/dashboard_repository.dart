import '../../../../core/utils/result.dart';
import '../entities/dashboard_source.dart';

abstract interface class DashboardRepository {
  Future<Result<DashboardSource>> getDashboardSource({
    required String companyId,
  });
}
