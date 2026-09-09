import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_financial_configuration.dart';
import '../../domain/entities/company_financial_readiness.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/policies/company_financial_readiness_policy.dart';
import '../cubit/company_financial_settings_cubit.dart';
import '../cubit/company_financial_settings_state.dart';
import '../cubit/current_company_cubit.dart';
import '../helpers/company_financial_settings_failure_message.dart';
import '../localization/company_financial_settings_localizations.dart';

final class CompanyFinancialSettingsCard extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const CompanyFinancialSettingsCard({
    required this.currentCompanyContext,
    super.key,
  });

  @override
  State<CompanyFinancialSettingsCard> createState() =>
      _CompanyFinancialSettingsCardState();
}

final class _CompanyFinancialSettingsCardState
    extends State<CompanyFinancialSettingsCard> {
  late final TextEditingController _currencyController;
  int? _fractionDigits;

  @override
  void initState() {
    super.initState();
    _currencyController = TextEditingController(
      text: widget.currentCompanyContext.company.baseCurrencyCode ?? '',
    );
    _fractionDigits =
        widget.currentCompanyContext.company.baseCurrencyFractionDigits;
  }

  @override
  void didUpdateWidget(covariant CompanyFinancialSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCompany = oldWidget.currentCompanyContext.company;
    final company = widget.currentCompanyContext.company;
    if (oldCompany.baseCurrencyCode != company.baseCurrencyCode) {
      _currencyController.text = company.baseCurrencyCode ?? '';
    }
    if (oldCompany.baseCurrencyFractionDigits !=
        company.baseCurrencyFractionDigits) {
      _fractionDigits = company.baseCurrencyFractionDigits;
    }
  }

  @override
  void dispose() {
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyFinancialSettingsL10n;
    final textTheme = Theme.of(context).textTheme;
    final readiness = CompanyFinancialReadinessPolicy.evaluate(
      widget.currentCompanyContext.company,
    );
    final canManage = widget.currentCompanyContext.canManageCompany;

    return BlocConsumer<
      CompanyFinancialSettingsCubit,
      CompanyFinancialSettingsState
    >(
      listener: (context, state) async {
        if (state is CompanyFinancialSettingsSaved) {
          await context.read<CurrentCompanyCubit>().refreshAndSelectCompany(
            widget.currentCompanyContext.companyId,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.saved)));
          return;
        }

        if (state is CompanyFinancialSettingsFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                companyFinancialSettingsFailureMessage(state.failure, l10n),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state is CompanyFinancialSettingsSaving;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.description),
                const SizedBox(height: AppSpacing.md),
                Text(_readinessMessage(readiness, l10n)),
                if (readiness.configuration case final configuration?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.currentValue(
                      configuration.baseCurrency.value,
                      configuration.fractionDigits,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  readiness.status ==
                          CompanyFinancialReadinessStatus.configurationRequired
                      ? l10n.initialSetupNotice
                      : l10n.lockNotice,
                ),
                if (canManage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _currencyController,
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    decoration: InputDecoration(
                      labelText: l10n.baseCurrencyLabel,
                      hintText: l10n.baseCurrencyHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    initialValue: _fractionDigits,
                    decoration: InputDecoration(
                      labelText: l10n.fractionDigitsLabel,
                    ),
                    items: [
                      for (
                        var digits =
                            CompanyFinancialConfiguration.minFractionDigits;
                        digits <=
                            CompanyFinancialConfiguration.maxFractionDigits;
                        digits++
                      )
                        DropdownMenuItem<int>(
                          value: digits,
                          child: Text('$digits'),
                        ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) => setState(() => _fractionDigits = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: !isSaving && _hasChange()
                        ? () => _save(context)
                        : null,
                    child: Text(isSaving ? l10n.saving : l10n.save),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.permissionNotice),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _readinessMessage(
    CompanyFinancialReadiness readiness,
    CompanyFinancialSettingsLocalizations l10n,
  ) {
    return switch (readiness.status) {
      CompanyFinancialReadinessStatus.ready => l10n.ready,
      CompanyFinancialReadinessStatus.configurationRequired =>
        l10n.configurationRequired,
      CompanyFinancialReadinessStatus.invalidConfiguration =>
        l10n.invalidConfiguration,
    };
  }

  bool _hasChange() {
    final code = _currencyController.text.trim().toUpperCase();
    final digits = _fractionDigits;
    if (code.isEmpty || digits == null) return false;

    final company = widget.currentCompanyContext.company;
    return code != company.baseCurrencyCode ||
        digits != company.baseCurrencyFractionDigits;
  }

  void _save(BuildContext context) {
    final digits = _fractionDigits;
    if (digits == null) return;

    context.read<CompanyFinancialSettingsCubit>().update(
      currentCompanyContext: widget.currentCompanyContext,
      baseCurrencyCode: _currencyController.text,
      baseCurrencyFractionDigits: digits,
    );
  }
}
