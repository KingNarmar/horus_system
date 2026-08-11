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
    return BlocBuilder<RegisterPaymentCubit, RegisterPaymentState>(
      builder: (context, state) {
        final canDismiss =
            state is! RegisterPaymentReady || !state.isSubmitting;

        return PopScope(
          canPop: canDismiss,
          child: AlertDialog(
            title: Text(context.paymentsL10n.registrationTitle),
            content: SizedBox(
              width: AppSizes.formDialogMaxWidth,
              child: switch (state) {
                RegisterPaymentInitial() ||
                RegisterPaymentLoading() => const _LoadingRegistration(),
                RegisterPaymentFailure(:final failure) => _LoadFailure(
                  message: paymentsFailureMessage(context, failure),
                  onRetry: context.read<RegisterPaymentCubit>().retryLoad,
                ),
                RegisterPaymentReady() => RegisterPaymentForm(state: state),
              },
            ),
          ),
        );
      },
    );
  }
}

final class _LoadingRegistration extends StatelessWidget {
  const _LoadingRegistration();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.paymentsL10n.cancel),
          ),
        ),
      ],
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
