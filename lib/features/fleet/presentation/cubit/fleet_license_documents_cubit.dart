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
    emit(const FleetLicenseDocumentsLoading());

    final documentResult = await getDocumentUseCase(
      GetFleetLicenseDocumentParams(
        currentCompanyContext: currentCompanyContext,
        target: target,
      ),
    );
    final documentFailure = documentResult.failureOrNull;
    if (documentFailure != null) {
      emit(FleetLicenseDocumentsFailure(documentFailure));
      return;
    }

    final manageResult = await canManageFleetUseCase(
      CanManageFleetParams(currentCompanyContext: currentCompanyContext),
    );
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

    emit(current.copyWith(isMutating: true, failure: null));
    final businessDateResult = await _getCurrentBusinessDate(current);
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
    if (latest is! FleetLicenseDocumentsLoaded) return false;
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

    emit(current.copyWith(isMutating: true, failure: null));
    final businessDateResult = await _getCurrentBusinessDate(current);
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
    if (latest is! FleetLicenseDocumentsLoaded) return false;
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
  }

  Future<bool> remove(FleetLicenseDocument document) async {
    final current = state;
    if (current is! FleetLicenseDocumentsLoaded || current.isMutating) {
      return false;
    }

    emit(current.copyWith(isMutating: true, failure: null));
    final result = await removeDocumentUseCase(
      FleetLicenseDocumentActionParams(
        currentCompanyContext: current.currentCompanyContext,
        target: current.target,
        document: document,
      ),
    );

    final latest = state;
    if (latest is! FleetLicenseDocumentsLoaded) return false;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(latest.copyWith(isMutating: false, failure: failure));
      return false;
    }

    emit(latest.copyWith(document: null, isMutating: false, failure: null));
    return true;
  }

  Future<BusinessDocumentAccess?> createAccess(
    FleetLicenseDocument document,
    FleetLicenseDocumentFile file,
  ) async {
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
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(current.copyWith(failure: failure));
      return null;
    }

    emit(current.copyWith(failure: null));
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
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(current.copyWith(failure: failure));
      return null;
    }

    emit(current.copyWith(failure: null));
    return result.dataOrNull;
  }
}
