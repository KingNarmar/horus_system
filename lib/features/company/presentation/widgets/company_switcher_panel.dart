import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/current_company_context.dart';
import '../cubit/company_switcher_cubit.dart';
import '../cubit/company_switcher_state.dart';
import '../cubit/current_company_cubit.dart';
import '../extensions/company_failure_localization.dart';
import '../extensions/company_role_localization.dart';

/// Tenant-safe membership picker shared by the active shell and company entry.
///
/// Selection always uses CurrentCompanyCubit's authoritative switch operation;
/// the displayed list is never treated as an authorization decision.
final class CompanySwitcherPanel extends StatefulWidget {
  final String? activeCompanyId;
  final VoidCallback? onJoin;
  final VoidCallback? onSwitchSucceeded;

  const CompanySwitcherPanel({
    required this.activeCompanyId,
    this.onJoin,
    this.onSwitchSucceeded,
    super.key,
  });

  @override
  State<CompanySwitcherPanel> createState() => _CompanySwitcherPanelState();
}

final class _CompanySwitcherPanelState extends State<CompanySwitcherPanel> {
  String? _pendingCompanyId;
  Failure? _switchFailure;

  Future<void> _select(CurrentCompanyContext company) async {
    if (_pendingCompanyId != null) return;
    if (company.companyId == widget.activeCompanyId) {
      widget.onSwitchSucceeded?.call();
      return;
    }

    setState(() {
      _pendingCompanyId = company.companyId;
      _switchFailure = null;
    });

    final result = await context
        .read<CurrentCompanyCubit>()
        .switchActiveCompany(company.companyId);
    if (!mounted) return;

    final failure = result.failureOrNull;
    if (failure == null) {
      widget.onSwitchSucceeded?.call();
      return;
    }

    setState(() {
      _pendingCompanyId = null;
      _switchFailure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CompanySwitcherCubit, CompanySwitcherState>(
      builder: (context, state) {
        final busy = _pendingCompanyId != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.companySwitcherTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state is CompanySwitcherLoading ||
                state is CompanySwitcherInitial)
              const Center(child: CircularProgressIndicator())
            else if (state is CompanySwitcherFailure) ...[
              Text(CompanyFailureLocalizationX(l10n).localizedErrorMessage(state.failure)),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : context.read<CompanySwitcherCubit>().load,
                icon: const Icon(AppIcons.resend),
                label: Text(l10n.retryButton),
              ),
            ] else if (state is CompanySwitcherLoaded) ...[
              if (state.companies.isEmpty)
                Text(l10n.companySwitcherEmpty)
              else
                ...state.companies.map(
                  (company) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: !busy,
                    title: Text(company.company.name),
                    subtitle: Text(company.role.localizedLabel(context)),
                    leading: Icon(
                      company.companyId == widget.activeCompanyId
                          ? AppIcons.reactivate
                          : AppIcons.customers,
                    ),
                    trailing: _pendingCompanyId == company.companyId
                        ? const CircularProgressIndicator()
                        : company.companyId == widget.activeCompanyId
                        ? Text(l10n.companySwitcherCurrent)
                        : null,
                    onTap: () => _select(company),
                  ),
                ),
            ],
            if (_switchFailure != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(CompanyFailureLocalizationX(l10n).localizedErrorMessage(_switchFailure!)),
            ],
            if (widget.onJoin != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: busy ? null : widget.onJoin,
                icon: const Icon(AppIcons.invitations),
                label: Text(l10n.companySwitcherJoin),
              ),
            ],
          ],
        );
      },
    );
  }
}
