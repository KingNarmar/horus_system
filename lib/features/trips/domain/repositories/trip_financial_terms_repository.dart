import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_entity.dart';

abstract class TripFinancialTermsRepository {
  Future<Result<TripEntity>> setFreightRate({
    required String companyId,
    required String tripId,
    required Money agreedFreightRatePerTon,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  });
}
