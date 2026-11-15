import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/company_brand_logo_file.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../../domain/failures/company_branding_failure_codes.dart';
import '../cubit/company_branding_cubit.dart';
import '../helpers/company_brand_logo_file_picker.dart';
import '../localization/company_branding_localizations.dart';
import '../cubit/company_onboarding_cubit.dart';
import '../cubit/company_onboarding_state.dart';
import '../cubit/company_timezone_cubit.dart';
import '../cubit/company_timezone_state.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import '../helpers/company_timezone_failure_message.dart';
import '../localization/company_timezone_localizations.dart';
import '../localization/company_onboarding_localizations.dart';
import '../widgets/company_creation_form.dart';

class CompanyCreationPage extends StatefulWidget {
  const CompanyCreationPage({super.key});

  @override
  State<CompanyCreationPage> createState() => _CompanyCreationPageState();
}

class _CompanyCreationPageState extends State<CompanyCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _invoicePrefixController = TextEditingController();
  String? _selectedCurrency;
  int? _selectedFractionDigits;
  String? _selectedTimezone;
  String? _contextSyncErrorMessage;
  String? _logoUploadErrorMessage;
  String? _logoUploadFailureCode;
  bool _logoUploadInFlight = false;
  CompanyBrandLogoFile? _selectedLogo;
  final _logoPicker = const CompanyBrandLogoFilePicker();

  @override
  void initState() {
    super.initState();
    context.read<CompanyOnboardingCubit>().prepareForCreation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _invoicePrefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timezoneL10n = context.companyTimezoneL10n;
    final onboardingL10n = context.companyOnboardingL10n;

    return BlocConsumer<CompanyOnboardingCubit, CompanyOnboardingState>(
      listener: (context, state) async {
        if (state is CompanyOnboardingCreated) {
          await _completeCreatedCompany(state.company);
          return;
        }

        if (state is CompanyOnboardingFailure) {
          final message = switch (state.failure.code) {
            CompanyFailureCodes.validationBusinessTimezoneRequired ||
            CompanyFailureCodes.validationBusinessTimezoneInvalid =>
              companyTimezoneFailureMessage(state.failure, timezoneL10n),
            CompanyFailureCodes.validationBaseCurrencyInvalid =>
              onboardingL10n.currencyInvalid,
            CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid =>
              onboardingL10n.fractionDigitsInvalid,
            CompanyFailureCodes.validationInvoicePrefixInvalid =>
              onboardingL10n.invoicePrefixInvalid,
            CompanyFailureCodes.creationLimitReached =>
              onboardingL10n.creationLimitReached,
            CompanyFailureCodes.creationRequestConflict =>
              onboardingL10n.creationRequestConflict,
            CompanyFailureCodes.creationRetryUnavailable =>
              onboardingL10n.creationRetryUnavailable,
            CompanyFailureCodes.creationLocalRetryUnavailable =>
              onboardingL10n.creationLocalRetryUnavailable,
            _ => l10n.localizedErrorMessage(state.failure),
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state is CompanyOnboardingCreated &&
            _logoUploadErrorMessage != null) {
          final brandingL10n = context.companyBrandingL10n;
          final mustVerify = _logoUploadFailureCode ==
                  CompanyBrandingFailureCodes.uploadCompletionUnknown ||
              _logoUploadFailureCode ==
                  CompanyBrandingFailureCodes.uploadCleanupPending;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.appTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mustVerify
                          ? brandingL10n.createLogoReview
                          : brandingL10n.createLogoRecovery,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(_logoUploadErrorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.lg),
                    if (!mustVerify) ...[
                      OutlinedButton(
                        onPressed: () => _uploadCreatedCompanyLogo(state.company),
                        child: Text(brandingL10n.uploadRetry),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    FilledButton(
                      onPressed: () => _openCreatedCompany(state.company.id),
                      child: Text(
                        mustVerify
                            ? brandingL10n.continueToCompany
                            : brandingL10n.continueWithoutLogo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is CompanyOnboardingCreated &&
            _contextSyncErrorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.appTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _contextSyncErrorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () async {
                        setState(() => _contextSyncErrorMessage = null);
                        await _openCreatedCompany(state.company.id);
                      },
                      child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is CompanyOnboardingLoading ||
            state is CompanyOnboardingInitial ||
            state is CompanyOnboardingCreated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CompanyOnboardingLoaded) {
          return _CompanyLoadedView(companyName: state.activeCompany.name);
        }

        return BlocBuilder<CompanyTimezoneCubit, CompanyTimezoneState>(
          builder: (context, timezoneState) {
            return CompanyCreationForm(
              formKey: _formKey,
              nameController: _nameController,
              businessTypeController: _businessTypeController,
              phoneController: _phoneController,
              emailController: _emailController,
              countryController: _countryController,
              cityController: _cityController,
              invoicePrefixController: _invoicePrefixController,
              selectedCurrency: _selectedCurrency,
              selectedFractionDigits: _selectedFractionDigits,
              onCurrencyChanged: (value) =>
                  setState(() => _selectedCurrency = value),
              onFractionDigitsChanged: (value) =>
                  setState(() => _selectedFractionDigits = value),
              timezoneState: timezoneState,
              selectedTimezone: _selectedTimezone,
              onTimezoneChanged: (value) {
                setState(() => _selectedTimezone = value);
              },
              onRetryTimezones: () =>
                  context.read<CompanyTimezoneCubit>().loadOptions(),
              onSubmit: _submit,
              selectedLogoBytes: _selectedLogo?.bytes,
              onChooseLogo: _chooseLogo,
              onRemoveLogo: () => setState(() => _selectedLogo = null),
            );
          },
        );
      },
    );
  }

  Future<void> _chooseLogo() async {
    try {
      final selected = await _logoPicker.pick();
      if (!mounted || selected == null) return;
      final result = await context
          .read<CompanyBrandingCubit>()
          .validateSelection(selected);
      if (!mounted) return;
      final failure = result.failureOrNull;
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.companyBrandingL10n.errorMessage(failure)),
          ),
        );
        return;
      }
      setState(() => _selectedLogo = result.dataOrNull);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.companyBrandingL10n.imageReadFailed)),
      );
    }
  }

  Future<void> _completeCreatedCompany(Company company) async {
    if (_selectedLogo == null) {
      await _openCreatedCompany(company.id);
      return;
    }
    await _uploadCreatedCompanyLogo(company);
  }

  Future<void> _uploadCreatedCompanyLogo(Company company) async {
    if (_logoUploadInFlight) return;
    final logo = _selectedLogo;
    if (logo == null) {
      await _openCreatedCompany(company.id);
      return;
    }
    setState(() {
      _logoUploadInFlight = true;
      _logoUploadErrorMessage = null;
      _logoUploadFailureCode = null;
    });
    final result = await context.read<CompanyBrandingCubit>().uploadLogo(
      companyContext: CurrentCompanyContext(
        company: company,
        role: CompanyRole.owner,
      ),
      logo: logo,
    );
    if (!mounted) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      setState(() {
        _logoUploadInFlight = false;
        _logoUploadFailureCode = failure.code;
        _logoUploadErrorMessage =
            context.companyBrandingL10n.errorMessage(failure);
      });
      return;
    }

    _logoUploadInFlight = false;
    _selectedLogo = null;
    await _openCreatedCompany(company.id);
  }

  Future<void> _openCreatedCompany(String companyId) async {
    final currentCompanyCubit = context.read<CurrentCompanyCubit>();
    await currentCompanyCubit.refreshAndSelectCompany(companyId);
    if (!mounted) return;

    final currentCompanyState = currentCompanyCubit.state;
    if (currentCompanyState is CurrentCompanyLoaded &&
        currentCompanyState.context.companyId == companyId) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.appShell, (route) => false);
      return;
    }

    final message = currentCompanyState is CurrentCompanyFailure
        ? context.l10n.localizedErrorMessage(currentCompanyState.failure)
        : context.l10n.currentCompanyContextRequired;
    setState(() => _contextSyncErrorMessage = message);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedTimezone = _selectedTimezone;
    final selectedCurrency = _selectedCurrency;
    final selectedDigits = _selectedFractionDigits;
    if (selectedTimezone == null ||
        selectedCurrency == null ||
        selectedDigits == null) {
      return;
    }

    context.read<CompanyOnboardingCubit>().createCompany(
      name: _nameController.text,
      businessTimezone: selectedTimezone,
      baseCurrencyCode: selectedCurrency,
      baseCurrencyFractionDigits: selectedDigits,
      invoicePrefix: _invoicePrefixController.text,
      businessType: _businessTypeController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      country: _countryController.text,
      city: _cityController.text,
    );
  }
}

class _CompanyLoadedView extends StatelessWidget {
  final String companyName;

  const _CompanyLoadedView({required this.companyName});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.companyContextLoadedTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                companyName,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.companyContextNextStep,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
