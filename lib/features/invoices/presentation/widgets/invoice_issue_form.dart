import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../constants/invoice_presentation_constants.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceIssueDates {
  final DateTime issueDate;
  final DateTime dueDate;

  const InvoiceIssueDates({required this.issueDate, required this.dueDate});
}

final class InvoiceIssueForm extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? issueDate;
  final DateTime? dueDate;
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
  DateTime? _issueDate;
  DateTime? _dueDate;

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
    return AlertDialog(
      title: Text(strings.issueTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
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
                  validator: (value) => value == null || value.isEmpty
                      ? strings.dateRequired
                      : null,
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
                  validator: (value) => value == null || value.isEmpty
                      ? strings.dateRequired
                      : null,
                ),
                if (widget.failureMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.failureMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
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
          label: Text(widget.isSubmitting ? strings.issuing : strings.issue),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isIssueDate}) async {
    if (widget.isSubmitting) return;
    final current = isIssueDate ? _issueDate : _dueDate;
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? widget.initialDate,
      firstDate: DateTime(InvoicePresentationConstants.minimumSelectableYear),
      lastDate: DateTime(
        now.year + InvoicePresentationConstants.maximumSelectableYearOffset,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isIssueDate) {
        _issueDate = selected;
        _issueDateController.text = formatInvoiceInputDate(selected);
      } else {
        _dueDate = selected;
        _dueDateController.text = formatInvoiceInputDate(selected);
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
