import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_cubit.dart';
import 'package:horus_system/core/network/presentation/widgets/global_network_gate.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  testWidgets('offline blocks child actions and online restores them', (
    tester,
  ) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    var actionCount = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        onAction: () => actionCount += 1,
      ),
    );
    await cubit.startWatching();

    repository.addStatus(NetworkConnectionStatus.offline);
    await tester.pump();

    expect(find.text(AppLocalizationsEn().networkOfflineTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('protected-action')), warnIfMissed: false);
    await tester.pump();
    expect(actionCount, 0);

    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pump();

    expect(find.text(AppLocalizationsEn().networkOfflineTitle), findsNothing);
    await tester.tap(find.byKey(const Key('protected-action')));
    await tester.pump();
    expect(actionCount, 1);
  });

  testWidgets('Arabic offline banner preserves RTL', (tester) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        locale: const Locale('ar'),
        onAction: () {},
      ),
    );
    await cubit.startWatching();
    repository.addStatus(NetworkConnectionStatus.offline);
    await tester.pump();

    final l10n = AppLocalizationsAr();
    expect(find.text(l10n.networkOfflineTitle), findsOneWidget);
    final context = tester.element(find.text(l10n.networkOfflineTitle));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}

NetworkStatusCubit _createCubit(NetworkStatusRepository repository) {
  return NetworkStatusCubit(
    getNetworkStatusUseCase: GetNetworkStatusUseCase(repository),
    watchNetworkStatusUseCase: WatchNetworkStatusUseCase(repository),
  );
}

class _TestApp extends StatelessWidget {
  final NetworkStatusCubit cubit;
  final Locale locale;
  final VoidCallback onAction;

  const _TestApp({
    required this.cubit,
    required this.onAction,
    this.locale = const Locale('en'),
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GlobalNetworkGate(
          child: Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('protected-action'),
                onPressed: onAction,
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ControllableNetworkStatusRepository
    implements NetworkStatusRepository {
  final _controller =
      StreamController<Result<NetworkConnectionStatus>>.broadcast();

  void addStatus(NetworkConnectionStatus status) {
    _controller.add(Success(status));
  }

  Future<void> close() => _controller.close();

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async {
    return const Success(NetworkConnectionStatus.online);
  }

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() => _controller.stream;
}
