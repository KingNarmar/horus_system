import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../constants/app_spacing.dart';

class AdaptiveAppDialog extends StatelessWidget {
  final Widget title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool canClose;

  const AdaptiveAppDialog({
    required this.title,
    required this.child,
    this.actions = const [],
    this.maxWidth = AppSizes.formDialogMaxWidth,
    this.canClose = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact =
        MediaQuery.sizeOf(context).width <= AppSizes.mobileMaxContentWidth;

    return Dialog(
      insetPadding: isCompact
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            )
          : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: canClose
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
