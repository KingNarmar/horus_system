import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../../domain/usecases/clear_current_company_context_usecase.dart';
import '../../domain/usecases/load_current_company_context_usecase.dart';
import '../../domain/usecases/refresh_selected_company_context_usecase.dart';
import '../../domain/usecases/select_current_company_usecase.dart';
import '../../domain/usecases/watch_company_membership_changes_usecase.dart';
import 'current_company_state.dart';

class CurrentCompanyCubit extends Cubit<CurrentCompanyState> {
  final LoadCurrentCompanyContextUseCase _loadCurrentCompanyContextUseCase;
  final SelectCurrentCompanyUseCase _selectCurrentCompanyUseCase;
  final RefreshSelectedCompanyContextUseCase
  _refreshSelectedCompanyContextUseCase;
  final ClearCurrentCompanyContextUseCase _clearCurrentCompanyContextUseCase;
  final WatchCompanyMembershipChangesUseCase? _watchMembershipChangesUseCase;
  StreamSubscription? _membershipSubscription;
  int _membershipGeneration = 0;
  int _requestGeneration = 0;

  CurrentCompanyCubit({
    required LoadCurrentCompanyContextUseCase loadCurrentCompanyContextUseCase,
    required SelectCurrentCompanyUseCase selectCurrentCompanyUseCase,
    required RefreshSelectedCompanyContextUseCase
    refreshSelectedCompanyContextUseCase,
    required ClearCurrentCompanyContextUseCase
    clearCurrentCompanyContextUseCase,
    WatchCompanyMembershipChangesUseCase? watchMembershipChangesUseCase,
  }) : _loadCurrentCompanyContextUseCase = loadCurrentCompanyContextUseCase,
       _selectCurrentCompanyUseCase = selectCurrentCompanyUseCase,
       _refreshSelectedCompanyContextUseCase =
           refreshSelectedCompanyContextUseCase,
       _clearCurrentCompanyContextUseCase = clearCurrentCompanyContextUseCase,
       _watchMembershipChangesUseCase = watchMembershipChangesUseCase,
       super(const CurrentCompanyInitial());

  /// Start the personal membership channel for this authenticated identity.
  /// Every event triggers a server re-read; client messages never grant roles.
  void startWatchingMembership(String userId) {
    if (_watchMembershipChangesUseCase == null || userId.trim().isEmpty) {
      return;
    }
    final generation = ++_membershipGeneration;
    final previous = _membershipSubscription;
    if (previous != null) {
      unawaited(previous.cancel().onError((Object _, StackTrace _) {
        AppLogger.debug('membership_channel_cleanup_failed');
      }));
    }

    _membershipSubscription =
        _watchMembershipChangesUseCase(
          WatchCompanyMembershipChangesParams(userId: userId),
        ).listen(
          (_) {
            if (isClosed || generation != _membershipGeneration) return;
            unawaited(revalidateSelectedCompany());
          },
          onError: (Object _, StackTrace _) {
            if (isClosed || generation != _membershipGeneration) return;
            unawaited(revalidateSelectedCompany());
          },
        );
  }

  Future<void> stopWatchingMembership() async {
    ++_membershipGeneration;
    final subscription = _membershipSubscription;
    _membershipSubscription = null;
    try {
      await subscription?.cancel();
    } catch (_) {
      AppLogger.debug('membership_channel_cleanup_failed');
    }
  }

  Future<void> loadCurrentCompanyContext() async {
    final request = ++_requestGeneration;
    emit(const CurrentCompanyLoading());

    final result = await _loadCurrentCompanyContextUseCase(const NoParams());
    if (!_isCurrent(request)) return;

    result.when(
      success: (context) => emit(
        context == null
            ? const CurrentCompanyEmpty()
            : CurrentCompanyLoaded(context),
      ),
      failure: (failure) => emit(CurrentCompanyFailure(failure)),
    );
  }

  Future<void> selectCompany(String companyId) async {
    final request = ++_requestGeneration;
    emit(const CurrentCompanyLoading());

    final result = await _selectCurrentCompanyUseCase(
      SelectCurrentCompanyParams(companyId: companyId),
    );
    if (!_isCurrent(request)) return;

    result.when(
      success: (context) => emit(CurrentCompanyLoaded(context)),
      failure: (failure) => emit(CurrentCompanyFailure(failure)),
    );
  }

  Future<void> refreshAndSelectCompany(String companyId) async {
    final request = ++_requestGeneration;
    emit(const CurrentCompanyLoading());
    await _refreshSelected(companyId, request);
  }

  /// On resumed/reconnected/renewed sessions, re-check active membership and
  /// role on the server before exposing the company shell again.
  Future<void> revalidateSelectedCompany() async {
    final current = state;
    if (current is CurrentCompanyEmpty) {
      // A previously revoked membership can be reactivated while logged in.
      await loadCurrentCompanyContext();
      return;
    }

    final context = switch (current) {
      CurrentCompanyLoaded(:final context) => context,
      CurrentCompanyVerifying(:final context) => context,
      _ => null,
    };
    if (context == null) return;

    final request = ++_requestGeneration;
    emit(CurrentCompanyVerifying(context));
    await _refreshSelected(context.companyId, request);
  }

  Future<void> _refreshSelected(String companyId, int request) async {
    final result = await _refreshSelectedCompanyContextUseCase(
      RefreshSelectedCompanyContextParams(companyId: companyId),
    );
    if (!_isCurrent(request)) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      if (failure.code == CompanyFailureCodes.companyNotAvailable) {
        // Never retain the old selection when the membership has been revoked.
        final clearResult = await _clearCurrentCompanyContextUseCase(
          const NoParams(),
        );
        if (!_isCurrent(request)) return;
        final clearFailure = clearResult.failureOrNull;
        if (clearFailure == null) {
          emit(const CurrentCompanyEmpty());
        } else {
          emit(CurrentCompanyFailure(clearFailure));
        }
      } else {
        emit(CurrentCompanyFailure(failure));
      }
      return;
    }

    final context = result.dataOrNull;
    if (context != null) emit(CurrentCompanyLoaded(context));
  }

  Future<void> clearCurrentCompanyContext() async {
    final request = ++_requestGeneration;
    emit(const CurrentCompanyLoading());

    final result = await _clearCurrentCompanyContextUseCase(const NoParams());
    if (!_isCurrent(request)) return;

    result.when(
      success: (_) => emit(const CurrentCompanyEmpty()),
      failure: (failure) => emit(CurrentCompanyFailure(failure)),
    );
  }

  bool _isCurrent(int request) => !isClosed && request == _requestGeneration;

  @override
  Future<void> close() async {
    ++_requestGeneration;
    await stopWatchingMembership();
    await super.close();
  }
}
