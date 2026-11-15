import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../localization/company_branding_localizations.dart';

/// Shared Presentation widget; selection and persistence are separate intents.
final class CompanyBrandLogoSelector extends StatelessWidget {
  final Uint8List? imageBytes;
  final bool hasLogo;
  final bool enabled;
  final VoidCallback? onChoose;
  final VoidCallback? onRemove;

  const CompanyBrandLogoSelector({
    required this.imageBytes,
    required this.hasLogo,
    required this.enabled,
    required this.onChoose,
    this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyBrandingL10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.logoTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.logoOptional),
        const SizedBox(height: AppSpacing.md),
        if (imageBytes != null)
          SizedBox(
            height: AppSizes.companyLogoPreviewHeight,
            child: Image.memory(
              imageBytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                AppIcons.image, size: AppSizes.iconXl,
              ),
            ),
          )
        else
          Row(
            children: [
              const Icon(AppIcons.image, size: AppSizes.iconLg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.noLogo)),
            ],
          ),
        if (onChoose != null || onRemove != null) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              if (onChoose != null)
                OutlinedButton.icon(
                  onPressed: enabled ? onChoose : null,
                  icon: const Icon(AppIcons.uploadFile),
                  label: Text(hasLogo ? l10n.replaceLogo : l10n.selectLogo),
                ),
              if (hasLogo && onRemove != null)
                TextButton.icon(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(AppIcons.clear),
                  label: Text(l10n.removeLogo),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
