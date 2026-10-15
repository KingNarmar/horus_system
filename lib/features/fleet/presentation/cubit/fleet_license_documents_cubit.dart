import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/fleet_license_document.dart';
import '../../domain/entities/fleet_license_document_file.dart';
import '../../domain/entities/fleet_license_document_file_side.dart';
import '../../domain/entities/fleet_license_document_target.dart';
import '../../domain/usecases/fleet_license_document_usecases.dart';
import '../../domain/usecases/fleet_usecases.dart';
import 'fleet_license_documents_state.dart';

final class FleetLicenseDocumentsCubit
    extends Cubit<FleetLicenseDocumentsState> {
  final GetFleetLicenseDocumentUseCase getDocumentUseCase;
  final UploadFleetLicenseDocumentFileUseCase uploadFileUseCase;
  final GetFleetLicenseDocumentFileAccessUseCase getFileAccessUseCase;
  final DownloadFleetLicenseDocumentFileUseCase downloadFileUseCase;
  final ReplaceFleetLicenseDocumentFileUseCase replaceFileUseCase;
  final RemoveFleetLicenseDocumentUseCase removeDocumentUseCase;
  final CanManageFleetUseCase canManageFleetUseCase;
  final GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase;

  int _generation = 0;
  int _mutationRevision = 0;
  int _fileReadRequestId = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _refreshPending = false;

  FleetLicenseDocumentsCubit({
    required this.getDocumentUseCase,
    required this.uploadFileUseCase,
    required this.getFileAccessUseCase,
    required this.downloadFileUseCase,
    required this.replaceFileUseCase,
    required this.removeDocumentUseCase,
    required this.canManageFleetUseCase,
    required this.getCompanyBusinessDateUseCase,
  }) : super(const FleetLicenseDocumentsInitial());

  Future<void> load({
    required CurrentCompanyContext currentCompanyContext,
    required FleetLicenseDocumentTarget target,
  }) async {
    if (isClosed) return;
    final generation = ++_generation;
    ++_fileReadRequestId;
    _refreshPending = false;
    _isLoading = true;
    emit(const FleetLicenseDocumentsLoading());

    try {
      final documentResult = await getDocumentUseCase(
        GetFleetLicenseDocumentParams(
          currentCompanyContext: currentCompanyContext,
          target: target,
        ),
      );
      if (!_isCurrentGeneration(generation)) return;

      final documentFailure = documentResult.failureOrNull;
      if (documentFailure != null) {
        emit(FleetLicenseDocumentsFailure(documentFailure));
        return;
      }

      final manageResult = await canManageFleetUseCase(
        CanManageFleetParams(currentCompanyContext: currentCompanyContext),
      );
      if (!_isCurrentGeneration(generation)) return;

      final manageFailure = manageResult.failureOrNull;
      if (manageFailure != null) {
        emit(FleetLicenseDocumentsFailure(manageFailure));
        return;
      }

      emit(
        FleetLicenseDocumentsLoaded(
          currentCompanyContext: currentCompanyContext,
          target: target,
          document: documentResult.dataOrNull,
          canManage: manageResult.dataOrNull ?? false,
        ),
      );
    } finally {
      if (_isCurrentGeneration(generation)) {
        _isLoading = false;
        _flushPendingRefresh();
      }
    }
  }

  /// Authoritative, company-scoped reload. The Broadcast contains no files.
  /// Requests during an active mutation are coalesced and replayed afterward.
  Future<void> refreshActiveDocument() async {
    if (isClosed) return;
    if (_isLoading || _isRefreshing) {
      _refreshPending = true;
      return;
    }
    final initial = state;
    if (initial is! FleetLicenseDocumentsLoaded) return;
    if (initial.isMutating) {
      _refreshPending = true;
      return;
    }

    _isRefreshing = true;
    try {
      do {
        _refreshPending = false;
        final current = state;
        if (current is! FleetLicenseDocumentsLoaded) return;
        if (current.isMutating) {
          _refreshPending = true;
          return;
        }

        final generation = _generation;
        final mutationRevision = _mutationRevision;
        final result = await getDocumentUseCase(
          GetFleetLicenseDocumentParams(
            currentCompanyContext: current.currentCompanyContext,
            target: current.target,
          ),
        );
        if (!_isCurrentGeneration(generation)) return;

        final latest = state;
        if (latest is! FleetLicenseDocumentsLoaded) return;
        if (latest.isMutating || mutationRevision != _mutationRevision) {
          _refreshPending = true;
          return;
        }

        final failure = result.failureOrNull;
        if (failure is PermissionFailure || failure is AuthFailure) {
          emit(FleetLicenseDocumentsFailure(failure));
          return;
        }
        emit(
          latest.copyWith(
            document: failure == null ? result.dataOrNull : latest.document,
            failure: failure,
          ),
        );
      } while (_refreshPending && state is FleetLicenseDocumentsLoaded);
    } finally {
      _isRefreshing = false;
      _flushPendingRefresh();
    }
  }

  /// The page owns this Cubit, but the details route owns its visible target.
  void dismissDetails() {
    if (isClosed) return;
    ++_generation;
    ++_fileReadRequestId;
    _refreshPending = false;
    emit(const FleetLicenseDocumentsInitial());
  }

  bool _isCurrentGeneration(int generation) =>
      !isClosed && generation == _generation;

  void _flushPendingRefresh() {
    if (!_refreshPending || isClosed || _isLoading || _isRefreshing) return;
    final latest = state;
    if (latest is FleetLicenseDocumentsLoaded && !latest.isMutating) {
      unawaited(refreshActiveDocument());
    }
  }

  Future<bool> upload({
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    final current = state;
    if (current is! FleetLicenseDocumentsLoaded || current.isMutating) {
      return false;
    }

    final generation = _generation;
    ++_mutationRevision;
    emit(current.copyWith(isMutating: true, failure: null));
    try {
    final businessDateResult = await _getCurrentBusinessDate(current);
    if (!_isCurrentGeneration(generation)) return false;
    final businessDateFailure = businessDateResult.failureOrNull;
    if (businessDateFailure != null) {
      final latest = state;
      if (latest is FleetLicenseDocumentsLoaded) {
        emit(latest.copyWith(isMutating: false, failure: businessDateFailure));
      }
      return false;
    }
    final currentBusinessDate = businessDateResult.dataOrNull;
    if (currentBusinessDate == null) {
      final latest = state;
      if (latest is FleetLicenseDocumentsLoaded) {
        emit(
          latest.copyWith(
            isMutating: false,
            failure: const UnexpectedFailure(),
          ),
        );
      }
      return false;
    }

    final result = await uploadFileUseCase(
      UploadFleetLicenseDocumentFileParams(
        currentCompanyContext: current.currentCompanyContext,
        target: current.target,
        side: side,
        file: file,
        currentBusinessDate: currentBusinessDate,
        newLicenseExpiryDate: newLicenseExpiryDate,
      ),
    );

    final latest = state;
    if (!_isCurrentGeneration(generation) ||
        latest is! FleetLicenseDocumentsLoaded) return false;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(latest.copyWith(isMutating: false, failure: failure));
      return false;
    }

    emit(
      latest.copyWith(
        document: result.dataOrNull,
        isMutating: false,
        failure: null,
      ),
    );
    return true;
    } finally {
      _flushPendingRefresh();
    }
  }

  Future<bool> replace({
    required FleetLicenseDocument document,
    required FleetLicenseDocumentFile file,
    required BusinessDocumentFile replacement,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    final current = state;
    if (current is! FleetLicenseDocumentsLoaded || current.isMutating) {
      return false;
    }

    final generation = _generation;
    ++_mutationRevision;
    emit(current.copyWith(isMutating: true, failure: null));
    try {
    final businessDateResult = await _getCurrentBusinessDate(current);
    if (!_isCurrentGeneration(generation)) return false;
    final businessDateFailure = businessDateResult.failureOrNull;
    if (businessDateFailure != null) {
      final latest = state;
      if (latest is FleetLicenseDocumentsLoaded) {
        emit(latest.copyWith(isMutating: false, failure: businessDateFailure));
      }
      return false;
    }
    final currentBusinessDate = businessDateResult.dataOrNull;
    if (currentBusinessDate == null) {
      final latest = state;
      if (latest is FleetLicenseDocumentsLoaded) {
        emit(
          latest.copyWith(
            isMutating: false,
            failure: const UnexpectedFailure(),
          ),
        );
      }
      return false;
    }

    final result = await replaceFileUseCase(
      ReplaceFleetLicenseDocumentFileParams(
        currentCompanyContext: current.currentCompanyContext,
        target: current.target,
        document: document,
        file: file,
        replacement: replacement,
        currentBusinessDate: currentBusinessDate,
        newLicenseExpiryDate: newLicenseExpiryDate,
      ),
    );

    final latest = state;
    if (!_isCurrentGeneration(generation) ||
        latest is! FleetLicenseDocumentsLoaded) return false;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(latest.copyWith(isMutating: false, failure: failure));
      return false;
    }

    emit(
      latest.copyWith(
        document: result.dataOrNull,
        isMutating: false,
        failure: null,
      ),
    );
    return true;
    } finally {
      _flushPendingRefresh();
    }
  }

  Future<bool> remove(FleetLicenseDocument document) async {
    final current = state;
    if (current is! FleetLicenseDocumentsLoaded || current.isMutating) {
      return false;
    }

    final generation = _generation;
    ++_mutationRevision;
    emit(current.copyWith(isMutating: true, failure: null));
    try {
    final result = await removeDocumentUseCase(
      FleetLicenseDocumentActionParams(
        currentCompanyContext: current.currentCompanyContext,
        target: current.target,
        document: document,
      ),
    );

    final latest = state;
    if (!_isCurrentGeneration(generation) ||
        latest is! FleetLicenseDocumentsLoaded) return false;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(latest.copyWith(isMutating: false, failure: failure));
      return false;
    }

    emit(latest.copyWith(document: null, isMutating: false, failure: null));
    return true;
    } finally {
      _flushPendingRefresh();
    }
  }

  Future<BusinessDocumentAccess?> createAccess(
    FleetLicenseDocument document,
    FleetLicenseDocumentFile file,
  ) async {
    final generation = _generation;
    final fileReadRequestId = ++_fileReadRequestId;
    final current = state;
    if (current is! FleetLicenseDocumentsLoaded) return null;

    final result = await getFileAccessUseCase(
      FleetLicenseDocumentFileActionParams(
        currentCompanyContext: current.currentCompanyContext,
        target: current.target,
        document: document,
        file: file,
      ),
    );
    if (!_isCurrentGeneration(generation) ||
        fileReadRequestId != _fileReadRequestId ||
        state is! FleetLicenseDocumentsLoaded) return null;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit((state as FleetLicenseDocumentsLoaded).copyWith(failure: failure));
      return null;
    }

    emit((state as FleetLicenseDocumentsLoaded).copyWith(failure: null));
    return result.dataOrNull;
  }

  Future<Result<BusinessDate>> _getCurrentBusinessDate(
    FleetLicenseDocumentsLoaded current,
  ) {
    return getCompanyBusinessDateUseCase(
      GetCompanyBusinessDateParams(
        companyId: current.currentCompanyContext.companyId,
      ),
    );
  }

  Future<Uint8List?> download(
    FleetLicenseDocument document,
    FleetLicenseDocumentFile file,
  ) async {
    final generation = _generation;
    final fileReadRequestId = ++_fileReadRequestId;
    final current = state;
    if (current is! FleetLicenseDocumentsLoaded) return null;

    final result = await downloadFileUseCase(
      FleetLicenseDocumentFileActionParams(
        currentCompanyContext: current.currentCompanyContext,
        target: current.target,
        document: document,
        file: file,
      ),
    );
    if (!_isCurrentGeneration(generation) ||
        fileReadRequestId != _fileReadRequestId ||
        state is! FleetLicenseDocumentsLoaded) return null;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit((state as FleetLicenseDocumentsLoaded).copyWith(failure: failure));
      return null;
    }

    emit((state as FleetLicenseDocumentsLoaded).copyWith(failure: null));
    return result.dataOrNull;
  }
}
