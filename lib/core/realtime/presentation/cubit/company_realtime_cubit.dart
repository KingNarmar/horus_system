import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../errors/common_failures.dart';
import '../../../errors/failure_codes.dart';
import '../../../logging/app_logger.dart';
import '../../domain/entities/company_data_change.dart';
import '../../domain/usecases/watch_company_data_changes_usecase.dart';
import 'company_realtime_state.dart';

final class CompanyRealtimeCubit extends Cubit<CompanyRealtimeState> {
  final WatchCompanyDataChangesUseCase _watchChanges;
  StreamSubscription? _subscription;
  int _watchGeneration = 0;

  CompanyRealtimeCubit({required WatchCompanyDataChangesUseCase watchChanges})
    : _watchChanges = watchChanges,
      super(const CompanyRealtimeState(companyId: ''));

  void watchCompany(String companyId) {
    final generation = ++_watchGeneration;
    final previousSubscription = _subscription;
    if (previousSubscription != null) {
      unawaited(
        previousSubscription.cancel().onError((Object _, StackTrace _) {
          if (isClosed || generation != _watchGeneration) return;
          emit(
            CompanyRealtimeState(
              companyId: companyId,
              customersRevision: state.customersRevision,
              failure: const NetworkFailure(
                code: FailureCodes.realtimeSubscriptionUnavailable,
              ),
            ),
          );
        }),
      );
    }
    emit(CompanyRealtimeState(companyId: companyId));

    _subscription =
        _watchChanges(
          WatchCompanyDataChangesParams(companyId: companyId),
        ).listen(
          (result) {
            if (isClosed || generation != _watchGeneration) return;

            final failure = result.failureOrNull;
            if (failure != null) {
              emit(
                CompanyRealtimeState(
                  companyId: companyId,
                  customersRevision: state.customersRevision,
                  failure: failure,
                ),
              );
              return;
            }

            final change = result.dataOrNull;
            if (change?.companyId != companyId ||
                change?.resource != CompanyDataResource.customers) {
              return;
            }

            emit(
              CompanyRealtimeState(
                companyId: companyId,
                customersRevision: state.customersRevision + 1,
              ),
            );
          },
          onError: (_, _) {
            if (isClosed || generation != _watchGeneration) return;
            emit(
              CompanyRealtimeState(
                companyId: companyId,
                customersRevision: state.customersRevision,
                failure: const NetworkFailure(
                  code: FailureCodes.realtimeSubscriptionUnavailable,
                ),
              ),
            );
          },
        );
  }

  @override
  Future<void> close() async {
    ++_watchGeneration;
    try {
      await _subscription?.cancel();
    } catch (_) {
      // Logout must complete even if server-side channel removal fails.
      AppLogger.debug('realtime_channel_cleanup_failed');
    }
    await super.close();
  }
}
