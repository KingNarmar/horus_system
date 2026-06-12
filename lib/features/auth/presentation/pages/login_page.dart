import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthCubit>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _openRegisterPage() {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _LoginLayout(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            onSubmit: _submit,
            onCreateAccount: _openRegisterPage,
          ),
          tablet: _LoginLayout(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            onSubmit: _submit,
            onCreateAccount: _openRegisterPage,
          ),
          desktop: _LoginLayout(
            maxWidth: AppSizes.desktopAuthFormMaxWidth,
            horizontalPadding: AppSpacing.xxl,
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            onSubmit: _submit,
            onCreateAccount: _openRegisterPage,
          ),
        ),
      ),
    );
  }
}

class _LoginLayout extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onCreateAccount;

  const _LoginLayout({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onCreateAccount,
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
                  SnackBar(
                    content: Text(l10n.localizedErrorMessage(state.failure)),
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.loginWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(AppIcons.email),
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
                        prefixIcon: const Icon(AppIcons.password),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return l10n.passwordRequired;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: isLoading ? null : onSubmit,
                      child: isLoading
                          ? const SizedBox(
                              width: AppSizes.loadingIndicatorSm,
                              height: AppSizes.loadingIndicatorSm,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                              ),
                            )
                          : Text(l10n.loginButton),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: isLoading ? null : onCreateAccount,
                      child: Text(l10n.createNewAccountButton),
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
