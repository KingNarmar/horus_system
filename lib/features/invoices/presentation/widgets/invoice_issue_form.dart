import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../constants/invoice_presentation_constants.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceIssueDates {
  final BusinessDate issueDate;
  final BusinessDate dueDate;

  const InvoiceIssueDates({required this.issueDate, required this.dueDate});
}

final class InvoiceIssueForm extends StatefulWidget {
  final DateTime initialDate;
  final BusinessDate? issueDate;
  final BusinessDate? dueDate;
  final bool isSubmitting;
  final String? failureMessage;
  final VoidCallback onBack;
  final Future<void> Function(InvoiceIssueDates dates) onSubmit;

  const InvoiceIssueForm({
    required this.initialDate,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
    this.issueDate,
    this.dueDate,
    this.failureMessage,
    super.key,
  });

  @override
  State<InvoiceIssueForm> createState() => _InvoiceIssueFormState();
}

final class _InvoiceIssueFormState extends State<InvoiceIssueForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _issueDateController;
  late final TextEditingController _dueDateController;
  BusinessDate? _issueDate;
  BusinessDate? _dueDate;

  @override
  void initState() {
    super.initState();
    _issueDate = widget.issueDate;
    _dueDate = widget.dueDate;
    _issueDateController = TextEditingController(
      text: formatInvoiceInputDate(_issueDate),
    );
    _dueDateController = TextEditingController(
      text: formatInvoiceInputDate(_dueDate),
    );
  }

  @override
  void dispose() {
    _issueDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _issueDateController,
            enabled: !widget.isSubmitting,
            readOnly: true,
            onTap: () => _pickDate(isIssueDate: true),
            decoration: InputDecoration(
              labelText: strings.issueDate,
              hintText: strings.selectIssueDate,
              suffixIcon: const Icon(AppIcons.calendar),
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? strings.dateRequired : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _dueDateController,
            enabled: !widget.isSubmitting,
            readOnly: true,
            onTap: () => _pickDate(isIssueDate: false),
            decoration: InputDecoration(
              labelText: strings.dueDate,
              hintText: strings.selectDueDate,
              suffixIcon: const Icon(AppIcons.calendar),
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? strings.dateRequired : null,
          ),
          if (widget.failureMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.failureMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: widget.isSubmitting ? null : widget.onBack,
                child: Text(strings.details),
              ),
              FilledButton.icon(
                key: const ValueKey('invoiceIssueSubmitButton'),
                onPressed: widget.isSubmitting ? null : _submit,
                icon: widget.isSubmitting
                    ? const SizedBox.square(
                        dimension: AppSizes.loadingIndicatorSm,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                        ),
                      )
                    : const Icon(AppIcons.statusUpdate),
                label: Text(
                  widget.isSubmitting ? strings.issuing : strings.issue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isIssueDate}) async {
    if (widget.isSubmitting) return;
    final current = isIssueDate ? _issueDate : _dueDate;
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current == null
          ? widget.initialDate
          : BusinessDateDateTimeAdapter.toDateTime(current),
      firstDate: DateTime(InvoicePresentationConstants.minimumSelectableYear),
      lastDate: DateTime(
        now.year + InvoicePresentationConstants.maximumSelectableYearOffset,
      ),
    );
    if (selected == null || !mounted) return;
    final businessDate = BusinessDateDateTimeAdapter.fromDateTime(selected);
    setState(() {
      if (isIssueDate) {
        _issueDate = businessDate;
        _issueDateController.text = formatInvoiceInputDate(businessDate);
      } else {
        _dueDate = businessDate;
        _dueDateController.text = formatInvoiceInputDate(businessDate);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || widget.isSubmitting) return;
    final issueDate = _issueDate;
    final dueDate = _dueDate;
    if (issueDate == null || dueDate == null) return;
    await widget.onSubmit(
      InvoiceIssueDates(issueDate: issueDate, dueDate: dueDate),
    );
  }
}
