import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/fleet_license_document.dart';
import '../../domain/entities/fleet_license_document_file_side.dart';
import '../cubit/fleet_license_documents_cubit.dart';
import '../cubit/fleet_license_documents_state.dart';
import '../helpers/fleet_license_document_failure_message.dart';
import 'fleet_license_document_file_slot.dart';

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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
    final combinedFile = document?.combinedFile;

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
          const SizedBox(height: AppSpacing.sm),
        ],
        if (combinedFile != null)
          FleetLicenseDocumentFileSlot(
            document: document,
            file: combinedFile,
            side: FleetLicenseDocumentFileSide.combined,
            canManage: state.canManage,
            isMutating: state.isMutating,
            currentLicenseExpiryDate: currentLicenseExpiryDate,
            onAssetChanged: onAssetChanged,
          )
        else ...[
          Text(l10n.fleetLicenseDocumentSideGuidance),
          const SizedBox(height: AppSpacing.sm),
          FleetLicenseDocumentFileSlot(
            document: document,
            file: document?.frontFile,
            side: FleetLicenseDocumentFileSide.front,
            canManage: state.canManage,
            isMutating: state.isMutating,
            currentLicenseExpiryDate: currentLicenseExpiryDate,
            onAssetChanged: onAssetChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          FleetLicenseDocumentFileSlot(
            document: document,
            file: document?.backFile,
            side: FleetLicenseDocumentFileSide.back,
            canManage: state.canManage,
            isMutating: state.isMutating,
            currentLicenseExpiryDate: currentLicenseExpiryDate,
            onAssetChanged: onAssetChanged,
          ),
        ],
        if (state.canManage && document != null) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: state.isMutating
                  ? null
                  : () => _confirmRemove(
                      context,
                      document,
                      onAssetChanged,
                    ),
              icon: const Icon(AppIcons.deactivate),
              label: Text(l10n.fleetLicenseDocumentRemoveButton),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _confirmRemove(
  BuildContext context,
  FleetLicenseDocument document,
  Future<void> Function() onAssetChanged,
) async {
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

  final changed = await context.read<FleetLicenseDocumentsCubit>().remove(
    document,
  );
  if (changed && context.mounted) {
    await onAssetChanged();
  }
}

String _dateText(BusinessDate? value, String fallback) {
  if (value == null) return fallback;
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
