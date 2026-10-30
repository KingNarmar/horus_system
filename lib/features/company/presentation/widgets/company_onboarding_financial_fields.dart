import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_financial_configuration.dart';
import '../helpers/company_currency_display_option.dart';
import '../localization/company_financial_settings_localizations.dart';
import '../localization/company_onboarding_localizations.dart';
import 'company_currency_selector.dart';

/// User-selected required financial foundations for a new tenant.
final class CompanyOnboardingFinancialFields extends StatelessWidget {
  final String? selectedCurrency;
  final int? fractionDigits;
  final TextEditingController invoicePrefixController;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onFractionDigitsChanged;

  const CompanyOnboardingFinancialFields({
    required this.selectedCurrency,
    required this.fractionDigits,
    required this.invoicePrefixController,
    required this.onCurrencyChanged,
    required this.onFractionDigitsChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyOnboardingL10n;
    final financialL10n = context.companyFinancialSettingsL10n;
    final options = CompanyCurrencyDisplayResolver.resolveAll(
      Localizations.localeOf(context),
      includeCurrencyCode: selectedCurrency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.financialSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        FormField<String>(
          key: ValueKey(selectedCurrency),
          initialValue: selectedCurrency,
          validator: (value) => value == null ? l10n.currencyRequired : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanyCurrencySelector(
                options: options,
                selectedValue: selectedCurrency,
                onChanged: (value) {
                  field.didChange(value);
                  onCurrencyChanged(value);
                },
              ),
              if (field.errorText case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    error,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          initialValue: fractionDigits,
          decoration: InputDecoration(
            labelText: financialL10n.fractionDigitsLabel,
            border: const OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null ? l10n.fractionDigitsRequired : null,
          items: [
            for (
              var digits = CompanyFinancialConfiguration.minFractionDigits;
              digits <= CompanyFinancialConfiguration.maxFractionDigits;
              digits++
            )
              DropdownMenuItem<int>(value: digits, child: Text('$digits')),
          ],
          onChanged: onFractionDigitsChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.invoiceSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: invoicePrefixController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: l10n.invoicePrefixLabel,
            hintText: l10n.invoicePrefixHint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? l10n.invoicePrefixRequired
              : null,
        ),
      ],
    );
  }
}
