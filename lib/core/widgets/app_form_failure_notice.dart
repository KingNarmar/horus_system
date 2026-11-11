import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

/// Consistent, accessible non-field submission feedback within editable forms.
class AppFormFailureNotice extends StatelessWidget {
  final String message;

  const AppFormFailureNotice({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(
          // Match the Material 3 SnackBar tone used elsewhere in H.O.R.U.S.
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.bootstrapFailure, color: colors.onInverseSurface),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
