import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/repositories/driver_balance_repository.dart';
import '../datasources/canonical_driver_balance_remote_data_source.dart';
import '../mappers/driver_balance_mapper.dart';

class DriverBalanceRepositoryImpl implements DriverBalanceRepository {
  final CanonicalDriverBalanceRemoteDataSource remoteDataSource;

  const DriverBalanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  }) async {
    try {
      final model = await remoteDataSource.getCanonicalDriverBalance(
        companyId: companyId,
        driverId: driverId,
        beforeExclusive: beforeExclusive,
        checkpointBeforeExclusive: checkpointBeforeExclusive,
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        return const FailureResult(
          PermissionFailure(
            code: FailureCodes.permissionDriverFinanceView,
            message: 'Driver finance access is not allowed.',
          ),
        );
      }
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
