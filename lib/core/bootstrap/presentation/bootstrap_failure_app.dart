import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../bootstrap_failure.dart';
import 'bootstrap_failure_localizations.dart';

class BootstrapFailureApp extends StatelessWidget {
  final BootstrapFailure failure;

  const BootstrapFailureApp({
    required this.failure,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final platformLocale =
        WidgetsBinding.instance.platformDispatcher.locale;
    final locale = platformLocale.languageCode.toLowerCase() == 'ar'
        ? const Locale('ar')
        : const Locale('en');
    final copy = BootstrapFailureLocalizations.resolve(
      languageCode: locale.languageCode,
      code: failure.code,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _BootstrapFailurePage(copy: copy),
    );
  }
}

class _BootstrapFailurePage extends StatelessWidget {
  final BootstrapFailureCopy copy;

  const _BootstrapFailurePage({required this.copy});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                    copy.title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    copy.message,
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
