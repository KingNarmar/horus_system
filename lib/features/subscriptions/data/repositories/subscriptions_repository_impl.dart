import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_subscription.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../datasources/subscriptions_remote_data_source.dart';
import '../mappers/subscription_mapper.dart';

final class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  final SubscriptionsRemoteDataSource remoteDataSource;

  const SubscriptionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() {
    return _guard(() async {
      final models = await remoteDataSource.getAvailablePlans();
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<CompanySubscription?>> getCurrentCompanySubscription({
    required String companyId,
  }) {
    return _guard(() async {
      final normalizedCompanyId = companyId.trim();
      if (normalizedCompanyId.isEmpty) {
        return const FailureResult<CompanySubscription?>(
          ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
            message: 'Company id is required.',
          ),
        );
      }

      final model = await remoteDataSource.getCurrentCompanySubscription(
        companyId: normalizedCompanyId,
      );
      if (model == null) return const Success(null);

      final mapped = model.toEntityResult();
      return mapped.when(
        success: (subscription) => Success<CompanySubscription?>(subscription),
        failure: (failure) => FailureResult<CompanySubscription?>(failure),
      );
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_mapPostgrestException(error));
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  Failure _mapPostgrestException(PostgrestException error) {
    return switch (error.code) {
      '42501' => const PermissionFailure(
        code: FailureCodes.permissionSubscriptionsView,
        message: 'Subscription view is not allowed.',
      ),
      _ => ServerFailure(
        code: FailureCodes.serverError,
        message: error.message,
      ),
    };
  }
}
