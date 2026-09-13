import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../helpers/company_currency_display_option.dart';
import '../localization/company_financial_settings_localizations.dart';

class CompanyCurrencySelector extends StatelessWidget {
  final List<CompanyCurrencyDisplayOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const CompanyCurrencySelector({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyFinancialSettingsL10n;
    final selectedOption = _selectedOption();

    return Semantics(
      button: true,
      enabled: enabled,
      label: l10n.baseCurrencyLabel,
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        child: InputDecorator(
          isEmpty: selectedOption == null,
          decoration: InputDecoration(
            labelText: l10n.baseCurrencyLabel,
            hintText: l10n.baseCurrencyHint,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(AppIcons.search),
          ),
          child: selectedOption == null
              ? Text(
                  l10n.baseCurrencyHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                )
              : _SelectedCurrencyValue(option: selectedOption),
        ),
      ),
    );
  }

  CompanyCurrencyDisplayOption? _selectedOption() {
    for (final option in options) {
      if (option.value == selectedValue) return option;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _CompanyCurrencyPickerDialog(
        options: options,
        selectedValue: selectedValue,
      ),
    );

    if (selected == null || !context.mounted) return;
    onChanged(selected);
  }
}

class _SelectedCurrencyValue extends StatelessWidget {
  final CompanyCurrencyDisplayOption option;

  const _SelectedCurrencyValue({required this.option});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(option.localizedName, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xs),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(option.value, style: textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _CompanyCurrencyPickerDialog extends StatefulWidget {
  final List<CompanyCurrencyDisplayOption> options;
  final String? selectedValue;

  const _CompanyCurrencyPickerDialog({
    required this.options,
    required this.selectedValue,
  });

  @override
  State<_CompanyCurrencyPickerDialog> createState() =>
      _CompanyCurrencyPickerDialogState();
}

class _CompanyCurrencyPickerDialogState
    extends State<_CompanyCurrencyPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyFinancialSettingsL10n;
    final filteredOptions = widget.options
        .where((option) => option.matches(_query))
        .toList(growable: false);
    final availableHeight =
        MediaQuery.sizeOf(context).height - (AppSpacing.xxxl * 2);
    final dialogHeight = math.min(
      AppSizes.selectionDialogMaxHeight,
      availableHeight,
    );

    return AlertDialog(
      title: Text(l10n.currencyPickerTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: l10n.currencySearchLabel,
                hintText: l10n.currencySearchHint,
                prefixIcon: const Icon(AppIcons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.currencyClearSearch,
                        onPressed: _clearSearch,
                        icon: const Icon(AppIcons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: filteredOptions.isEmpty
                  ? Center(child: Text(l10n.currencyNoResults))
                  : ListView.separated(
                      itemCount: filteredOptions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = filteredOptions[index];
                        return ListTile(
                          selected: option.value == widget.selectedValue,
                          title: Text(option.localizedName),
                          subtitle: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(option.value),
                          ),
                          onTap: () => Navigator.of(context).pop(option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }
}
