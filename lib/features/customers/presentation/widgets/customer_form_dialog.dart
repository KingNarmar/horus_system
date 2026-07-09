import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/customer.dart';

class CustomerFormData {
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? taxRegistrationNumber;
  final String? address;
  final String? city;
  final String? country;
  final double? creditLimit;

  const CustomerFormData({
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.taxRegistrationNumber,
    this.address,
    this.city,
    this.country,
    this.creditLimit,
  });
}

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final Future<void> Function(CustomerFormData data) onSubmit;

  const CustomerFormDialog({required this.onSubmit, this.customer, super.key});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxRegistrationNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _creditLimitController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _nameController.text = customer?.name ?? '';
    _contactPersonController.text = customer?.contactPerson ?? '';
    _phoneController.text = customer?.phone ?? '';
    _emailController.text = customer?.email ?? '';
    _taxRegistrationNumberController.text =
        customer?.taxRegistrationNumber ?? '';
    _addressController.text = customer?.address ?? '';
    _cityController.text = customer?.city ?? '';
    _countryController.text = customer?.country ?? '';
    _creditLimitController.text =
        customer?.creditLimit?.toStringAsFixed(2) ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxRegistrationNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final creditLimitText = _creditLimitController.text.trim();

    await widget.onSubmit(
      CustomerFormData(
        name: _nameController.text,
        contactPerson: _optional(_contactPersonController.text),
        phone: _optional(_phoneController.text),
        email: _optional(_emailController.text),
        taxRegistrationNumber: _optional(_taxRegistrationNumberController.text),
        address: _optional(_addressController.text),
        city: _optional(_cityController.text),
        country: _optional(_countryController.text),
        creditLimit: creditLimitText.isEmpty
            ? null
            : double.tryParse(creditLimitText),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.customer != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.editCustomerTitle : l10n.addCustomerTitle),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TextField(
                  controller: _nameController,
                  label: l10n.customerNameLabel,
                  requiredMessage: l10n.customerNameRequired,
                ),
                _TextField(
                  controller: _contactPersonController,
                  label: l10n.contactPersonLabel,
                ),
                _TextField(
                  controller: _phoneController,
                  label: l10n.phoneLabel,
                ),
                _TextField(
                  controller: _emailController,
                  label: l10n.emailLabel,
                ),
                _TextField(
                  controller: _taxRegistrationNumberController,
                  label: l10n.taxRegistrationNumberLabel,
                ),
                _TextField(
                  controller: _addressController,
                  label: l10n.addressLabel,
                ),
                _TextField(controller: _cityController, label: l10n.cityLabel),
                _TextField(
                  controller: _countryController,
                  label: l10n.countryLabel,
                ),
                _TextField(
                  controller: _creditLimitController,
                  label: l10n.creditLimitLabel,
                  validator: (value) {
                    final normalized = (value ?? '').trim();
                    if (normalized.isEmpty) return null;
                    final parsed = double.tryParse(normalized);
                    if (parsed == null || parsed < 0) {
                      return l10n.creditLimitInvalid;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? requiredMessage;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.label,
    this.requiredMessage,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator:
            validator ??
            (value) {
              if (requiredMessage == null) return null;
              if ((value ?? '').trim().isEmpty) return requiredMessage;
              return null;
            },
      ),
    );
  }
}
