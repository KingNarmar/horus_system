import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/payable_invoice.dart';
import '../constants/payments_presentation_constants.dart';
import '../cubit/register_payment_cubit.dart';
import '../cubit/register_payment_state.dart';
import '../helpers/payment_formatters.dart';
import '../helpers/payments_failure_message.dart';
import '../localization/payments_localizations.dart';
import 'payment_balance_summary.dart';

final class RegisterPaymentForm extends StatefulWidget {
  final RegisterPaymentReady state;

  const RegisterPaymentForm({required this.state, super.key});

  @override
  State<RegisterPaymentForm> createState() => _RegisterPaymentFormState();
}

final class _RegisterPaymentFormState extends State<RegisterPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _invoiceId;
  String? _paymentMethodId;
  late DateTime _paymentDate;

  @override
  void initState() {
    super.initState();
    final state = widget.state;
    _invoiceId = state.payableInvoices.isEmpty
        ? null
        : state.payableInvoices.first.invoice.id;
    _paymentMethodId = state.paymentMethods.isEmpty
        ? null
        : state.paymentMethods.first.id;
    _paymentDate = _dateOnly(state.businessDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  PayableInvoice? get _selectedInvoice {
    final invoiceId = _invoiceId;
    if (invoiceId == null) return null;
    for (final item in widget.state.payableInvoices) {
      if (item.invoice.id == invoiceId) return item;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final issueDate = _selectedInvoice?.invoice.issueDate?.value;
    if (issueDate == null) return;

    final firstDate = _dateOnly(issueDate);
    final lastDate = _dateOnly(widget.state.businessDate);
    final initialDate = _paymentDate.isBefore(firstDate)
        ? firstDate
        : _paymentDate.isAfter(lastDate)
        ? lastDate
        : _paymentDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _paymentDate = _dateOnly(picked));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final invoiceId = _invoiceId;
    final paymentMethodId = _paymentMethodId;
    if (invoiceId == null || paymentMethodId == null) return;

    final succeeded = await context.read<RegisterPaymentCubit>().submit(
      invoiceId: invoiceId,
      paymentMethodId: paymentMethodId,
      paymentDate: _paymentDate,
      amountText: _amountController.text,
      referenceNumber: _optional(_referenceController.text),
      notes: _optional(_notesController.text),
    );
    if (succeeded && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final strings = context.paymentsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final fractionDigits =
        state.currentCompanyContext.company.baseCurrencyFractionDigits;

    if (state.payableInvoices.isEmpty) {
      return _EmptyRegistration(message: strings.noPayableInvoices);
    }
    if (state.paymentMethods.isEmpty) {
      return _EmptyRegistration(message: strings.noActivePaymentMethods);
    }
    if (fractionDigits == null) {
      return _EmptyRegistration(message: strings.regionalSettingsFailure);
    }

    final selectedInvoice = _selectedInvoice;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _invoiceId,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.invoice),
              items: state.payableInvoices
                  .map((item) {
                    final invoice = item.invoice;
                    return DropdownMenuItem<String>(
                      value: invoice.id,
                      child: Text(
                        strings.invoiceOption(
                          number:
                              invoice.number?.value ?? strings.unavailableValue,
                          customer: invoice.customer.name,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .toList(growable: false),
              onChanged: state.isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _invoiceId = value;
                        final issueDate =
                            _selectedInvoice?.invoice.issueDate?.value;
                        if (issueDate != null &&
                            _paymentDate.isBefore(_dateOnly(issueDate))) {
                          _paymentDate = _dateOnly(issueDate);
                        }
                      });
                    },
              validator: (value) =>
                  value == null ? strings.invoiceRequired : null,
            ),
            if (selectedInvoice != null) ...[
              const SizedBox(height: AppSpacing.md),
              PaymentBalanceSummary(
                payableInvoice: selectedInvoice,
                fractionDigits: fractionDigits,
                localeName: localeName,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethodId,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.paymentMethod),
              items: state.paymentMethods
                  .map(
                    (method) => DropdownMenuItem<String>(
                      value: method.id,
                      child: Text(method.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: state.isSubmitting
                  ? null
                  : (value) => setState(() => _paymentMethodId = value),
              validator: (value) =>
                  value == null ? strings.paymentMethodRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountController,
              enabled: !state.isSubmitting,
              decoration: InputDecoration(labelText: strings.amount),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? strings.amountRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: state.isSubmitting ? null : _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: strings.paymentDate,
                  suffixIcon: const Icon(AppIcons.calendar),
                ),
                child: Text(formatPaymentDate(_paymentDate, localeName)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _referenceController,
              enabled: !state.isSubmitting,
              decoration: InputDecoration(labelText: strings.referenceNumber),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              enabled: !state.isSubmitting,
              decoration: InputDecoration(labelText: strings.notes),
              maxLines: PaymentsPresentationConstants.notesMaxLines,
            ),
            if (state.submissionFailure != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(paymentsFailureMessage(context, state.submissionFailure!)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(strings.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: state.canSubmit ? _submit : null,
                  child: Text(
                    state.isSubmitting ? strings.submitting : strings.submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _EmptyRegistration extends StatelessWidget {
  final String message;

  const _EmptyRegistration({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
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

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
