import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/company_invitation_preview.dart';
import '../../domain/usecases/accept_company_invitation_usecase.dart';
import '../../domain/usecases/clear_pending_company_invitation_usecase.dart';
import '../../domain/usecases/get_company_invitation_preview_usecase.dart';
import '../../domain/usecases/get_pending_company_invitation_usecase.dart';
import '../../domain/usecases/store_pending_company_invitation_usecase.dart';
import 'company_invitation_acceptance_state.dart';

class CompanyInvitationAcceptanceCubit
    extends Cubit<CompanyInvitationAcceptanceState> {
  final StorePendingCompanyInvitationUseCase _storePendingUseCase;
  final GetPendingCompanyInvitationUseCase _getPendingUseCase;
  final ClearPendingCompanyInvitationUseCase _clearPendingUseCase;
  final GetCompanyInvitationPreviewUseCase _getPreviewUseCase;
  final AcceptCompanyInvitationUseCase _acceptUseCase;

  String? _rawToken;
  CompanyInvitationPreview? _preview;

  CompanyInvitationAcceptanceCubit({
    required StorePendingCompanyInvitationUseCase storePendingUseCase,
    required GetPendingCompanyInvitationUseCase getPendingUseCase,
    required ClearPendingCompanyInvitationUseCase clearPendingUseCase,
    required GetCompanyInvitationPreviewUseCase getPreviewUseCase,
    required AcceptCompanyInvitationUseCase acceptUseCase,
  }) : _storePendingUseCase = storePendingUseCase,
       _getPendingUseCase = getPendingUseCase,
       _clearPendingUseCase = clearPendingUseCase,
       _getPreviewUseCase = getPreviewUseCase,
       _acceptUseCase = acceptUseCase,
       super(const CompanyInvitationAcceptanceInitial());

  Future<void> captureToken({
    required String token,
    required bool isAuthenticated,
  }) async {
    final normalizedToken = token.trim();
    final result = await _storePendingUseCase(normalizedToken);

    final failure = result.failureOrNull;
    if (failure != null) {
      emit(CompanyInvitationAcceptanceFailure(failure));
      return;
    }

    _rawToken = normalizedToken;
    _preview = null;

    if (!isAuthenticated) {
      emit(const CompanyInvitationAwaitingAuthentication());
      return;
    }

    await loadPreview();
  }

  Future<void> restore({required bool isAuthenticated}) async {
    final result = await _getPendingUseCase(const NoParams());
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(CompanyInvitationAcceptanceFailure(failure));
      return;
    }

    final token = result.dataOrNull?.trim();
    if (token == null || token.isEmpty) {
      _rawToken = null;
      _preview = null;
      emit(const CompanyInvitationAcceptanceInitial());
      return;
    }

    _rawToken = token;
    if (!isAuthenticated) {
      emit(const CompanyInvitationAwaitingAuthentication());
      return;
    }

    await loadPreview();
  }

  Future<void> loadPreview() async {
    final token = _rawToken;
    if (token == null || token.isEmpty) {
      await restore(isAuthenticated: true);
      return;
    }

    emit(const CompanyInvitationPreviewLoading());
    final result = await _getPreviewUseCase(token);

    result.when(
      success: (preview) {
        _preview = preview;
        emit(CompanyInvitationPreviewReady(preview));
      },
      failure: (failure) => emit(CompanyInvitationAcceptanceFailure(failure)),
    );
  }

  Future<void> accept() async {
    final token = _rawToken;
    final preview = _preview;
    if (token == null || preview == null) {
      await loadPreview();
      return;
    }

    emit(CompanyInvitationAccepting(preview));
    final result = await _acceptUseCase(token);

    await result.when(
      success: (companyId) async {
        final cleanupResult = await _clearPendingUseCase(const NoParams());
        final cleanupFailure = cleanupResult.failureOrNull;

        _rawToken = null;
        _preview = null;
        emit(
          CompanyInvitationAccepted(
            companyId,
            pendingTokenCleanupFailure: cleanupFailure,
          ),
        );
      },
      failure: (failure) async =>
          emit(CompanyInvitationAcceptanceFailure(failure)),
    );
  }

  Future<void> clear() async {
    final result = await _clearPendingUseCase(const NoParams());
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(CompanyInvitationAcceptanceFailure(failure));
      return;
    }

    _rawToken = null;
    _preview = null;
    emit(const CompanyInvitationAcceptanceInitial());
  }
}
