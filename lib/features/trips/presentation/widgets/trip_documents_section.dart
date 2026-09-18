import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_document.dart';
import '../../domain/entities/trip_document_kind.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../helpers/trip_document_launcher.dart';
import '../helpers/trip_document_picker.dart';
import '../helpers/trips_failure_message.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_shared_widgets.dart';

class TripDocumentsSection extends StatelessWidget {
  final TripEntity trip;
  final TripsLoaded? state;

  const TripDocumentsSection({
    required this.trip,
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loaded = state;

    if (loaded == null || loaded.isDocumentsLoading) {
      return TripDetailsCard(children: [Text(l10n.tripLoadingDocuments)]);
    }

    final failure = loaded.documentsFailure;

    return TripDetailsCard(
      children: [
        _TripDocumentReadiness(state: loaded),
        if (failure != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            tripsFailureMessage(context, failure),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (loaded.canManageTripDocuments)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: loaded.isTripDocumentMutating
                  ? null
                  : () => _upload(context),
              icon: const Icon(AppIcons.uploadFile),
              label: Text(l10n.tripDocumentUploadButton),
            ),
          ),
        if (loaded.canManageTripDocuments)
          const SizedBox(height: AppSpacing.md),
        if (loaded.selectedTripDocuments.isEmpty)
          Text(l10n.tripNoDocumentsFound)
        else
          for (final document in loaded.selectedTripDocuments)
            _TripDocumentTile(
              document: document,
              canManage: loaded.canManageTripDocuments,
              isMutating: loaded.isTripDocumentMutating,
              onOpen: () => _open(context, document),
              onReplace: () => _replace(context, document),
              onRemove: () => _confirmRemove(context, document),
            ),
      ],
    );
  }

  Future<void> _upload(BuildContext context) async {
    final kind = await _selectDocumentKind(context);
    if (kind == null || !context.mounted) return;

    final picked = await _pickDocument(context);
    if (picked == null || !context.mounted) return;

    await context.read<TripsCubit>().uploadTripDocument(
      tripId: trip.id,
      kind: kind,
      document: picked,
    );
  }

  Future<void> _replace(
    BuildContext context,
    TripDocument document,
  ) async {
    final picked = await _pickDocument(context);
    if (picked == null || !context.mounted) return;

    await context.read<TripsCubit>().replaceTripDocument(
      document: document,
      replacement: picked,
    );
  }

  Future<void> _open(BuildContext context, TripDocument document) async {
    final cubit = context.read<TripsCubit>();
    final access = await cubit.createTripDocumentAccess(document);
    if (access == null || !context.mounted) return;

    final opened = await const TripDocumentLauncher().open(access.value);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tripDocumentOpenFailed)),
      );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    TripDocument document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.tripDocumentRemoveTitle),
          content: Text(l10n.tripDocumentRemoveMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.tripDocumentRemoveButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<TripsCubit>().removeTripDocument(
      trip: trip,
      document: document,
    );
  }

  Future<TripDocumentKind?> _selectDocumentKind(BuildContext context) {
    final l10n = context.l10n;
    return showDialog<TripDocumentKind>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(l10n.tripDocumentChooseKindTitle),
          children: [
            for (final kind in TripDocumentKind.values)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(kind),
                child: Text(l10n.tripDocumentKindLabel(kind)),
              ),
          ],
        );
      },
    );
  }

  Future<BusinessDocumentFile?> _pickDocument(BuildContext context) async {
    final picker = TripDocumentPicker();
    if (!picker.supportsImageCapture) {
      return picker.pick(TripDocumentPickSource.file);
    }

    final source = await showDialog<TripDocumentPickSource>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return SimpleDialog(
          title: Text(l10n.tripDocumentChooseSourceTitle),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(TripDocumentPickSource.file),
              child: ListTile(
                leading: const Icon(AppIcons.uploadFile),
                title: Text(l10n.tripDocumentChooseFile),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(TripDocumentPickSource.gallery),
              child: ListTile(
                leading: const Icon(AppIcons.image),
                title: Text(l10n.tripDocumentChooseGallery),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(TripDocumentPickSource.camera),
              child: ListTile(
                leading: const Icon(AppIcons.camera),
                title: Text(l10n.tripDocumentTakePhoto),
              ),
            ),
          ],
        );
      },
    );

    if (source == null) return null;
    return picker.pick(source);
  }
}

class _TripDocumentReadiness extends StatelessWidget {
  final TripsLoaded state;

  const _TripDocumentReadiness({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isReady = state.hasRequiredTripEvidence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isReady ? AppIcons.reactivate : AppIcons.auditHistory,
              size: AppSizes.iconSm,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isReady
                    ? l10n.tripDocumentEvidenceReady
                    : l10n.tripDocumentEvidenceMissing,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.tripDocumentEvidenceRule),
      ],
    );
  }
}

class _TripDocumentTile extends StatelessWidget {
  final TripDocument document;
  final bool canManage;
  final bool isMutating;
  final VoidCallback onOpen;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _TripDocumentTile({
    required this.document,
    required this.canManage,
    required this.isMutating,
    required this.onOpen,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.uploadFile),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.originalFileName),
                Text(l10n.tripDocumentKindLabel(document.kind)),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              IconButton(
                tooltip: l10n.tripDocumentViewButton,
                onPressed: isMutating ? null : onOpen,
                icon: const Icon(AppIcons.view),
              ),
              if (canManage)
                IconButton(
                  tooltip: l10n.tripDocumentReplaceButton,
                  onPressed: isMutating ? null : onReplace,
                  icon: const Icon(AppIcons.edit),
                ),
              if (canManage)
                IconButton(
                  tooltip: l10n.tripDocumentRemoveButton,
                  onPressed: isMutating ? null : onRemove,
                  icon: const Icon(AppIcons.deactivate),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
