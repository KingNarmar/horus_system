import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart'
    show AppLocalizationsX;
import '../../../../core/responsive/responsive_layout.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/company_invitation_preview.dart';
import '../../domain/entities/company_invitation_status.dart';
import '../cubit/company_invitation_acceptance_cubit.dart';
import '../cubit/company_invitation_acceptance_state.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import '../extensions/company_failure_localization.dart';
import '../extensions/company_role_localization.dart';

class CompanyInvitationAcceptancePage extends StatefulWidget {
  final String? initialToken;

  const CompanyInvitationAcceptancePage({this.initialToken, super.key});

  @override
  State<CompanyInvitationAcceptancePage> createState() =>
      _CompanyInvitationAcceptancePageState();
}

class _CompanyInvitationAcceptancePageState
    extends State<CompanyInvitationAcceptancePage> {
  final _tokenController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isAuthenticated =
          context.read<AuthCubit>().state is AuthAuthenticated;
      final token = widget.initialToken?.trim();

      if (token != null && token.isNotEmpty) {
        context.read<CompanyInvitationAcceptanceCubit>().captureToken(
          token: token,
          isAuthenticated: isAuthenticated,
        );
      } else {
        context.read<CompanyInvitationAcceptanceCubit>().restore(
          isAuthenticated: isAuthenticated,
        );
      }
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.read<CompanyInvitationAcceptanceCubit>().restore(
                isAuthenticated: true,
              );
            }
          },
        ),
        BlocListener<CompanyInvitationAcceptanceCubit,
            CompanyInvitationAcceptanceState>(
          listener: (context, state) {
            if (state is CompanyInvitationAccepted) {
              final cleanupFailure = state.pendingTokenCleanupFailure;
              if (cleanupFailure != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.localizedCompanyErrorMessage(cleanupFailure),
                    ),
                  ),
                );
              }
              _openAcceptedCompany(state.companyId);
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthInitial || authState is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return BlocBuilder<CompanyInvitationAcceptanceCubit,
              CompanyInvitationAcceptanceState>(
            builder: (context, state) {
              if (state is CompanyInvitationAwaitingAuthentication &&
                  authState is! AuthAuthenticated) {
                return const LoginPage();
              }

              return Scaffold(
                appBar: AppBar(title: Text(context.l10n.invitationTitle)),
                body: SafeArea(child: _buildBody(context, state)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CompanyInvitationAcceptanceState state,
  ) {
    if (state is CompanyInvitationPreviewLoading ||
        state is CompanyInvitationAccepted) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CompanyInvitationPreviewReady) {
      return _responsivePreview(context, state.preview, isAccepting: false);
    }

    if (state is CompanyInvitationAccepting) {
      return _responsivePreview(context, state.preview, isAccepting: true);
    }

    if (state is CompanyInvitationAcceptanceFailure) {
      return _responsiveContent(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.localizedCompanyErrorMessage(state.failure),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            _TokenEntry(
              controller: _tokenController,
              onSubmit: _submitManualToken,
            ),
          ],
        ),
      );
    }

    return _responsiveContent(
      context,
      _TokenEntry(
        controller: _tokenController,
        onSubmit: _submitManualToken,
      ),
    );
  }

  Widget _responsivePreview(
    BuildContext context,
    CompanyInvitationPreview preview, {
    required bool isAccepting,
  }) {
    final l10n = context.l10n;
    final statusLabel = switch (preview.status) {
      CompanyInvitationStatus.pending => l10n.invitationStatusPending,
      CompanyInvitationStatus.accepted => l10n.invitationStatusAccepted,
      CompanyInvitationStatus.expired => l10n.invitationStatusExpired,
      CompanyInvitationStatus.revoked => l10n.invitationStatusRevoked,
    };

    final canAccept =
        preview.status == CompanyInvitationStatus.pending && !isAccepting;

    return _responsiveContent(
      context,
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.invitationPreviewTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.invitationCompanyLine(preview.companyName)),
              Text(l10n.invitationEmailLine(preview.email)),
              Text(
                l10n.invitationRoleLine(preview.role.localizedLabel(context)),
              ),
              Text(l10n.invitationStatusLine(statusLabel)),
              Text(
                l10n.invitationExpiresLine(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(preview.expiresAt.toLocal()),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: canAccept
                    ? context.read<CompanyInvitationAcceptanceCubit>().accept
                    : null,
                child: isAccepting
                    ? const SizedBox(
                        width: AppSizes.iconMd,
                        height: AppSizes.iconMd,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                        ),
                      )
                    : Text(l10n.invitationAcceptButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _responsiveContent(BuildContext context, Widget child) {
    return ResponsiveLayout(
      mobile: _CenteredInvitationContent(
        maxWidth: AppSizes.mobileMaxContentWidth,
        horizontalPadding: AppSpacing.lg,
        child: child,
      ),
      tablet: _CenteredInvitationContent(
        maxWidth: AppSizes.tabletMaxContentWidth,
        horizontalPadding: AppSpacing.xl,
        child: child,
      ),
      desktop: _CenteredInvitationContent(
        maxWidth: AppSizes.desktopAuthFormMaxWidth,
        horizontalPadding: AppSpacing.xxl,
        child: child,
      ),
    );
  }

  void _submitManualToken() {
    final isAuthenticated = context.read<AuthCubit>().state is AuthAuthenticated;
    context.read<CompanyInvitationAcceptanceCubit>().captureToken(
      token: _tokenController.text,
      isAuthenticated: isAuthenticated,
    );
  }

  Future<void> _openAcceptedCompany(String companyId) async {
    final currentCompanyCubit = context.read<CurrentCompanyCubit>();
    await currentCompanyCubit.refreshAndSelectCompany(companyId);
    if (!mounted) return;

    final state = currentCompanyCubit.state;
    if (state is CurrentCompanyLoaded && state.context.companyId == companyId) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.appShell,
        (route) => false,
      );
    }
  }
}

class _TokenEntry extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _TokenEntry({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.invitationManualCodeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.invitationManualCodeDescription),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: controller,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: l10n.invitationCodeLabel),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: onSubmit,
          child: Text(l10n.invitationContinueButton),
        ),
      ],
    );
  }
}

class _CenteredInvitationContent extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;
  final Widget child;

  const _CenteredInvitationContent({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
