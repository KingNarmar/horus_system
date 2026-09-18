import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_date_constraints.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../domain/entities/fleet_license_document.dart';
import '../cubit/fleet_license_documents_cubit.dart';
import '../cubit/fleet_license_documents_state.dart';
import '../helpers/fleet_license_document_failure_message.dart';
import '../helpers/fleet_license_document_launcher.dart';
import '../helpers/fleet_license_document_picker.dart';
import '../helpers/fleet_license_document_saver.dart';

final class FleetLicenseDocumentsSection extends StatelessWidget {
  final BusinessDate? currentLicenseExpiryDate;
  final Future<void> Function() onAssetChanged;

  const FleetLicenseDocumentsSection({
    required this.currentLicenseExpiryDate,
    required this.onAssetChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetLicenseDocumentsCubit, FleetLicenseDocumentsState>(
      builder: (context, state) {
        final l10n = context.l10n;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.fleetLicenseDocumentsTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.fleetLicenseExpiryCurrent(
                    _dateText(currentLicenseExpiryDate, l10n.fleetNotAvailable),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (state is FleetLicenseDocumentsInitial ||
                    state is FleetLicenseDocumentsLoading)
                  Text(l10n.fleetLicenseDocumentsLoading)
                else if (state is FleetLicenseDocumentsFailure)
                  Text(
                    fleetLicenseDocumentFailureMessage(context, state.failure),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else if (state is FleetLicenseDocumentsLoaded)
                  _LoadedContent(
                    state: state,
                    currentLicenseExpiryDate: currentLicenseExpiryDate,
                    onAssetChanged: onAssetChanged,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _LoadedContent extends StatelessWidget {
  final FleetLicenseDocumentsLoaded state;
  final BusinessDate? currentLicenseExpiryDate;
  final Future<void> Function() onAssetChanged;

  const _LoadedContent({
    required this.state,
    required this.currentLicenseExpiryDate,
    required this.onAssetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final document = state.document;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.failure != null) ...[
          Text(
            fleetLicenseDocumentFailureMessage(context, state.failure!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (document == null) ...[
          Text(l10n.fleetLicenseDocumentMissing),
          if (state.canManage) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: state.isMutating ? null : () => _upload(context),
                icon: const Icon(AppIcons.uploadFile),
                label: Text(l10n.fleetLicenseDocumentUploadButton),
              ),
            ),
          ],
        ] else
          _DocumentTile(
            document: document,
            canManage: state.canManage,
            isMutating: state.isMutating,
            currentLicenseExpiryDate: currentLicenseExpiryDate,
            onAssetChanged: onAssetChanged,
          ),
      ],
    );
  }

  Future<void> _upload(BuildContext context) async {
    final file = await const FleetLicenseDocumentPicker().pick();
    if (file == null || !context.mounted) return;

    final expirySelection = await _selectExpiryUpdate(
      context,
      currentLicenseExpiryDate,
    );
    if (expirySelection == null || !context.mounted) return;

    final changed = await context.read<FleetLicenseDocumentsCubit>().upload(
      document: file,
      newLicenseExpiryDate: expirySelection.newValue,
    );
    if (changed && context.mounted) {
      await onAssetChanged();
    }
  }
}

final class _DocumentTile extends StatelessWidget {
  final FleetLicenseDocument document;
  final bool canManage;
  final bool isMutating;
  final BusinessDate? currentLicenseExpiryDate;
  final Future<void> Function() onAssetChanged;

  const _DocumentTile({
    required this.document,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(AppIcons.uploadFile),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.originalFileName),
                  Text(l10n.fleetLicenseDocumentUploaded),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
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
              if (canManage)
                IconButton(
                  tooltip: l10n.fleetLicenseDocumentRemoveButton,
                  onPressed: isMutating ? null : () => _confirmRemove(context),
                  icon: const Icon(AppIcons.deactivate),
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
        .createAccess(document);
    if (access == null || !context.mounted) return;

    final opened = await const FleetLicenseDocumentLauncher().open(access.value);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fleetLicenseDocumentOpenFailed)),
      );
    }
  }

  Future<void> _download(BuildContext context) async {
    final bytes = await context
        .read<FleetLicenseDocumentsCubit>()
        .download(document);
    if (bytes == null || !context.mounted) return;

    final saved = await const FleetLicenseDocumentSaver().save(
      bytes: bytes,
      fileName: document.originalFileName,
      mimeType: document.mimeType,
      dialogTitle: context.l10n.fleetLicenseDocumentSaveDialogTitle,
    );
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fleetLicenseDocumentDownloadFailed)),
      );
    }
  }

  Future<void> _replace(BuildContext context) async {
    final file = await const FleetLicenseDocumentPicker().pick();
    if (file == null || !context.mounted) return;

    final expirySelection = await _selectExpiryUpdate(
      context,
      currentLicenseExpiryDate,
    );
    if (expirySelection == null || !context.mounted) return;

    final changed = await context.read<FleetLicenseDocumentsCubit>().replace(
      document: document,
      replacement: file,
      newLicenseExpiryDate: expirySelection.newValue,
    );
    if (changed && context.mounted) {
      await onAssetChanged();
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.fleetLicenseDocumentRemoveTitle),
        content: Text(dialogContext.l10n.fleetLicenseDocumentRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.fleetLicenseDocumentRemoveButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final changed = await context
        .read<FleetLicenseDocumentsCubit>()
        .remove(document);
    if (changed && context.mounted) {
      await onAssetChanged();
    }
  }
}

Future<_LicenseExpirySelection?> _selectExpiryUpdate(
  BuildContext context,
  BusinessDate? currentValue,
) async {
  final choice = await showDialog<_ExpiryChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.fleetLicenseExpiryUpdateTitle),
      content: Text(dialogContext.l10n.fleetLicenseExpiryUpdateMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.l10n.cancelButton),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_ExpiryChoice.keepCurrent),
          child: Text(dialogContext.l10n.fleetLicenseExpiryKeepCurrent),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_ExpiryChoice.update),
          child: Text(dialogContext.l10n.fleetLicenseExpiryUpdateButton),
        ),
      ],
    ),
  );

  if (choice == null) return null;
  if (choice == _ExpiryChoice.keepCurrent) {
    return const _LicenseExpirySelection();
  }

  final today = BusinessDateDateTimeAdapter.fromDateTime(DateTime.now());
  final picked = await showDatePicker(
    context: context,
    initialDate: BusinessDateDateTimeAdapter.toDateTime(currentValue ?? today),
    firstDate: DateTime(
      today.year - AppDateConstraints.fleetLicenseExpiryPastYears,
      today.month,
      today.day,
    ),
    lastDate: DateTime(
      today.year + AppDateConstraints.fleetLicenseExpiryFutureYears,
      today.month,
      today.day,
    ),
  );
  if (picked == null) return null;
  return _LicenseExpirySelection(
    newValue: BusinessDateDateTimeAdapter.fromDateTime(picked),
  );
}

enum _ExpiryChoice { keepCurrent, update }

final class _LicenseExpirySelection {
  final BusinessDate? newValue;

  const _LicenseExpirySelection({this.newValue});
}

String _dateText(BusinessDate? value, String fallback) {
  if (value == null) return fallback;
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
