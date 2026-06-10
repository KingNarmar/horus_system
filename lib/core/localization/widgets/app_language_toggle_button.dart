import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_locale_cubit.dart';
import '../app_localizations_extension.dart';

class AppLanguageToggleButton extends StatelessWidget {
  const AppLanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLocaleCubit, Locale>(
      builder: (context, locale) {
        final isArabic = locale.languageCode == AppLocaleCubit.arabic.languageCode;
        final label = isArabic ? context.l10n.switchToEnglish : context.l10n.switchToArabic;

        return TextButton.icon(
          onPressed: () => context.read<AppLocaleCubit>().toggleLanguage(),
          icon: const Icon(Icons.translate_outlined),
          label: Text(label),
        );
      },
    );
  }
}
