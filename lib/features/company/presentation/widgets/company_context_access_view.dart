import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/current_company_context.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import '../pages/company_entry_page.dart';

/// Presents the same authoritative access states for root and deep-link routes.
///
/// A successful same-role revalidation keeps the protected subtree mounted;
/// a changed role recreates it so old role-specific state cannot be reused.
final class CompanyContextAccessView extends StatefulWidget {
  final Widget Function(CurrentCompanyContext) builder;

  const CompanyContextAccessView({required this.builder, super.key});

  @override
  State<CompanyContextAccessView> createState() =>
      _CompanyContextAccessViewState();
}

final class _CompanyContextAccessViewState
    extends State<CompanyContextAccessView> {
  @override
  void initState() {
    super.initState();
    // Also supports isolated route mounting in tests and nested navigation.
    // The app-level session boundary normally initiates the initial load.
    final cubit = context.read<CurrentCompanyCubit>();
    final state = cubit.state;
    if (state is CurrentCompanyInitial || state is CurrentCompanyEmpty) {
      unawaited(cubit.loadCurrentCompanyContext());
    }
  }

  void _retry() {
    unawaited(context.read<CurrentCompanyCubit>().revalidateSelectedCompany());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CurrentCompanyCubit, CurrentCompanyState>(
      builder: (context, state) {
        if (state is CurrentCompanyInitial || state is CurrentCompanyLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CurrentCompanyEmpty) {
          return const CompanyEntryPage();
        }

        if (state is CurrentCompanyLoaded ||
            state is CurrentCompanyVerifying) {
          final verifying = state is CurrentCompanyVerifying;
          final companyContext = state is CurrentCompanyLoaded
              ? state.context
              : (state as CurrentCompanyVerifying).context;

          return Stack(
            children: [
              ExcludeSemantics(
                excluding: verifying,
                child: ExcludeFocus(
                  excluding: verifying,
                  child: AbsorbPointer(
                    absorbing: verifying,
                    child: KeyedSubtree(
                      key: ValueKey((
                        companyContext.companyId,
                        companyContext.role,
                      )),
                      child: widget.builder(companyContext),
                    ),
                  ),
                ),
              ),
              if (verifying)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const Center(child: CircularProgressIndicator()),
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
                      onPressed: _retry,
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
    );
  }
}
