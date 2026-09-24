import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../bootstrap_failure.dart';

class BootstrapFailureApp extends StatelessWidget {
  final BootstrapFailure failure;

  const BootstrapFailureApp({required this.failure, super.key});

  @override
  Widget build(BuildContext context) {
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final locale = platformLocale.languageCode.toLowerCase() == 'ar'
        ? const Locale('ar')
        : const Locale('en');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _BootstrapFailurePage(failure: failure),
    );
  }
}

class _BootstrapFailurePage extends StatelessWidget {
  final BootstrapFailure failure;

  const _BootstrapFailurePage({required this.failure});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);
    final message = switch (failure.code) {
      BootstrapFailureCode.invalidConfiguration =>
        localizations.bootstrapInvalidConfigurationMessage,
      BootstrapFailureCode.serviceInitializationFailed =>
        localizations.bootstrapServiceInitializationFailedMessage,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.desktopAuthFormMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.bootstrapFailure,
                    size: AppSizes.iconXl,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    localizations.bootstrapFailureTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
