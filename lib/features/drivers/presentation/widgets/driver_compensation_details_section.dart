import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../cubit/driver_compensation_state.dart';
import '../helpers/driver_compensation_formatters.dart';
import '../localization/driver_compensation_localizations.dart';
import 'driver_details_section.dart';

final class DriverCompensationDetailsSection extends StatelessWidget {
  final DriverCompensationState state;
  final VoidCallback onAddRevision;
  final ValueChanged<DriverCompensationRevision> onEndRevision;
  final ValueChanged<DriverCompensationRevision> onAttachContract;
  final ValueChanged<DriverCompensationRevision> onOpenContract;

  const DriverCompensationDetailsSection({
    required this.state,
    required this.onAddRevision,
    required this.onEndRevision,
    required this.onAttachContract,
    required this.onOpenContract,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.driverCompensationL10n;
    final currentState = state;

    return DriverDetailsSection(
      title: l10n.sectionTitle,
      children: [
        if (currentState is DriverCompensationInitial ||
            currentState is DriverCompensationLoading)
          const Center(child: CircularProgressIndicator())
        else if (currentState is DriverCompensationFailure)
          Text(driverCompensationFailureMessage(context, currentState.failure))
        else if (currentState is DriverCompensationLoaded) ...[
          if (currentState.mutationFailure != null) ...[
            Text(
              driverCompensationFailureMessage(
                context,
                currentState.mutationFailure!,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.currentCompensation,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (currentState.canManage)
                FilledButton.icon(
                  onPressed: currentState.isSaving ? null : onAddRevision,
                  icon: const Icon(AppIcons.add),
                  label: Text(l10n.addRevision),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (currentState.currentRevision == null)
            Text(l10n.noCurrentCompensation)
          else
            _RevisionCard(
              revision: currentState.currentRevision!,
              canManage: currentState.canManage,
              canAccessContractDocument: currentState.canAccessContractDocument,
              isPending:
                  currentState.isSaving &&
                  currentState.pendingRevisionId ==
                      currentState.currentRevision!.id,
              onEndRevision: onEndRevision,
              onAttachContract: onAttachContract,
              onOpenContract: onOpenContract,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (currentState.history.isEmpty)
            Text(l10n.noHistory)
          else
            ...currentState.history.map(
              (revision) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RevisionCard(
                  revision: revision,
                  canManage: currentState.canManage,
                  canAccessContractDocument:
                      currentState.canAccessContractDocument,
                  isPending:
                      currentState.isSaving &&
                      currentState.pendingRevisionId == revision.id,
                  onEndRevision: onEndRevision,
                  onAttachContract: onAttachContract,
                  onOpenContract: onOpenContract,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

final class _RevisionCard extends StatelessWidget {
  final DriverCompensationRevision revision;
  final bool canManage;
  final bool canAccessContractDocument;
  final bool isPending;
  final ValueChanged<DriverCompensationRevision> onEndRevision;
  final ValueChanged<DriverCompensationRevision> onAttachContract;
  final ValueChanged<DriverCompensationRevision> onOpenContract;

  const _RevisionCard({
    required this.revision,
    required this.canManage,
    required this.canAccessContractDocument,
    required this.isPending,
    required this.onEndRevision,
    required this.onAttachContract,
    required this.onOpenContract,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.driverCompensationL10n;
    final contractReference = revision.contractReference?.trim();
    final hasDocument = revision.contractDocumentReference != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DriverCompensationFormatters.amount(revision),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.effectiveFromLabel}: '
              '${DriverCompensationFormatters.date(revision.effectiveFrom)}',
            ),
            Text(
              '${l10n.effectiveToLabel}: '
              '${revision.effectiveTo == null ? l10n.ongoingLabel : DriverCompensationFormatters.date(revision.effectiveTo!)}',
            ),
            if (contractReference != null && contractReference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('${l10n.contractReferenceLabel}: $contractReference'),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasDocument
                  ? l10n.contractDocumentLabel
                  : l10n.noContractDocument,
            ),
            if (canManage || (canAccessContractDocument && hasDocument)) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (revision.effectiveTo == null && canManage)
                    OutlinedButton(
                      onPressed: isPending
                          ? null
                          : () => onEndRevision(revision),
                      child: Text(l10n.endRevision),
                    ),
                  if (!hasDocument && canManage)
                    OutlinedButton.icon(
                      onPressed: isPending
                          ? null
                          : () => onAttachContract(revision),
                      icon: const Icon(AppIcons.uploadFile),
                      label: Text(l10n.attachContractDocument),
                    ),
                  if (hasDocument && canAccessContractDocument)
                    OutlinedButton.icon(
                      onPressed: isPending
                          ? null
                          : () => onOpenContract(revision),
                      icon: const Icon(AppIcons.view),
                      label: Text(l10n.openContractDocument),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
