import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../cubit/company_onboarding_cubit.dart';
import '../cubit/company_onboarding_state.dart';
import '../cubit/current_company_cubit.dart';
import '../widgets/company_logout_button.dart';

class CompanyOnboardingPage extends StatefulWidget {
  const CompanyOnboardingPage({super.key});

  @override
  State<CompanyOnboardingPage> createState() => _CompanyOnboardingPageState();
}

class _CompanyOnboardingPageState extends State<CompanyOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

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
    return BlocConsumer<CompanyOnboardingCubit, CompanyOnboardingState>(
      listener: (context, state) {
        if (state is CompanyOnboardingLoaded) {
          context.read<CurrentCompanyCubit>().loadCurrentCompanyContext();
        }

        if (state is CompanyOnboardingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.failure.message)),
          );
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

        return _CompanyOnboardingForm(
          formKey: _formKey,
          nameController: _nameController,
          businessTypeController: _businessTypeController,
          phoneController: _phoneController,
          emailController: _emailController,
          countryController: _countryController,
          cityController: _cityController,
          onSubmit: _submit,
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<CompanyOnboardingCubit>().createCompany(
          name: _nameController.text,
          businessType: _businessTypeController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          country: _countryController.text,
          city: _cityController.text,
        );
  }
}

class _CompanyOnboardingForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController businessTypeController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController countryController;
  final TextEditingController cityController;
  final VoidCallback onSubmit;

  const _CompanyOnboardingForm({
    required this.formKey,
    required this.nameController,
    required this.businessTypeController,
    required this.phoneController,
    required this.emailController,
    required this.countryController,
    required this.cityController,
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
          mobile: _CompanyOnboardingFormBody(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
            formKey: formKey,
            nameController: nameController,
            businessTypeController: businessTypeController,
            phoneController: phoneController,
            emailController: emailController,
            countryController: countryController,
            cityController: cityController,
            onSubmit: onSubmit,
          ),
          tablet: _CompanyOnboardingFormBody(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
            formKey: formKey,
            nameController: nameController,
            businessTypeController: businessTypeController,
            phoneController: phoneController,
            emailController: emailController,
            countryController: countryController,
            cityController: cityController,
            onSubmit: onSubmit,
          ),
          desktop: _CompanyOnboardingFormBody(
            maxWidth: AppSizes.desktopMaxContentWidth,
            horizontalPadding: AppSpacing.xxl,
            formKey: formKey,
            nameController: nameController,
            businessTypeController: businessTypeController,
            phoneController: phoneController,
            emailController: emailController,
            countryController: countryController,
            cityController: cityController,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }
}

class _CompanyOnboardingFormBody extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController businessTypeController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController countryController;
  final TextEditingController cityController;
  final VoidCallback onSubmit;

  const _CompanyOnboardingFormBody({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.formKey,
    required this.nameController,
    required this.businessTypeController,
    required this.phoneController,
    required this.emailController,
    required this.countryController,
    required this.cityController,
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
                  onPressed: onSubmit,
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
