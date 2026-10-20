import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/entities/company_invalidation_resource.dart';
import 'package:horus_system/core/realtime/domain/repositories/company_data_changes_repository.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/realtime/presentation/cubit/company_realtime_cubit.dart';
import 'package:horus_system/core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import 'package:horus_system/core/utils/result.dart';

void main() {
  testWidgets('only visible matching resources trigger a refresh', (
    tester,
  ) async {
    final repository = _ChangeRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    cubit.watchCompany('company-a');

    var calls = 0;
    Widget boundary(Set<CompanyInvalidationResource> resources) {
      return BlocProvider<CompanyRealtimeCubit>.value(
        value: cubit,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CompanyResourceInvalidationBoundary(
            companyId: 'company-a',
            resources: resources,
            onInvalidate: (_) async {
              calls++;
            },
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      boundary(const {CompanyInvalidationResource.customers}),
    );
    repository.send('company-a', CompanyDataResource.customers);
    await tester.pump();
    expect(calls, 1);

    await tester.pumpWidget(
      boundary(const {CompanyInvalidationResource.payments}),
    );
    repository.send('company-a', CompanyDataResource.customers);
    await tester.pump();
    expect(calls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    repository.send('company-a', CompanyDataResource.customers);
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('old company events cannot refresh a new company view', (
    tester,
  ) async {
    final repository = _ChangeRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    var calls = 0;
    Widget boundary(String companyId) =>
        BlocProvider<CompanyRealtimeCubit>.value(
          value: cubit,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CompanyResourceInvalidationBoundary(
              companyId: companyId,
              resources: const {CompanyInvalidationResource.customers},
              onInvalidate: (_) async {
                calls++;
              },
              child: const SizedBox.shrink(),
            ),
          ),
        );

    cubit.watchCompany('company-a');
    await tester.pumpWidget(boundary('company-a'));
    cubit.watchCompany('company-b');
    await tester.pumpWidget(boundary('company-b'));

    repository.send('company-a', CompanyDataResource.customers);
    await tester.pump();
    expect(calls, 0);

    repository.send('company-b', CompanyDataResource.customers);
    await tester.pump();
    expect(calls, 1);
  });
}

final class _ChangeRepository implements CompanyDataChangesRepository {
  final Map<String, StreamController<Result<CompanyDataChange>>> _controllers =
      {};

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    final controller = StreamController<Result<CompanyDataChange>>.broadcast(
      sync: true,
    );
    _controllers[companyId] = controller;
    return controller.stream;
  }

  void send(String companyId, CompanyDataResource resource) {
    _controllers[companyId]!.add(
      Success(CompanyDataChange(companyId: companyId, resource: resource)),
    );
  }

  Future<void> close() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }
}
