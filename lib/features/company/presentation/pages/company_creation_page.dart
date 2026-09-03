import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../cubit/company_onboarding_cubit.dart';
import '../cubit/company_onboarding_state.dart';
import '../cubit/company_timezone_cubit.dart';
import '../cubit/company_timezone_state.dart';
import '../cubit/current_company_cubit.dart';
import '../helpers/company_timezone_failure_message.dart';
import '../localization/company_timezone_localizations.dart';
import '../widgets/company_logout_button.dart';

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
  String? _selectedTimezone;

  @override
  void initState() {
    super.initState();
    context.read<CompanyOnboardingCubit>().loadMyCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timezoneL10n = context.companyTimezoneL10n;

    return BlocConsumer<CompanyOnboardingCubit, CompanyOnboardingState>(
      listener: (context, state) {
        if (state is CompanyOnboardingLoaded) {
          context.read<CurrentCompanyCubit>().loadCurrentCompanyContext();
        }

        if (state is CompanyOnboardingFailure) {
          final message = switch (state.failure.code) {
            CompanyFailureCodes.validationBusinessTimezoneRequired ||
            CompanyFailureCodes.validationBusinessTimezoneInvalid =>
              companyTimezoneFailureMessage(state.failure, timezoneL10n),
            _ => l10n.localizedErrorMessage(state.failure),
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state is CompanyOnboardingLoading ||
            state is CompanyOnboardingInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CompanyOnboardingLoaded) {
          return _CompanyLoadedView(companyName: state.activeCompany.name);
        }

        return BlocBuilder<CompanyTimezoneCubit, CompanyTimezoneState>(
          builder: (context, timezoneState) {
            return _CompanyCreationForm(
              formKey: _formKey,
              nameController: _nameController,
              businessTypeController: _businessTypeController,
              phoneController: _phoneController,
              emailController: _emailController,
              countryController: _countryController,
              cityController: _cityController,
              timezoneState: timezoneState,
              selectedTimezone: _selectedTimezone,
              onTimezoneChanged: (value) {
                setState(() => _selectedTimezone = value);
              },
              onRetryTimezones: () =>
                  context.read<CompanyTimezoneCubit>().loadOptions(),
              onSubmit: _submit,
            );
          },
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedTimezone = _selectedTimezone;
    if (selectedTimezone == null) return;

    context.read<CompanyOnboardingCubit>().createCompany(
      name: _nameController.text,
      businessTimezone: selectedTimezone,
      businessType: _businessTypeController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      country: _countryController.text,
      city: _cityController.text,
    );
  }
}

class _CompanyCreationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController businessTypeController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController countryController;
  final TextEditingController cityController;
  final CompanyTimezoneState timezoneState;
  final String? selectedTimezone;
  final ValueChanged<String?> onTimezoneChanged;
  final VoidCallback onRetryTimezones;
  final VoidCallback onSubmit;

  const _CompanyCreationForm({
    required this.formKey,
    required this.nameController,
    required this.businessTypeController,
    required this.phoneController,
    required this.emailController,
    required this.countryController,
    required this.cityController,
    required this.timezoneState,
    required this.selectedTimezone,
    required this.onTimezoneChanged,
    required this.onRetryTimezones,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          mobile: _CompanyCreationFormBody(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
            formKey: formKey,
            nameController: nameController,
            businessTypeController: businessTypeController,
            phoneController: phoneController,
            emailController: emailController,
            countryController: countryController,
            cityController: cityController,
            timezoneState: timezoneState,
            selectedTimezone: selectedTimezone,
            onTimezoneChanged: onTimezoneChanged,
            onRetryTimezones: onRetryTimezones,
            onSubmit: onSubmit,
          ),
          tablet: _CompanyCreationFormBody(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
            formKey: formKey,
            nameController: nameController,
            businessTypeController: businessTypeController,
            phoneController: phoneController,
            emailController: emailController,
            countryController: countryController,
            cityController: cityController,
            timezoneState: timezoneState,
            selectedTimezone: selectedTimezone,
            onTimezoneChanged: onTimezoneChanged,
            onRetryTimezones: onRetryTimezones,
            onSubmit: onSubmit,
          ),
          desktop: _CompanyCreationFormBody(
            maxWidth: AppSizes.desktopMaxContentWidth,
            horizontalPadding: AppSpacing.xxl,
            formKey: formKey,
            nameController: nameController,
            businessTypeController: businessTypeController,
            phoneController: phoneController,
            emailController: emailController,
            countryController: countryController,
            cityController: cityController,
            timezoneState: timezoneState,
            selectedTimezone: selectedTimezone,
            onTimezoneChanged: onTimezoneChanged,
            onRetryTimezones: onRetryTimezones,
            onSubmit: onSubmit,
          ),
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

    return DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.label,
        hintText: l10n.hint,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.value),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
      validator: (value) => value == null ? l10n.required : null,
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
