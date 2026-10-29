import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../errors/common_failures.dart';
import '../../../errors/failure_codes.dart';
import '../../../logging/app_logger.dart';
import '../../domain/entities/company_data_change.dart';
import '../../domain/policies/company_invalidation_policy.dart';
import '../../domain/usecases/watch_company_data_changes_usecase.dart';
import 'company_realtime_state.dart';

/// One source subscription per active company session. It routes typed
/// invalidations; visible feature boundaries decide when to refresh.
final class CompanyRealtimeCubit extends Cubit<CompanyRealtimeState> {
  final WatchCompanyDataChangesUseCase _watchChanges;
  StreamSubscription? _subscription;
  int _watchGeneration = 0;

  CompanyRealtimeCubit({required WatchCompanyDataChangesUseCase watchChanges})
    : _watchChanges = watchChanges,
      super(const CompanyRealtimeState(companyId: ''));

  void watchCompany(
    String companyId, {
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    final generation = ++_watchGeneration;
    AppLogger.debug('realtime.session.watch_started');
    final previousSubscription = _subscription;
    if (previousSubscription != null) {
      unawaited(
        previousSubscription.cancel().onError((Object _, StackTrace _) {
          if (isClosed || generation != _watchGeneration) return;
          emit(
            CompanyRealtimeState(
              companyId: companyId,
              revisions: state.revisions,
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
          WatchCompanyDataChangesParams(
            companyId: companyId,
            additionalResources: additionalResources,
          ),
        ).listen(
          (result) {
            if (isClosed || generation != _watchGeneration) return;

            final failure = result.failureOrNull;
            if (failure != null) {
              emit(
                CompanyRealtimeState(
                  companyId: companyId,
                  revisions: state.revisions,
                  failure: failure,
                ),
              );
              return;
            }

            final change = result.dataOrNull;
            if (change == null || change.companyId != companyId) return;

            AppLogger.debug('realtime.session.signal_${change.resource.name}');
            final affected = CompanyInvalidationPolicy.affectedBy(
              change.resource,
            );
            if (affected.isEmpty) return;

            final revisions = {...state.revisions};
            for (final resource in affected) {
              revisions[resource] = (revisions[resource] ?? 0) + 1;
            }

            emit(
              CompanyRealtimeState(
                companyId: companyId,
                revisions: Map.unmodifiable(revisions),
              ),
            );
          },
          onError: (_, _) {
            if (isClosed || generation != _watchGeneration) return;
            emit(
              CompanyRealtimeState(
                companyId: companyId,
                revisions: state.revisions,
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
    AppLogger.debug('realtime.session.close_requested');
    ++_watchGeneration;
    // Stop emitting immediately, without waiting on remote channel cleanup.
    Future<void>? cancellation;
    try {
      cancellation = _subscription?.cancel().onError((Object _, StackTrace _) {
        AppLogger.debug('realtime_channel_cleanup_failed');
      });
    } catch (_) {
      AppLogger.debug('realtime_channel_cleanup_failed');
    }
    await super.close();
    await cancellation;
  }
}
