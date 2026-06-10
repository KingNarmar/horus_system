import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/routing/app_router.dart';
import 'app/routing/app_routes.dart';
import 'core/constants/app_sizes.dart';
import 'core/constants/app_spacing.dart';
import 'core/di/app_dependencies.dart';
import 'core/localization/app_locale_cubit.dart';
import 'core/localization/app_locale_storage.dart';
import 'core/localization/app_localizations_extension.dart';
import 'core/responsive/responsive_layout.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/company/presentation/cubit/company_onboarding_cubit.dart';
import 'features/company/presentation/cubit/company_users_cubit.dart';
import 'features/company/presentation/cubit/current_company_cubit.dart';
import 'features/customers/presentation/cubit/customers_cubit.dart';
import 'l10n/app_localizations.dart';

class HorusApp extends StatelessWidget {
  const HorusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppLocaleCubit>(
          create: (_) => AppLocaleCubit(
            storage: const SharedPreferencesAppLocaleStorage(),
          ),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => AppDependencies.createAuthCubit()..checkCurrentUser(),
        ),
        BlocProvider<CurrentCompanyCubit>(
          create: (_) => AppDependencies.createCurrentCompanyCubit(),
        ),
        BlocProvider<CompanyOnboardingCubit>(
          create: (_) => AppDependencies.createCompanyOnboardingCubit(),
        ),
        BlocProvider<CompanyUsersCubit>(
          create: (_) => AppDependencies.createCompanyUsersCubit(),
        ),
        BlocProvider<CustomersCubit>(
          create: (_) => AppDependencies.createCustomersCubit(),
        ),
      ],
      child: BlocBuilder<AppLocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            onGenerateTitle: (context) => context.l10n.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: locale,
            builder: DevicePreview.appBuilder,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: AppRoutes.root,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}

class HorusLaunchPage extends StatelessWidget {
  const HorusLaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _LaunchLayout(
            maxWidth: AppSizes.mobileMaxContentWidth,
            horizontalPadding: AppSpacing.lg,
          ),
          tablet: _LaunchLayout(
            maxWidth: AppSizes.tabletMaxContentWidth,
            horizontalPadding: AppSpacing.xl,
          ),
          desktop: _LaunchLayout(
            maxWidth: AppSizes.desktopMaxContentWidth,
            horizontalPadding: AppSpacing.xxl,
          ),
        ),
      ),
    );
  }
}

class _LaunchLayout extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;

  const _LaunchLayout({
    required this.maxWidth,
    required this.horizontalPadding,
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
          child: const _LaunchContent(),
        ),
      ),
    );
  }
}

class _LaunchContent extends StatelessWidget {
  const _LaunchContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.appSubtitle,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.launchDescription,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _ArchitectureBadge(),
      ],
    );
  }
}

class _ArchitectureBadge extends StatelessWidget {
  const _ArchitectureBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          l10n.architectureBadge,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
