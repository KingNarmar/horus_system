import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../cubit/account_deletion_cubit.dart';
import '../cubit/account_deletion_state.dart';

final class AccountDeletionSettingsCard extends StatelessWidget {
  const AccountDeletionSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: BlocBuilder<AccountDeletionCubit, AccountDeletionState>(
          builder: (context, state) {
            final isLoading = state is AccountDeletionLoading;
            final ready = state is AccountDeletionReady ? state : null;
            final pending = ready?.status.isPending ?? false;
            final soleOwner =
                state is AccountDeletionFailure &&
                state.failure.code == FailureCodes.accountDeletionSoleOwner;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountDeletionTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.accountDeletionDescription),
                if (soleOwner) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.accountDeletionSoleOwner),
                ],
                if (pending) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.accountDeletionPending),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (pending)
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AccountDeletionCubit>().cancelDeletion();
                    },
                    icon: const Icon(AppIcons.clear),
                    label: Text(l10n.accountDeletionCancel),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _confirm(context),
                    icon: const Icon(AppIcons.deactivate),
                    label: Text(l10n.accountDeletionRequest),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountDeletionConfirmTitle),
        content: Text(l10n.accountDeletionConfirmDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountDeletionConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AccountDeletionCubit>().requestDeletion();
    }
  }
}
