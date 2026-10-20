import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/route_financial_terms_repository.dart';
import '../datasources/route_financial_terms_remote_data_source.dart';
import '../mappers/route_mapper.dart';
import 'route_repository_failure_mapper.dart';

final class RouteFinancialTermsRepositoryImpl
    implements RouteFinancialTermsRepository {
  final RouteFinancialTermsRemoteDataSource _remoteDataSource;
  final RouteRepositoryFailureMapper _failureMapper;
  final MoneyDecimalCodec _codec;

  const RouteFinancialTermsRepositoryImpl(
    this._remoteDataSource, {
    RouteRepositoryFailureMapper failureMapper =
        const RouteRepositoryFailureMapper(),
    MoneyDecimalCodec codec = const MoneyDecimalCodec(),
  }) : _failureMapper = failureMapper,
       _codec = codec;

  @override
  Future<Result<RouteEntity>> setDefaultFreightRate({
    required String companyId,
    required String routeId,
    required Money rate,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  }) async {
    try {
      final decimal = _codec.encodeNonNegative(
        rate,
        configuration: financialConfiguration,
      );
      final model = await _remoteDataSource.setDefaultFreightRate(
        companyId: companyId,
        routeId: routeId,
        rateDecimal: decimal,
        expectedUpdatedAt: expectedUpdatedAt,
      );
      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
