import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/value_objects/company_timezone.dart';
import '../helpers/company_timezone_display_option.dart';
import '../localization/company_timezone_localizations.dart';

class CompanyTimezoneSelector extends StatelessWidget {
  final List<CompanyTimezone> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  const CompanyTimezoneSelector({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.enabled = true,
    this.validator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = context.companyTimezoneL10n;
    final displayOptions = CompanyTimezoneDisplayResolver.resolveAll(
      options,
      locale,
    );
    final selectedOption = _selectedOption(displayOptions);

    return FormField<String>(
      key: ValueKey<String?>(selectedValue),
      initialValue: selectedValue,
      validator: validator,
      builder: (field) {
        return Semantics(
          button: true,
          enabled: enabled,
          label: l10n.label,
          child: InkWell(
            onTap: enabled
                ? () => _openPicker(context, field, displayOptions)
                : null,
            child: InputDecorator(
              isEmpty: selectedOption == null,
              decoration: InputDecoration(
                labelText: l10n.label,
                hintText: l10n.hint,
                errorText: field.errorText,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(AppIcons.search),
              ),
              child: selectedOption == null
                  ? Text(
                      l10n.hint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    )
                  : _SelectedTimezoneValue(option: selectedOption),
            ),
          ),
        );
      },
    );
  }

  CompanyTimezoneDisplayOption? _selectedOption(
    List<CompanyTimezoneDisplayOption> displayOptions,
  ) {
    for (final option in displayOptions) {
      if (option.value == selectedValue) return option;
    }
    return null;
  }

  Future<void> _openPicker(
    BuildContext context,
    FormFieldState<String> field,
    List<CompanyTimezoneDisplayOption> displayOptions,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _CompanyTimezonePickerDialog(
        options: displayOptions,
        selectedValue: selectedValue,
      ),
    );

    if (selected == null || !context.mounted) return;
    field.didChange(selected);
    onChanged(selected);
  }
}

class _SelectedTimezoneValue extends StatelessWidget {
  final CompanyTimezoneDisplayOption option;

  const _SelectedTimezoneValue({required this.option});

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

class _CompanyTimezonePickerDialog extends StatefulWidget {
  final List<CompanyTimezoneDisplayOption> options;
  final String? selectedValue;

  const _CompanyTimezonePickerDialog({
    required this.options,
    required this.selectedValue,
  });

  @override
  State<_CompanyTimezonePickerDialog> createState() =>
      _CompanyTimezonePickerDialogState();
}

class _CompanyTimezonePickerDialogState
    extends State<_CompanyTimezonePickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyTimezoneL10n;
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
      title: Text(l10n.pickerTitle),
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
                labelText: l10n.searchLabel,
                hintText: l10n.searchHint,
                prefixIcon: const Icon(AppIcons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.clearSearch,
                        onPressed: _clearSearch,
                        icon: const Icon(AppIcons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: filteredOptions.isEmpty
                  ? Center(child: Text(l10n.noResults))
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
