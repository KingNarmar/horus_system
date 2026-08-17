import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../localization/drivers_localizations_x.dart';

class DriverImagesGrid extends StatelessWidget {
  final String? profileImageUrl;
  final String? licenseImageUrl;
  final String? licenseBackImageUrl;
  final String? nationalIdImageUrl;
  final String? nationalIdBackImageUrl;

  const DriverImagesGrid({
    required this.profileImageUrl,
    required this.licenseImageUrl,
    required this.licenseBackImageUrl,
    required this.nationalIdImageUrl,
    required this.nationalIdBackImageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppSizes.dataTableBreakpoint;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _DriverImagePreview(
              label: l10n.driverProfileImageLabel,
              imageUrl: profileImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverLicenseFrontImageLabel,
              imageUrl: licenseImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverLicenseBackImageLabel,
              imageUrl: licenseBackImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverNationalIdFrontImageLabel,
              imageUrl: nationalIdImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverNationalIdBackImageLabel,
              imageUrl: nationalIdBackImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
          ],
        );
      },
    );
  }
}

class _DriverImagePreview extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final double width;

  const _DriverImagePreview({
    required this.label,
    required this.imageUrl,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final normalizedUrl = imageUrl?.trim();
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: normalizedUrl == null || normalizedUrl.isEmpty
                  ? Center(child: Text(l10n.emptyValue))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        normalizedUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Text(l10n.emptyValue));
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
