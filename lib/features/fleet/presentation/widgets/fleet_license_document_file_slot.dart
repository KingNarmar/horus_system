import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fleet_license_document.dart';
import '../../domain/entities/fleet_license_document_file.dart';
import '../../domain/entities/fleet_license_document_file_side.dart';
import '../cubit/fleet_cubit.dart';
import '../cubit/fleet_license_documents_cubit.dart';
import '../helpers/fleet_license_document_launcher.dart';
import '../helpers/fleet_license_document_picker.dart';
import '../helpers/fleet_license_document_saver.dart';
import '../helpers/fleet_license_expiry_update_picker.dart';

final class FleetLicenseDocumentFileSlot extends StatelessWidget {
  final FleetLicenseDocument? document;
  final FleetLicenseDocumentFile? file;
  final FleetLicenseDocumentFileSide side;
  final bool canManage;
  final bool isMutating;
  final BusinessDate? currentLicenseExpiryDate;
  final Future<void> Function() onAssetChanged;

  const FleetLicenseDocumentFileSlot({
    required this.document,
    required this.file,
    required this.side,
    required this.canManage,
    required this.isMutating,
    required this.currentLicenseExpiryDate,
    required this.onAssetChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sideLabel = _sideLabel(l10n, side);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sideLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (file == null)
              _MissingFileActions(
                document: document,
                side: side,
                sideLabel: sideLabel,
                canManage: canManage,
                isMutating: isMutating,
                currentLicenseExpiryDate: currentLicenseExpiryDate,
                onAssetChanged: onAssetChanged,
              )
            else
              _ExistingFileActions(
                document: document!,
                file: file!,
                canManage: canManage,
                isMutating: isMutating,
                currentLicenseExpiryDate: currentLicenseExpiryDate,
                onAssetChanged: onAssetChanged,
              ),
          ],
        ),
      ),
    );
  }
}

final class _MissingFileActions extends StatelessWidget {
  final FleetLicenseDocument? document;
  final FleetLicenseDocumentFileSide side;
  final String sideLabel;
  final bool canManage;
  final bool isMutating;
  final BusinessDate? currentLicenseExpiryDate;
  final Future<void> Function() onAssetChanged;

  const _MissingFileActions({
    required this.document,
    required this.side,
    required this.sideLabel,
    required this.canManage,
    required this.isMutating,
    required this.currentLicenseExpiryDate,
    required this.onAssetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.fleetLicenseDocumentMissingSide(sideLabel)),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: isMutating ? null : () => _upload(context),
              icon: const Icon(AppIcons.uploadFile),
              label: Text(l10n.fleetLicenseDocumentUploadSide(sideLabel)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _upload(BuildContext context) async {
    final picked = await const FleetLicenseDocumentPicker().pick();
    if (picked == null || !context.mounted) return;

    BusinessDate? newExpiry;
    if (document == null) {
      final currentBusinessDate = await _getCurrentBusinessDate(context);
      if (currentBusinessDate == null || !context.mounted) return;
      final selection = await selectFleetLicenseExpiryUpdate(
        context,
        currentLicenseExpiryDate,
        currentBusinessDate: currentBusinessDate,
      );
      if (selection == null || !context.mounted) return;
      newExpiry = selection.newValue;
    }

    final changed = await context.read<FleetLicenseDocumentsCubit>().upload(
      side: side,
      file: picked,
      newLicenseExpiryDate: newExpiry,
    );
    if (changed && context.mounted) {
      await onAssetChanged();
    }
  }
}

final class _ExistingFileActions extends StatelessWidget {
  final FleetLicenseDocument document;
  final FleetLicenseDocumentFile file;
  final bool canManage;
  final bool isMutating;
  final BusinessDate? currentLicenseExpiryDate;
  final Future<void> Function() onAssetChanged;

  const _ExistingFileActions({
    required this.document,
    required this.file,
    required this.canManage,
    required this.isMutating,
    required this.currentLicenseExpiryDate,
    required this.onAssetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(file.originalFileName),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              IconButton(
                tooltip: l10n.fleetLicenseDocumentOpenButton,
                onPressed: isMutating ? null : () => _open(context),
                icon: const Icon(AppIcons.view),
              ),
              IconButton(
                tooltip: l10n.fleetLicenseDocumentDownloadButton,
                onPressed: isMutating ? null : () => _download(context),
                icon: const Icon(AppIcons.download),
              ),
              if (canManage)
                IconButton(
                  tooltip: l10n.fleetLicenseDocumentReplaceButton,
                  onPressed: isMutating ? null : () => _replace(context),
                  icon: const Icon(AppIcons.edit),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final access = await context
        .read<FleetLicenseDocumentsCubit>()
        .createAccess(document, file);
    if (access == null || !context.mounted) return;

    final opened = await const FleetLicenseDocumentLauncher().open(
      access.value,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fleetLicenseDocumentOpenFailed)),
      );
    }
  }

  Future<void> _download(BuildContext context) async {
    final bytes = await context.read<FleetLicenseDocumentsCubit>().download(
      document,
      file,
    );
    if (bytes == null || !context.mounted) return;

    final saved = await const FleetLicenseDocumentSaver().save(
      bytes: bytes,
      fileName: file.originalFileName,
      mimeType: file.mimeType,
      dialogTitle: context.l10n.fleetLicenseDocumentSaveDialogTitle,
    );
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.fleetLicenseDocumentDownloadFailed),
        ),
      );
    }
  }

  Future<void> _replace(BuildContext context) async {
    final replacement = await const FleetLicenseDocumentPicker().pick();
    if (replacement == null || !context.mounted) return;

    final currentBusinessDate = await _getCurrentBusinessDate(context);
    if (currentBusinessDate == null || !context.mounted) return;
    final selection = await selectFleetLicenseExpiryUpdate(
      context,
      currentLicenseExpiryDate,
      currentBusinessDate: currentBusinessDate,
    );
    if (selection == null || !context.mounted) return;

    final changed = await context.read<FleetLicenseDocumentsCubit>().replace(
      document: document,
      file: file,
      replacement: replacement,
      newLicenseExpiryDate: selection.newValue,
    );
    if (changed && context.mounted) {
      await onAssetChanged();
    }
  }
}

Future<BusinessDate?> _getCurrentBusinessDate(BuildContext context) async {
  final result = await context.read<FleetCubit>().getCurrentBusinessDate();
  if (!context.mounted) return null;

  if (result is FailureResult<BusinessDate>) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.localizedErrorMessage(result.failure))),
    );
    return null;
  }

  return (result as Success<BusinessDate>).data;
}

String _sideLabel(AppLocalizations l10n, FleetLicenseDocumentFileSide side) {
  return switch (side) {
    FleetLicenseDocumentFileSide.front => l10n.fleetLicenseDocumentFrontSide,
    FleetLicenseDocumentFileSide.back => l10n.fleetLicenseDocumentBackSide,
    FleetLicenseDocumentFileSide.combined =>
      l10n.fleetLicenseDocumentCombinedSide,
  };
}
