import 'dart:typed_data';

import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_location.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_reference.dart';
import 'package:horus_system/core/documents/domain/repositories/business_document_repository.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/drivers/data/datasources/driver_compensation_remote_data_source.dart';
import 'package:horus_system/features/drivers/data/models/driver_compensation_model.dart';
import 'package:horus_system/features/drivers/data/repositories/driver_compensation_repository_impl.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:horus_system/features/drivers/domain/failures/driver_compensation_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverCompensationRepositoryImpl', () {
    test('uploads contract then persists revision', () async {
      final operations = <String>[];
      final remote = _FakeRemoteDataSource(operations: operations);
      final documents = _FakeBusinessDocumentRepository(operations: operations);
      final repository = _repository(remote, documents);

      final result = await repository.createRevision(
        data: _writeData(),
        actorRole: 'owner',
        contractDocument: _document(),
      );

      expect(result.isSuccess, isTrue);
      expect(operations, ['upload', 'create_revision']);
      expect(documents.deletedReferences, isEmpty);
      expect(remote.lastContractDocumentReference, isNotNull);
    });

    test('cleans uploaded document when revision persistence fails', () async {
      final operations = <String>[];
      final remote = _FakeRemoteDataSource(
        operations: operations,
        createError: const PostgrestException(
          message: 'conflicting key value violates exclusion constraint',
          code: '23P01',
        ),
      );
      final documents = _FakeBusinessDocumentRepository(operations: operations);
      final repository = _repository(remote, documents);

      final result = await repository.createRevision(
        data: _writeData(),
        actorRole: 'owner',
        contractDocument: _document(),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.conflictOverlap,
      );
      expect(operations, ['upload', 'create_revision', 'delete_document']);
      expect(documents.deletedReferences, hasLength(1));
    });

    test('attaches contract without redundant audit snapshot lookup', () async {
      final operations = <String>[];
      final remote = _FakeRemoteDataSource(operations: operations);
      final documents = _FakeBusinessDocumentRepository(operations: operations);
      final repository = _repository(remote, documents);
      final revision = _entity();

      final result = await repository.attachContractDocument(
        revision: revision,
        actorRole: 'admin',
        document: _document(),
      );

      expect(result.isSuccess, isTrue);
      expect(operations, ['upload', 'attach_document']);
      expect(result.dataOrNull?.contractDocumentReference, isNotNull);
    });

    test('history query remains company and driver scoped', () async {
      final remote = _FakeRemoteDataSource();
      final repository = _repository(remote, _FakeBusinessDocumentRepository());

      final result = await repository.getHistory(
        companyId: _companyId,
        driverId: _driverId,
      );

      expect(result.isSuccess, isTrue);
      expect(remote.lastHistoryCompanyId, _companyId);
      expect(remote.lastHistoryDriverId, _driverId);
      expect(result.dataOrNull?.single.amount.minorUnits, 500000);
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';

DriverCompensationRepositoryImpl _repository(
  DriverCompensationRemoteDataSource remote,
  BusinessDocumentRepository documents,
) {
  return DriverCompensationRepositoryImpl(
    remoteDataSource: remote,
    businessDocumentRepository: documents,
  );
}

DriverCompensationWriteData _writeData() {
  return DriverCompensationWriteData(
    companyId: _companyId,
    driverId: _driverId,
    amount: Money(minorUnits: 500000, currency: CurrencyCode.tryParse('AED')!),
    currencyFractionDigits: 2,
    effectiveFrom: BusinessDate(year: 2026, month: 1, day: 1),
    contractReference: 'EMP-001',
  );
}

BusinessDocumentFile _document() {
  return BusinessDocumentFile(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'contract.pdf',
  );
}

DriverCompensationRevision _entity() {
  return DriverCompensationRevision(
    id: '11111111-1111-1111-1111-111111111111',
    companyId: _companyId,
    driverId: _driverId,
    amount: Money(minorUnits: 500000, currency: CurrencyCode.tryParse('AED')!),
    currencyFractionDigits: 2,
    effectiveFrom: BusinessDate(year: 2026, month: 1, day: 1),
  );
}

DriverCompensationModel _model({
  String id = '11111111-1111-1111-1111-111111111111',
  String? documentReference,
}) {
  return DriverCompensationModel(
    id: id,
    companyId: _companyId,
    driverId: _driverId,
    amountMinorUnits: 500000,
    currencyCode: 'AED',
    currencyFractionDigits: 2,
    effectiveFrom: '2026-01-01',
    contractReference: 'EMP-001',
    contractDocumentReference: documentReference,
  );
}

final class _FakeRemoteDataSource
    implements DriverCompensationRemoteDataSource {
  final List<String>? operations;
  final Object? createError;
  String? lastHistoryCompanyId;
  String? lastHistoryDriverId;
  BusinessDocumentReference? lastContractDocumentReference;

  _FakeRemoteDataSource({this.operations, this.createError});

  @override
  Future<List<DriverCompensationModel>> getHistory({
    required String companyId,
    required String driverId,
  }) async {
    lastHistoryCompanyId = companyId;
    lastHistoryDriverId = driverId;
    return [_model()];
  }

  @override
  Future<DriverCompensationModel> getById({
    required String companyId,
    required String revisionId,
    required String driverId,
  }) async {
    operations?.add('get_revision');
    return _model(id: revisionId);
  }

  @override
  Future<DriverCompensationModel> createRevision({
    required String revisionId,
    required DriverCompensationWriteData data,
    BusinessDocumentReference? contractDocumentReference,
  }) async {
    operations?.add('create_revision');
    lastContractDocumentReference = contractDocumentReference;
    if (createError != null) throw createError!;
    return _model(
      id: revisionId,
      documentReference: contractDocumentReference?.value,
    );
  }

  @override
  Future<DriverCompensationModel> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required BusinessDate effectiveTo,
  }) async {
    operations?.add('end_revision');
    return DriverCompensationModel(
      id: revisionId,
      companyId: companyId,
      driverId: driverId,
      amountMinorUnits: 500000,
      currencyCode: 'AED',
      currencyFractionDigits: 2,
      effectiveFrom: '2026-01-01',
      effectiveTo:
          '${effectiveTo.year.toString().padLeft(4, '0')}-'
          '${effectiveTo.month.toString().padLeft(2, '0')}-'
          '${effectiveTo.day.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<DriverCompensationModel> attachContractDocument({
    required String companyId,
    required String revisionId,
    required String driverId,
    required BusinessDocumentReference reference,
  }) async {
    operations?.add('attach_document');
    return _model(id: revisionId, documentReference: reference.value);
  }
}

final class _FakeBusinessDocumentRepository
    implements BusinessDocumentRepository {
  final List<String>? operations;
  final List<BusinessDocumentReference> deletedReferences = [];

  _FakeBusinessDocumentRepository({this.operations});

  BusinessDocumentReference get _reference => const BusinessDocumentReference(
    'companies/11111111-1111-1111-1111-111111111111/driver-compensation/11111111-1111-1111-1111-111111111111/employment-contract/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pdf',
  );

  @override
  Future<Result<BusinessDocumentReference>> upload({
    required BusinessDocumentLocation location,
    required BusinessDocumentFile file,
  }) async {
    operations?.add('upload');
    return Success(_reference);
  }

  @override
  Future<Result<void>> delete({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    operations?.add('delete_document');
    deletedReferences.add(reference);
    return const Success<void>(null);
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    return const Success(BusinessDocumentAccess('https://example.test'));
  }

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required BusinessDocumentReference reference,
  }) async {
    return Success(Uint8List(0));
  }
}
