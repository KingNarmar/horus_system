import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/utils/result.dart';
import '../entities/route_entity.dart';

abstract class RouteFinancialTermsRepository {
  Future<Result<RouteEntity>> setDefaultFreightRate({
    required String companyId,
    required String routeId,
    required Money rate,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  });
}
