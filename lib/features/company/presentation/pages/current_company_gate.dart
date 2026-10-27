import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/network/presentation/cubit/network_status_cubit.dart';
import '../../../../core/network/presentation/cubit/network_status_state.dart';
import '../../../app_shell/presentation/pages/app_shell_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import 'company_entry_page.dart';

class CurrentCompanyGate extends StatefulWidget {
  const CurrentCompanyGate({super.key});

  @override
  State<CurrentCompanyGate> createState() => _CurrentCompanyGateState();
}

class _CurrentCompanyGateState extends State<CurrentCompanyGate>
    with WidgetsBindingObserver {
  late final CurrentCompanyCubit _companyCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _companyCubit = context.read<CurrentCompanyCubit>();
    unawaited(_companyCubit.loadCurrentCompanyContext());
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      _companyCubit.startWatchingMembership(auth.user.id);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revalidate();
    }
  }

  void _revalidate() {
    if (!mounted) return;
    unawaited(_companyCubit.revalidateSelectedCompany());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_companyCubit.stopWatchingMembership());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<NetworkStatusCubit, NetworkStatusState>(
      listenWhen: (previous, current) =>
          previous.reconnectRevision != current.reconnectRevision,
      listener: (_, _) => _revalidate(),
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous is AuthAuthenticated &&
            current is AuthAuthenticated &&
            previous.user.id == current.user.id &&
            previous.sessionRevision != current.sessionRevision,
        listener: (_, _) => _revalidate(),
        child: BlocBuilder<CurrentCompanyCubit, CurrentCompanyState>(
          builder: (context, state) {
            if (state is CurrentCompanyLoading ||
                state is CurrentCompanyInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is CurrentCompanyEmpty) {
              return const CompanyEntryPage();
            }

            if (state is CurrentCompanyLoaded ||
                state is CurrentCompanyVerifying) {
              final companyContext = state is CurrentCompanyLoaded
                  ? state.context
                  : (state as CurrentCompanyVerifying).context;
              return Stack(
                children: [
                  AppShellPage(currentCompanyContext: companyContext),
                  if (state is CurrentCompanyVerifying)
                    Positioned.fill(
                      child: AbsorbPointer(
                        child: ColoredBox(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            if (state is CurrentCompanyFailure) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.localizedErrorMessage(state.failure),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _revalidate,
                          icon: const Icon(AppIcons.resend),
                          label: Text(l10n.retryButton),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const CompanyEntryPage();
          },
        ),
      ),
    );
  }
}
