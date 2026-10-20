import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_financial_terms_repository.dart';
import '../datasources/trip_financial_terms_remote_data_source.dart';
import '../mappers/trip_mapper.dart';
import 'trip_repository_failure_mapper.dart';

final class TripFinancialTermsRepositoryImpl
    implements TripFinancialTermsRepository {
  final TripFinancialTermsRemoteDataSource _remoteDataSource;
  final TripRepositoryFailureMapper _failureMapper;
  final MoneyDecimalCodec _codec;

  const TripFinancialTermsRepositoryImpl(
    this._remoteDataSource, {
    TripRepositoryFailureMapper failureMapper =
        const TripRepositoryFailureMapper(),
    MoneyDecimalCodec codec = const MoneyDecimalCodec(),
  }) : _failureMapper = failureMapper,
       _codec = codec;

  @override
  Future<Result<TripEntity>> setFreightRate({
    required String companyId,
    required String tripId,
    required Money agreedFreightRatePerTon,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  }) async {
    try {
      final decimal = _codec.encodeNonNegative(
        agreedFreightRatePerTon,
        configuration: financialConfiguration,
      );
      final model = await _remoteDataSource.setFreightRate(
        companyId: companyId,
        tripId: tripId,
        rateDecimal: decimal,
        expectedUpdatedAt: expectedUpdatedAt,
      );
      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromFinancialTermsPostgrest(error));
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
