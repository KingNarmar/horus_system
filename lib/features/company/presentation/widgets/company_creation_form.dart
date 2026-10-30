import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../cubit/company_timezone_state.dart';
import '../helpers/company_timezone_failure_message.dart';
import '../localization/company_timezone_localizations.dart';
import 'company_logout_button.dart';
import 'company_onboarding_financial_fields.dart';
import 'company_timezone_selector.dart';

class CompanyCreationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController businessTypeController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController countryController;
  final TextEditingController cityController;
  final TextEditingController invoicePrefixController;
  final String? selectedCurrency;
  final int? selectedFractionDigits;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onFractionDigitsChanged;
  final CompanyTimezoneState timezoneState;
  final String? selectedTimezone;
  final ValueChanged<String?> onTimezoneChanged;
  final VoidCallback onRetryTimezones;
  final VoidCallback onSubmit;

  const CompanyCreationForm({
    required this.formKey,
    required this.nameController,
    required this.businessTypeController,
    required this.phoneController,
    required this.emailController,
    required this.countryController,
    required this.cityController,
    required this.invoicePrefixController,
    required this.selectedCurrency,
    required this.selectedFractionDigits,
    required this.onCurrencyChanged,
    required this.onFractionDigitsChanged,
    required this.timezoneState,
    required this.selectedTimezone,
    required this.onTimezoneChanged,
    required this.onRetryTimezones,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Widget formBody(double maxWidth, double horizontalPadding) =>
        _CompanyCreationFormBody(
          maxWidth: maxWidth,
          horizontalPadding: horizontalPadding,
          formKey: formKey,
          nameController: nameController,
          businessTypeController: businessTypeController,
          phoneController: phoneController,
          emailController: emailController,
          countryController: countryController,
          cityController: cityController,
          invoicePrefixController: invoicePrefixController,
          selectedCurrency: selectedCurrency,
          selectedFractionDigits: selectedFractionDigits,
          onCurrencyChanged: onCurrencyChanged,
          onFractionDigitsChanged: onFractionDigitsChanged,
          timezoneState: timezoneState,
          selectedTimezone: selectedTimezone,
          onTimezoneChanged: onTimezoneChanged,
          onRetryTimezones: onRetryTimezones,
          onSubmit: onSubmit,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createCompanyTitle),
        actions: const [
          CompanyLogoutButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: formBody(AppSizes.mobileMaxContentWidth, AppSpacing.lg),
          tablet: formBody(AppSizes.tabletMaxContentWidth, AppSpacing.xl),
          desktop: formBody(AppSizes.desktopMaxContentWidth, AppSpacing.xxl),
        ),
      ),
    );
  }
}

class _CompanyCreationFormBody extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController businessTypeController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController countryController;
  final TextEditingController cityController;
  final TextEditingController invoicePrefixController;
  final String? selectedCurrency;
  final int? selectedFractionDigits;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onFractionDigitsChanged;
  final CompanyTimezoneState timezoneState;
  final String? selectedTimezone;
  final ValueChanged<String?> onTimezoneChanged;
  final VoidCallback onRetryTimezones;
  final VoidCallback onSubmit;

  const _CompanyCreationFormBody({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.formKey,
    required this.nameController,
    required this.businessTypeController,
    required this.phoneController,
    required this.emailController,
    required this.countryController,
    required this.cityController,
    required this.invoicePrefixController,
    required this.selectedCurrency,
    required this.selectedFractionDigits,
    required this.onCurrencyChanged,
    required this.onFractionDigitsChanged,
    required this.timezoneState,
    required this.selectedTimezone,
    required this.onTimezoneChanged,
    required this.onRetryTimezones,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.createCompanyFormTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.createCompanySubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.companyNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.companyNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _CompanyTimezoneField(
                  state: timezoneState,
                  selectedTimezone: selectedTimezone,
                  onChanged: onTimezoneChanged,
                  onRetry: onRetryTimezones,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: businessTypeController,
                  decoration: InputDecoration(
                    labelText: l10n.businessTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: countryController,
                  decoration: InputDecoration(
                    labelText: l10n.countryLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: l10n.cityLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                CompanyOnboardingFinancialFields(
                  selectedCurrency: selectedCurrency,
                  fractionDigits: selectedFractionDigits,
                  invoicePrefixController: invoicePrefixController,
                  onCurrencyChanged: onCurrencyChanged,
                  onFractionDigitsChanged: onFractionDigitsChanged,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: timezoneState.options.isNotEmpty ? onSubmit : null,
                  child: Text(l10n.createCompanyButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyTimezoneField extends StatelessWidget {
  final CompanyTimezoneState state;
  final String? selectedTimezone;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  const _CompanyTimezoneField({
    required this.state,
    required this.selectedTimezone,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyTimezoneL10n;

    if (state is CompanyTimezoneInitial || state is CompanyTimezoneLoading) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: AppSpacing.xl,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(l10n.loading)),
        ],
      );
    }

    if (state is CompanyTimezoneFailure && state.options.isEmpty) {
      final failure = (state as CompanyTimezoneFailure).failure;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(companyTimezoneFailureMessage(failure, l10n)),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      );
    }

    final options = state.options;
    final effectiveValue =
        options.any((option) => option.value == selectedTimezone)
        ? selectedTimezone
        : null;

    return CompanyTimezoneSelector(
      options: options,
      selectedValue: effectiveValue,
      onChanged: onChanged,
      validator: (value) => value == null ? l10n.required : null,
    );
  }
}
