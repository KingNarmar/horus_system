import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customers/domain/entities/customer.dart';
import 'package:horus_system/features/customers/domain/entities/customer_write_data.dart';
import 'package:horus_system/features/customers/domain/repositories/customers_repository.dart';
import 'package:horus_system/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/deactivate_customer_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/reactivate_customer_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:horus_system/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:horus_system/features/customers/presentation/cubit/customers_state.dart';
import 'package:test/test.dart';

import '../../../../helpers/activity_projection_fakes.dart';

void main() {
  late DeferredActivityRepository audit;
  late RecordingActivityConverter converter;
  late CustomersCubit cubit;
  setUp(() {
    audit = DeferredActivityRepository();
    converter = RecordingActivityConverter();
    final repository = _Repository();
    cubit = CustomersCubit(
      getCustomersUseCase: GetCustomersUseCase(repository),
      addCustomerUseCase: AddCustomerUseCase(repository),
      updateCustomerUseCase: UpdateCustomerUseCase(repository),
      deactivateCustomerUseCase: DeactivateCustomerUseCase(repository),
      reactivateCustomerUseCase: ReactivateCustomerUseCase(repository),
      getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(audit),
      convertInstantsToBusinessLocalDateTimesUseCase:
          ConvertInstantsToBusinessLocalDateTimesUseCase(converter),
    );
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test(
    'projects scoped audit timestamps across midnight in company timezone',
    () async {
      await cubit.loadCustomers(_context());
      final pending = cubit.loadCustomerActivity(_entity());
      audit.requests.single.complete(Success([_log()]));
      await pending;
      final state = cubit.state as CustomersLoaded;
      expect(
        state.activityTimestampFor('log-1'),
        BusinessLocalDateTime(
          year: 2026,
          month: 9,
          day: 7,
          hour: 0,
          minute: 30,
        ),
      );
      expect(
        state.selectedCustomerActivity.single.createdAt,
        DateTime.utc(2026, 9, 6, 20, 30),
      );
      expect(converter.timeZoneIds, ['Asia/Dubai']);
      expect(audit.companyIds, ['company-1']);
      expect(audit.modules, [AuditModule.customers]);
      expect(audit.entityTypes, [AuditEntityType.customer]);
      expect(audit.entityIds, ['entity-1']);
      expect(state.isActivityLoading, isFalse);
      expect(
        state.copyWith(searchQuery: 'query').activityTimestampFor('log-1'),
        state.activityTimestampFor('log-1'),
      );
      cubit.clearCustomerActivity();
      expect(
        (cubit.state as CustomersLoaded).activityTimestampFor('log-1'),
        isNull,
      );
    },
  );

  test(
    'projection failure exposes typed failure without raw activity',
    () async {
      converter.failure = const ServerFailure(code: FailureCodes.serverError);
      await cubit.loadCustomers(_context());
      final pending = cubit.loadCustomerActivity(_entity());
      audit.requests.single.complete(Success([_log()]));
      await pending;
      final state = cubit.state as CustomersLoaded;
      expect(state.activityFailure?.code, FailureCodes.serverError);
      expect(state.selectedCustomerActivity, isEmpty);
      expect(state.activityTimestampFor('log-1'), isNull);
      expect(state.isActivityLoading, isFalse);
    },
  );

  test(
    'ignores old activity after a company switch even with the same entity id',
    () async {
      await cubit.loadCustomers(_context());
      final old = cubit.loadCustomerActivity(_entity());
      await cubit.loadCustomers(
        _context(companyId: 'company-2', timezone: 'UTC'),
      );
      final current = cubit.loadCustomerActivity(
        _entity(companyId: 'company-2'),
      );
      audit.requests[1].complete(Success([_log(companyId: 'company-2')]));
      await current;
      audit.requests[0].complete(Success([_log()]));
      await old;
      final state = cubit.state as CustomersLoaded;
      expect(state.selectedCustomerActivity.single.companyId, 'company-2');
      expect(
        state.activityTimestampFor('log-1'),
        BusinessLocalDateTime(
          year: 2026,
          month: 9,
          day: 6,
          hour: 20,
          minute: 30,
        ),
      );
      expect(converter.timeZoneIds, ['UTC']);
    },
  );

  test(
    'latest activity request wins when replies arrive out of order',
    () async {
      await cubit.loadCustomers(_context());
      final old = cubit.loadCustomerActivity(_entity());
      final current = cubit.loadCustomerActivity(_entity());
      audit.requests[1].complete(Success([_log(id: 'new')]));
      await current;
      audit.requests[0].complete(Success([_log(id: 'old')]));
      await old;
      expect(
        (cubit.state as CustomersLoaded).selectedCustomerActivity.single.id,
        'new',
      );
    },
  );

  test('closing details ignores a pending audit result', () async {
    await cubit.loadCustomers(_context());
    final pending = cubit.loadCustomerActivity(_entity());
    cubit.clearCustomerActivity();
    audit.requests.single.complete(Success([_log()]));
    await pending;
    expect((cubit.state as CustomersLoaded).selectedCustomer, isNull);
    expect(converter.timeZoneIds, isEmpty);
  });

  test(
    'audit failure retains its typed code without invoking conversion',
    () async {
      await cubit.loadCustomers(_context());
      final pending = cubit.loadCustomerActivity(_entity());
      audit.requests.single.complete(
        const FailureResult(ServerFailure(code: FailureCodes.serverError)),
      );
      await pending;
      final state = cubit.state as CustomersLoaded;
      expect(state.activityFailure?.code, FailureCodes.serverError);
      expect(state.isActivityLoading, isFalse);
      expect(converter.timeZoneIds, isEmpty);
    },
  );

  test('foreign-company entity does not initiate an audit read', () async {
    await cubit.loadCustomers(_context());
    await cubit.loadCustomerActivity(_entity(companyId: 'company-2'));
    expect(audit.requests, isEmpty);
  });

  test(
    'closing details during projection does not restore the old selection',
    () async {
      await cubit.loadCustomers(_context());
      converter.onConvert = cubit.clearCustomerActivity;
      final pending = cubit.loadCustomerActivity(_entity());
      audit.requests.single.complete(Success([_log()]));
      await pending;
      final state = cubit.state as CustomersLoaded;
      expect(state.selectedCustomer, isNull);
      expect(state.activityTimestampFor('log-1'), isNull);
    },
  );

  test('closing cubit ignores a pending audit result', () async {
    await cubit.loadCustomers(_context());
    final pending = cubit.loadCustomerActivity(_entity());
    await cubit.close();
    audit.requests.single.complete(Success([_log()]));
    await pending;
    expect(converter.timeZoneIds, isEmpty);
  });
}

CurrentCompanyContext _context({
  String companyId = 'company-1',
  String timezone = 'Asia/Dubai',
}) => CurrentCompanyContext(
  company: Company(id: companyId, name: 'Company', businessTimezone: timezone),
  role: CompanyRole.owner,
);
Customer _entity({String companyId = 'company-1'}) =>
    Customer(id: 'entity-1', companyId: companyId, name: 'Customer');
AuditLog _log({String companyId = 'company-1', String id = 'log-1'}) =>
    AuditLog(
      id: id,
      companyId: companyId,
      module: AuditModule.customers,
      entityType: AuditEntityType.customer,
      entityId: 'entity-1',
      action: AuditAction.created,
      description: 'Created',
      createdAt: DateTime.utc(2026, 9, 6, 20, 30),
    );

final class _Repository implements CustomersRepository {
  @override
  Future<Result<List<Customer>>> getCustomers({
    required String companyId,
  }) async => const Success([]);

  @override
  Future<Result<Customer>> addCustomer({
    required CustomerWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Customer>> deactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Customer>> reactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) => throw UnimplementedError();
}
