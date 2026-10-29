import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/entities/company_invalidation_resource.dart';
import 'package:horus_system/core/realtime/domain/repositories/company_data_changes_repository.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/realtime/presentation/cubit/company_realtime_cubit.dart';
import 'package:horus_system/core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/app_shell/presentation/widgets/company_realtime_session_boundary.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';

void main() {
  testWidgets('stacked company shell routes must share one Realtime session', (
    tester,
  ) async {
    final repository = _WatchingRepository();
    addTearDown(repository.close);
    final changes = WatchCompanyDataChangesUseCase(repository);

    Widget shell(String label) => CompanyRealtimeSessionBoundary(
      companyId: 'company-a',
      role: CompanyRole.admin,
      userId: 'fixture-user',
      realtimeCubitFactory: () =>
          CompanyRealtimeCubit(watchChanges: changes),
      child: CompanyResourceInvalidationBoundary(
        companyId: 'company-a',
        resources: const {CompanyInvalidationResource.customers},
        onInvalidate: (_) async {},
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => shell('nested')),
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(MaterialApp(home: shell('root')));
    await tester.pump();
    expect(repository.watched, ['company-a']);

    await tester.tap(find.text('root'));
    await tester.pumpAndSettle();

    // This must fail against the current route-owned Realtime provider:
    // the Navigator keeps both shell routes mounted during transitions.
    expect(repository.watched, ['company-a']);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final class _WatchingRepository implements CompanyDataChangesRepository {
  final watched = <String>[];
  final controllers = <StreamController<Result<CompanyDataChange>>>[];

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    final controller = StreamController<Result<CompanyDataChange>>(
      onListen: () => watched.add(companyId),
    );
    controllers.add(controller);
    return controller.stream;
  }

  Future<void> close() async {
    for (final controller in controllers) {
      await controller.close();
    }
  }
}
