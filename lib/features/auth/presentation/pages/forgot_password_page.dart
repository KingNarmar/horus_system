import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/validators/app_validators.dart';
import '../cubit/password_recovery_cubit.dart';
import '../cubit/password_recovery_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<PasswordRecoveryCubit>().requestRecovery(
      email: _emailController.text,
    );
  }

  void _backToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _ForgotPasswordLayout(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
            formKey: _formKey,
            emailController: _emailController,
            onSubmit: _submit,
            onBackToLogin: _backToLogin,
          ),
          tablet: _ForgotPasswordLayout(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
            formKey: _formKey,
            emailController: _emailController,
            onSubmit: _submit,
            onBackToLogin: _backToLogin,
          ),
          desktop: _ForgotPasswordLayout(
            maxWidth: AppSizes.desktopAuthFormMaxWidth,
            horizontalPadding: AppSpacing.xxl,
            formKey: _formKey,
            emailController: _emailController,
            onSubmit: _submit,
            onBackToLogin: _backToLogin,
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordLayout extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final VoidCallback onSubmit;
  final VoidCallback onBackToLogin;

  const _ForgotPasswordLayout({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.formKey,
    required this.emailController,
    required this.onSubmit,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: BlocConsumer<PasswordRecoveryCubit, PasswordRecoveryState>(
            listener: (context, state) {
              if (state is PasswordRecoveryFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.localizedErrorMessage(state.failure)),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is PasswordRecoverySubmitted) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          AppIcons.invitationSent,
                          size: AppSizes.iconXl,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.checkYourEmailTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.passwordRecoverySuccessMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          onPressed: onBackToLogin,
                          icon: const Icon(AppIcons.login),
                          label: Text(l10n.backToLoginButton),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final isSubmitting = state is PasswordRecoverySubmitting;

              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.forgotPasswordTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.forgotPasswordSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) =>
                          isSubmitting ? null : onSubmit(),
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(AppIcons.email),
                      ),
                      validator: (value) {
                        if (!AppValidators.hasRequiredText(value)) {
                          return l10n.emailRequired;
                        }

                        if (!AppValidators.hasValidEmail(value)) {
                          return l10n.failureAuthInvalidEmail;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: isSubmitting ? null : onSubmit,
                      child: isSubmitting
                          ? const SizedBox(
                              width: AppSizes.loadingIndicatorSm,
                              height: AppSizes.loadingIndicatorSm,
                              child: CircularProgressIndicator(
                                strokeWidth:
                                    AppSizes.loadingIndicatorStrokeWidth,
                              ),
                            )
                          : Text(l10n.sendPasswordRecoveryButton),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: isSubmitting ? null : onBackToLogin,
                      child: Text(l10n.backToLoginButton),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
