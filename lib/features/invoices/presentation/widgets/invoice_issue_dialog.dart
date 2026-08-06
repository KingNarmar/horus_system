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

final class InvoiceIssueDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? issueDate;
  final DateTime? dueDate;

  const InvoiceIssueDialog({
    required this.initialDate,
    this.issueDate,
    this.dueDate,
    super.key,
  });

  @override
  State<InvoiceIssueDialog> createState() => _InvoiceIssueDialogState();
}

final class _InvoiceIssueDialogState extends State<InvoiceIssueDialog> {
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _issueDateController,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.issue)),
      ],
    );
  }

  Future<void> _pickDate({required bool isIssueDate}) async {
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final issueDate = _issueDate;
    final dueDate = _dueDate;
    if (issueDate == null || dueDate == null) return;
    Navigator.of(context).pop(
      InvoiceIssueDates(issueDate: issueDate, dueDate: dueDate),
    );
  }
}
