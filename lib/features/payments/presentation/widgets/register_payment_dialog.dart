import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../cubit/register_payment_cubit.dart';
import '../cubit/register_payment_state.dart';
import '../helpers/payments_failure_message.dart';
import '../localization/payments_localizations.dart';
import 'register_payment_form.dart';

final class RegisterPaymentDialog extends StatelessWidget {
  const RegisterPaymentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;

    return AlertDialog(
      title: Text(strings.registrationTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: BlocBuilder<RegisterPaymentCubit, RegisterPaymentState>(
          builder: (context, state) {
            return switch (state) {
              RegisterPaymentInitial() || RegisterPaymentLoading() =>
                const Center(child: CircularProgressIndicator()),
              RegisterPaymentFailure(:final failure) => _LoadFailure(
                message: paymentsFailureMessage(context, failure),
                onRetry: context.read<RegisterPaymentCubit>().retryLoad,
              ),
              RegisterPaymentReady() => RegisterPaymentForm(state: state),
            };
          },
        ),
      ),
    );
  }
}

final class _LoadFailure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailure({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
        ),
      ],
    );
  }
}
