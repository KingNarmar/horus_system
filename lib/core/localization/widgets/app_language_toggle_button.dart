import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_locale_cubit.dart';
import '../app_localizations_extension.dart';

class AppLanguageToggleButton extends StatelessWidget {
  final bool showLabel;

  const AppLanguageToggleButton({this.showLabel = true, super.key});

  const AppLanguageToggleButton.compact({super.key}) : showLabel = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLocaleCubit, Locale>(
      builder: (context, locale) {
        final isArabic = locale.languageCode == AppLocaleCubit.arabic.languageCode;
        final label = isArabic ? context.l10n.switchToEnglish : context.l10n.switchToArabic;
        final onPressed = () => context.read<AppLocaleCubit>().toggleLanguage();

        if (!showLabel) {
          return IconButton(
            tooltip: label,
            onPressed: onPressed,
            icon: const Icon(Icons.translate_outlined),
          );
        }

        return TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.translate_outlined),
          label: Text(label),
        );
      },
    );
  }
}
