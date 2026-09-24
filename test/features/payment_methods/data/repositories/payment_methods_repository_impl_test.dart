import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/payment_methods/data/datasources/payment_methods_remote_data_source.dart';
import 'package:horus_system/features/payment_methods/data/models/payment_method_model.dart';
import 'package:horus_system/features/payment_methods/data/repositories/payment_methods_repository_impl.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('PaymentMethodsRepositoryImpl', () {
    test('all read forwards exact company scope and maps entities', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events);
      final repository = _repository(dataSource);

      final result = await repository.getPaymentMethods(companyId: 'company-1');

      expect(result, isA<Success>());
      expect(result.dataOrNull?.single.name, 'Cash');
      expect(dataSource.lastCompanyId, 'company-1');
      expect(events, ['getAll']);
    });

    test(
      'active read forwards exact company scope and maps entities',
      () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events);
      final repository = _repository(dataSource);

      final result = await repository.getActivePaymentMethods(
        companyId: 'company-1',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull, hasLength(1));
      expect(dataSource.lastCompanyId, 'company-1');
      expect(events, ['getActive']);
      },
    );

    test('model-to-entity failure stays inside repository boundary', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(
        events: events,
        model: const _ThrowingPaymentMethodModel(),
      );
      final repository = _repository(dataSource);

      final result = await repository.getPaymentMethods(companyId: 'company-1');

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('add mutation is the server-audited boundary', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events);
      final repository = _repository(dataSource);

      final result = await repository.addPaymentMethod(
        data: const PaymentMethodWriteData(
          companyId: 'company-1',
          name: 'Bank',
        ),
        actorRole: 'owner',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.name, 'Bank');
      expect(events, ['add']);
    });

    test('update avoids redundant audit snapshot lookup', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events);
      final repository = _repository(dataSource);

      final result = await repository.updatePaymentMethod(
        paymentMethodId: 'method-1',
        data: const PaymentMethodWriteData(
          companyId: 'company-1',
          name: 'Updated',
        ),
        actorRole: 'owner',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.name, 'Updated');
      expect(events, ['update']);
    });

    test('lifecycle mutations avoid redundant audit snapshot lookup', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events);
      final repository = _repository(dataSource);

      final deactivated = await repository.deactivatePaymentMethod(
        companyId: 'company-1',
        paymentMethodId: 'method-1',
        actorRole: 'owner',
      );
      expect(deactivated.dataOrNull?.isActive, isFalse);
      expect(events, ['deactivate']);

      events.clear();
      final reactivated = await repository.reactivatePaymentMethod(
        companyId: 'company-1',
        paymentMethodId: 'method-1',
        actorRole: 'owner',
      );
      expect(reactivated.dataOrNull?.isActive, isTrue);
      expect(events, ['reactivate']);
    });

    test('42501 uses view permission code for reads', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events)
        ..getAllError = const PostgrestException(
          message: 'permission denied',
          code: '42501',
        );
      final repository = _repository(dataSource);

      final result = await repository.getPaymentMethods(companyId: 'company-1');

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionPaymentMethodsView,
      );
      expect(result.failureOrNull?.message, isNull);
    });

    test('42501 uses management permission code for mutations', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events)
        ..addError = const PostgrestException(
          message: 'permission denied',
          code: '42501',
        );
      final repository = _repository(dataSource);

      final result = await repository.addPaymentMethod(
        data: const PaymentMethodWriteData(
          companyId: 'company-1',
          name: 'Cash',
        ),
        actorRole: 'owner',
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionPaymentMethodsManagement,
      );
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['add']);
    });

    test('not-found mutation error keeps stable sanitized failure', () async {
      final events = <String>[];
      final dataSource = _FakePaymentMethodsRemoteDataSource(events: events)
        ..deactivateError = const PostgrestException(
          message: 'missing internal wording',
          code: 'PGRST116',
        );
      final repository = _repository(dataSource);

      final result = await repository.deactivatePaymentMethod(
        companyId: 'company-1',
        paymentMethodId: 'missing',
        actorRole: 'owner',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(result.failureOrNull?.code, FailureCodes.paymentMethodNotFound);
      expect(result.failureOrNull?.message, isNull);
      expect(dataSource.lastCompanyId, 'company-1');
      expect(dataSource.lastPaymentMethodId, 'missing');
      expect(events, ['deactivate']);
    });

    test('generic Postgrest and unexpected errors are sanitized', () async {
      final postgrestEvents = <String>[];
      final postgrestDataSource =
          _FakePaymentMethodsRemoteDataSource(events: postgrestEvents)
            ..getAllError = const PostgrestException(
              message: 'database unavailable',
              code: 'PGRST500',
              details: 'internal details',
              hint: 'internal hint',
            );
      final postgrestRepository = _repository(postgrestDataSource);

      final serverResult = await postgrestRepository.getPaymentMethods(
        companyId: 'company-1',
      );
      expect(serverResult.failureOrNull, isA<ServerFailure>());
      expect(serverResult.failureOrNull?.code, FailureCodes.serverError);
      expect(serverResult.failureOrNull?.message, isNull);
      expect(postgrestEvents, ['getAll']);

      final unexpectedEvents = <String>[];
      final unexpectedDataSource = _FakePaymentMethodsRemoteDataSource(
        events: unexpectedEvents,
      )..getActiveError = StateError('unexpected runtime details');
      final unexpectedRepository = _repository(unexpectedDataSource);

      final unexpectedResult = await unexpectedRepository
          .getActivePaymentMethods(companyId: 'company-1');
      expect(unexpectedResult.failureOrNull, isA<UnexpectedFailure>());
      expect(
        unexpectedResult.failureOrNull?.code,
        FailureCodes.unexpectedError,
      );
      expect(unexpectedResult.failureOrNull?.message, isNull);
      expect(unexpectedEvents, ['getActive']);
    });
  });
}

PaymentMethodsRepositoryImpl _repository(
  _FakePaymentMethodsRemoteDataSource dataSource,
) {
  return PaymentMethodsRepositoryImpl(remoteDataSource: dataSource);
}

final class _FakePaymentMethodsRemoteDataSource
    implements PaymentMethodsRemoteDataSource {
  final List<String> events;
  Object? getAllError;
  Object? getActiveError;
  Object? lookupError;
  Object? addError;
  Object? updateError;
  Object? deactivateError;
  Object? reactivateError;
  String? lastCompanyId;
  String? lastPaymentMethodId;
  PaymentMethodModel model;

  _FakePaymentMethodsRemoteDataSource({
    required this.events,
    PaymentMethodModel? model,
  }) : model = model ?? _model(isActive: true);

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String companyId,
  }) async {
    events.add('getAll');
    lastCompanyId = companyId;
    _throwIfPresent(getAllError);
    return [model];
  }

  @override
  Future<List<PaymentMethodModel>> getActivePaymentMethods({
    required String companyId,
  }) async {
    events.add('getActive');
    lastCompanyId = companyId;
    _throwIfPresent(getActiveError);
    return model.isActive ? [model] : [];
  }

  @override
  Future<PaymentMethodModel> getPaymentMethodById({
    required String companyId,
    required String paymentMethodId,
  }) async {
    events.add('lookup');
    lastCompanyId = companyId;
    lastPaymentMethodId = paymentMethodId;
    _throwIfPresent(lookupError);
    return model;
  }

  @override
  Future<PaymentMethodModel> addPaymentMethod({
    required PaymentMethodWriteData data,
  }) async {
    events.add('add');
    lastCompanyId = data.companyId;
    _throwIfPresent(addError);
    model = _model(companyId: data.companyId, name: data.name, isActive: true);
    return model;
  }

  @override
  Future<PaymentMethodModel> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
  }) async {
    events.add('update');
    lastCompanyId = data.companyId;
    lastPaymentMethodId = paymentMethodId;
    _throwIfPresent(updateError);
    model = _model(
      id: paymentMethodId,
      companyId: data.companyId,
      name: data.name,
      isActive: model.isActive,
    );
    return model;
  }

  @override
  Future<PaymentMethodModel> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  }) async {
    events.add('deactivate');
    lastCompanyId = companyId;
    lastPaymentMethodId = paymentMethodId;
    _throwIfPresent(deactivateError);
    model = _model(
      id: paymentMethodId,
      companyId: companyId,
      name: model.name,
      isActive: false,
    );
    return model;
  }

  @override
  Future<PaymentMethodModel> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  }) async {
    events.add('reactivate');
    lastCompanyId = companyId;
    lastPaymentMethodId = paymentMethodId;
    _throwIfPresent(reactivateError);
    model = _model(
      id: paymentMethodId,
      companyId: companyId,
      name: model.name,
      isActive: true,
    );
    return model;
  }

  void _throwIfPresent(Object? error) {
    if (error != null) throw error;
  }
}

final class _ThrowingPaymentMethodModel extends PaymentMethodModel {
  const _ThrowingPaymentMethodModel()
    : super(
        id: 'method-1',
        companyId: 'company-1',
        name: 'Cash',
        code: 'other',
        isActive: true,
      );

  @override
  String get id => throw StateError('payment method mapping failed');
}

PaymentMethodModel _model({
  String id = 'method-1',
  String companyId = 'company-1',
  String name = 'Cash',
  required bool isActive,
}) {
  return PaymentMethodModel(
    id: id,
    companyId: companyId,
    name: name,
    code: 'other',
    isActive: isActive,
    createdAt: DateTime.utc(2026, 8, 10),
    updatedAt: DateTime.utc(2026, 8, 10),
  );
}
