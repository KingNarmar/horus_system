import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/auth_user.dart';

class AuthUserIdentitySummary extends StatelessWidget {
  final AuthUser? user;
  final bool compact;

  const AuthUserIdentitySummary({
    required this.user,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = _normalized(user?.fullName);
    final email = _normalized(user?.email);
    final primaryText = name ?? email ?? l10n.unknownUser;
    final secondaryText = name != null ? email : null;
    final hasKnownIdentity = name != null || email != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          child: hasKnownIdentity
              ? Text(_initial(primaryText))
              : const Icon(AppIcons.user),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.signedInAsLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                primaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: compact
                    ? Theme.of(context).textTheme.bodyMedium
                    : Theme.of(context).textTheme.titleMedium,
              ),
              if (!compact && secondaryText != null)
                Text(
                  secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String? _normalized(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _initial(String value) {
    return String.fromCharCode(value.runes.first).toUpperCase();
  }
}
