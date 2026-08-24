import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/company_subscription.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../datasources/subscriptions_remote_data_source.dart';
import '../mappers/subscription_mapper.dart';
import 'subscriptions_repository_failure_mapper.dart';

final class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  final SubscriptionsRemoteDataSource remoteDataSource;

  const SubscriptionsRepositoryImpl({required this.remoteDataSource});

  static const _failureMapper = SubscriptionsRepositoryFailureMapper();

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
      final model = await remoteDataSource.getCurrentCompanySubscription(
        companyId: companyId,
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
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
