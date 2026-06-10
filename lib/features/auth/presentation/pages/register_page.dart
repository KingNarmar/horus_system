import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthCubit>().register(
          fullName: _fullNameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.createAccountTitle)),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _RegisterLayout(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
            formKey: _formKey,
            fullNameController: _fullNameController,
            phoneController: _phoneController,
            emailController: _emailController,
            passwordController: _passwordController,
            onSubmit: _submit,
          ),
          tablet: _RegisterLayout(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
            formKey: _formKey,
            fullNameController: _fullNameController,
            phoneController: _phoneController,
            emailController: _emailController,
            passwordController: _passwordController,
            onSubmit: _submit,
          ),
          desktop: _RegisterLayout(
            maxWidth: 520,
            horizontalPadding: AppSpacing.xxl,
            formKey: _formKey,
            fullNameController: _fullNameController,
            phoneController: _phoneController,
            emailController: _emailController,
            passwordController: _passwordController,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _RegisterLayout extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const _RegisterLayout({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
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
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthFailureState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.failure.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is AuthEmailConfirmationRequired) {
                return _EmailConfirmationRequiredView(
                  email: state.email,
                  onBackToLogin: () => Navigator.of(context).pop(),
                );
              }

              final isLoading = state is AuthLoading;

              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.registerTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.registerSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: fullNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.fullNameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l10n.fullNameRequired;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.phoneNumberLabel,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l10n.phoneNumberRequired;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l10n.emailRequired;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return l10n.passwordMinLength;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: isLoading ? null : onSubmit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.createAccountButton),
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

class _EmailConfirmationRequiredView extends StatelessWidget {
  final String email;
  final VoidCallback onBackToLogin;

  const _EmailConfirmationRequiredView({
    required this.email,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 56,
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
              l10n.emailConfirmationMessage(email),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onBackToLogin,
              icon: const Icon(Icons.login_outlined),
              label: Text(l10n.backToLoginButton),
            ),
          ],
        ),
      ),
    );
  }
}
