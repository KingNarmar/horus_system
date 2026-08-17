import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver_image_file.dart';
import '../localization/drivers_localizations_x.dart';

enum DriverImageTarget {
  profile,
  licenseFront,
  licenseBack,
  nationalIdFront,
  nationalIdBack,
}

class SelectedDriverImage {
  final String displayName;
  final DriverImageFile file;

  const SelectedDriverImage({required this.displayName, required this.file});
}

class DriverFormImagePickerTile extends StatelessWidget {
  final String label;
  final String? existingPath;
  final SelectedDriverImage? selectedImage;
  final String? failureText;
  final bool isSubmitting;
  final VoidCallback onPickFromFiles;
  final VoidCallback? onTakePhoto;

  const DriverFormImagePickerTile({
    required this.label,
    required this.existingPath,
    required this.selectedImage,
    required this.failureText,
    required this.isSubmitting,
    required this.onPickFromFiles,
    required this.onTakePhoto,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasExisting = existingPath?.trim().isNotEmpty ?? false;
    final status =
        selectedImage?.displayName ??
        (hasExisting ? l10n.driverImageAlreadyUploaded : l10n.emptyValue);

    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.image),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : onPickFromFiles,
                icon: const Icon(AppIcons.uploadFile),
                label: Text(l10n.driverChooseImageFromFiles),
              ),
              if (onTakePhoto != null)
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onTakePhoto,
                  icon: const Icon(AppIcons.camera),
                  label: Text(l10n.driverTakeImageWithCamera),
                ),
            ],
          ),
          if (failureText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              failureText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

bool get canUseDriverImageCamera {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
