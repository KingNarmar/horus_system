import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/app_icons.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_spacing.dart';
import '../../../localization/app_localizations_extension.dart';
import '../cubit/network_status_cubit.dart';
import '../cubit/network_status_state.dart';

class GlobalNetworkGate extends StatelessWidget {
  final Widget child;

  const GlobalNetworkGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkStatusCubit, NetworkStatusState>(
      builder: (context, state) {
        final isBlocked = state.blocksInteraction;

        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeFocus(
              excluding: isBlocked,
              child: AbsorbPointer(absorbing: isBlocked, child: child),
            ),
            if (isBlocked) ...[
              const ModalBarrier(dismissible: false, color: Colors.transparent),
              Align(
                alignment: Alignment.topCenter,
                child: _NetworkGateBanner(state: state),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _NetworkGateBanner extends StatelessWidget {
  final NetworkStatusState state;

  const _NetworkGateBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isChecking =
        state is NetworkStatusInitial || state is NetworkStatusChecking;
    final isFailure = state is NetworkStatusFailure;

    final title = isChecking
        ? l10n.networkCheckingTitle
        : isFailure
        ? l10n.networkStatusCheckFailedTitle
        : l10n.networkOfflineTitle;
    final message = isChecking
        ? l10n.networkCheckingMessage
        : isFailure
        ? l10n.networkStatusCheckFailedMessage
        : l10n.networkOfflineMessage;

    return SafeArea(
      bottom: false,
      child: Material(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (isChecking)
                SizedBox.square(
                  dimension: AppSizes.loadingIndicatorSm,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                    color: colorScheme.onErrorContainer,
                  ),
                )
              else
                Icon(
                  AppIcons.networkOffline,
                  color: colorScheme.onErrorContainer,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isChecking) ...[
                const SizedBox(width: AppSpacing.md),
                TextButton.icon(
                  onPressed: () => context.read<NetworkStatusCubit>().retry(),
                  icon: const Icon(AppIcons.resend),
                  label: Text(l10n.networkRetryButton),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
