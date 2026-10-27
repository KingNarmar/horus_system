import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/presentation/cubit/network_status_cubit.dart';
import '../../../../core/network/presentation/cubit/network_status_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/current_company_cubit.dart';

/// Owns membership observation and reconciliation across every app route.
///
/// Kept above the Navigator so a protected deep link cannot bypass session
/// validation, and route transitions cannot create duplicate subscriptions.
final class CompanySessionLifecycleBoundary extends StatefulWidget {
  final Widget child;

  const CompanySessionLifecycleBoundary({required this.child, super.key});

  @override
  State<CompanySessionLifecycleBoundary> createState() =>
      _CompanySessionLifecycleBoundaryState();
}

final class _CompanySessionLifecycleBoundaryState
    extends State<CompanySessionLifecycleBoundary>
    with WidgetsBindingObserver {
  late final CurrentCompanyCubit _companyCubit;
  String? _activeUserId;
  int? _sessionRevision;
  int _identityGeneration = 0;

  @override
  void initState() {
    super.initState();
    _companyCubit = context.read<CurrentCompanyCubit>();
    WidgetsBinding.instance.addObserver(this);
    _handleAuthState(context.read<AuthCubit>().state);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revalidate();
    }
  }

  void _handleAuthState(AuthState state) {
    if (state is AuthAuthenticated) {
      final userId = state.user.id;
      if (_activeUserId != userId) {
        _activeUserId = userId;
        _sessionRevision = state.sessionRevision;
        final generation = ++_identityGeneration;
        // Immediately hide any context belonging to the previous identity.
        final reset = _companyCubit.clearCurrentCompanyContext();
        unawaited(_activateIdentity(userId, generation, reset));
        return;
      }

      if (_sessionRevision != state.sessionRevision) {
        _sessionRevision = state.sessionRevision;
        _revalidate();
      }
      return;
    }

    if (_activeUserId == null) return;
    _activeUserId = null;
    _sessionRevision = null;
    ++_identityGeneration;
    unawaited(_companyCubit.stopWatchingMembership());
    unawaited(_companyCubit.clearCurrentCompanyContext());
  }

  Future<void> _activateIdentity(
    String userId,
    int generation,
    Future<void> reset,
  ) async {
    await _companyCubit.stopWatchingMembership();
    await reset;
    if (!_isActiveIdentity(userId, generation)) return;

    _companyCubit.startWatchingMembership(userId);
    await _companyCubit.loadCurrentCompanyContext();
  }

  bool _isActiveIdentity(String userId, int generation) =>
      mounted && _identityGeneration == generation && _activeUserId == userId;

  void _revalidate() {
    if (!mounted || _activeUserId == null) return;
    unawaited(_companyCubit.revalidateSelectedCompany());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeUserId = null;
    ++_identityGeneration;
    unawaited(_companyCubit.stopWatchingMembership());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (_, state) => _handleAuthState(state),
        ),
        BlocListener<NetworkStatusCubit, NetworkStatusState>(
          listenWhen: (previous, current) =>
              previous.reconnectRevision != current.reconnectRevision,
          listener: (_, _) => _revalidate(),
        ),
      ],
      child: widget.child,
    );
  }
}
