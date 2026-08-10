import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/payment_methods/data/datasources/payment_methods_remote_data_source.dart';
import 'package:horus_system/features/payment_methods/data/models/payment_method_model.dart';
import 'package:horus_system/features/payment_methods/data/repositories/payment_methods_repository_impl.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentMethodsRepositoryImpl', () {
    test('create maps entity and writes structured semantic audit', () async {
      final dataSource = _FakePaymentMethodsRemoteDataSource();
      final auditRepository = _FakeAuditLogRepository();
      final repository = PaymentMethodsRepositoryImpl(
        remoteDataSource: dataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addPaymentMethod(
        data: const PaymentMethodWriteData(
          companyId: 'company-1',
          name: 'Cash',
        ),
        actorRole: 'accountant',
      );

      expect(result.dataOrNull?.id, 'method-1');
      expect(dataSource.lastCompanyId, 'company-1');
      final audit = auditRepository.lastWriteData;
      expect(audit?.companyId, 'company-1');
      expect(audit?.actorRole, 'accountant');
      expect(audit?.module, AuditModule.companySettings);
      expect(audit?.entityType, AuditEntityType.paymentMethod);
      expect(audit?.description, 'payment_method_created');
      expect(audit?.oldValues, isNull);
      expect(audit?.newValues?['name'], 'Cash');
    });

    test('duplicate database error maps to stable conflict code', () async {
      final dataSource = _FakePaymentMethodsRemoteDataSource()
        ..addError = PostgrestException(
          message: 'duplicate internal wording',
          code: '23505',
        );
      final auditRepository = _FakeAuditLogRepository();
      final repository = PaymentMethodsRepositoryImpl(
        remoteDataSource: dataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addPaymentMethod(
        data: const PaymentMethodWriteData(
          companyId: 'company-1',
          name: ' cash ',
        ),
        actorRole: 'owner',
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.conflictPaymentMethodDuplicateName,
      );
      expect(auditRepository.lastWriteData, isNull);
    });

    test('status mutation records old and new values', () async {
      final dataSource = _FakePaymentMethodsRemoteDataSource();
      final auditRepository = _FakeAuditLogRepository();
      final repository = PaymentMethodsRepositoryImpl(
        remoteDataSource: dataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.deactivatePaymentMethod(
        companyId: 'company-1',
        paymentMethodId: 'method-1',
        actorRole: 'admin',
      );

      expect(result.dataOrNull?.isActive, isFalse);
      final audit = auditRepository.lastWriteData;
      expect(audit?.description, 'payment_method_deactivated');
      expect(audit?.oldValues?['is_active'], isTrue);
      expect(audit?.newValues?['is_active'], isFalse);
    });
  });
}

final class _FakePaymentMethodsRemoteDataSource
    implements PaymentMethodsRemoteDataSource {
  PostgrestException? addError;
  String? lastCompanyId;
  PaymentMethodModel model = _model(isActive: true);

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String companyId,
  }) async {
    lastCompanyId = companyId;
    return [model];
  }

  @override
  Future<List<PaymentMethodModel>> getActivePaymentMethods({
    required String companyId,
  }) async {
    lastCompanyId = companyId;
    return model.isActive ? [model] : [];
  }

  @override
  Future<PaymentMethodModel> getPaymentMethodById({
    required String companyId,
    required String paymentMethodId,
  }) async {
    lastCompanyId = companyId;
    return model;
  }

  @override
  Future<PaymentMethodModel> addPaymentMethod({
    required PaymentMethodWriteData data,
  }) async {
    lastCompanyId = data.companyId;
    final error = addError;
    if (error != null) throw error;
    model = _model(name: data.name, isActive: true);
    return model;
  }

  @override
  Future<PaymentMethodModel> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
  }) async {
    lastCompanyId = data.companyId;
    model = _model(name: data.name, isActive: model.isActive);
    return model;
  }

  @override
  Future<PaymentMethodModel> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  }) async {
    lastCompanyId = companyId;
    model = _model(name: model.name, isActive: false);
    return model;
  }

  @override
  Future<PaymentMethodModel> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  }) async {
    lastCompanyId = companyId;
    model = _model(name: model.name, isActive: true);
    return model;
  }
}

final class _FakeAuditLogRepository implements AuditLogRepository {
  AuditLogWriteData? lastWriteData;

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    lastWriteData = data;
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}

PaymentMethodModel _model({String name = 'Cash', required bool isActive}) {
  return PaymentMethodModel(
    id: 'method-1',
    companyId: 'company-1',
    name: name,
    code: 'other',
    isActive: isActive,
    createdAt: DateTime.utc(2026, 8, 10),
    updatedAt: DateTime.utc(2026, 8, 10),
  );
}
