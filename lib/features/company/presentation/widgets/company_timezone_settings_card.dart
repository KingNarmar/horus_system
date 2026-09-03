import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/current_company_context.dart';
import '../cubit/company_timezone_cubit.dart';
import '../cubit/company_timezone_state.dart';
import '../cubit/current_company_cubit.dart';
import '../helpers/company_timezone_failure_message.dart';
import '../localization/company_timezone_localizations.dart';

class CompanyTimezoneSettingsCard extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const CompanyTimezoneSettingsCard({
    required this.currentCompanyContext,
    super.key,
  });

  @override
  State<CompanyTimezoneSettingsCard> createState() =>
      _CompanyTimezoneSettingsCardState();
}

class _CompanyTimezoneSettingsCardState
    extends State<CompanyTimezoneSettingsCard> {
  String? _selectedTimezone;

  @override
  void initState() {
    super.initState();
    _selectedTimezone = widget.currentCompanyContext.company.businessTimezone;
  }

  @override
  void didUpdateWidget(covariant CompanyTimezoneSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousTimezone = oldWidget.currentCompanyContext.company.businessTimezone;
    final currentTimezone = widget.currentCompanyContext.company.businessTimezone;
    if (previousTimezone != currentTimezone) {
      _selectedTimezone = currentTimezone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.companyTimezoneL10n;
    final textTheme = Theme.of(context).textTheme;
    final canManage = widget.currentCompanyContext.canManageCompany;

    return BlocConsumer<CompanyTimezoneCubit, CompanyTimezoneState>(
      listener: (context, state) async {
        if (state is CompanyTimezoneSaved) {
          _selectedTimezone = state.company.businessTimezone;
          await context.read<CurrentCompanyCubit>().refreshAndSelectCompany(
            widget.currentCompanyContext.companyId,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.saved)),
          );
          return;
        }

        if (state is CompanyTimezoneFailure && state.options.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(companyTimezoneFailureMessage(state.failure, l10n)),
            ),
          );
        }
      },
      builder: (context, state) {
        final currentTimezone =
            widget.currentCompanyContext.company.businessTimezone;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.description),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.currentValue(currentTimezone ?? l10n.notConfigured),
                ),
                if (canManage) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildEditor(context, state, currentTimezone),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditor(
    BuildContext context,
    CompanyTimezoneState state,
    String? currentTimezone,
  ) {
    final l10n = context.companyTimezoneL10n;

    if (state is CompanyTimezoneInitial || state is CompanyTimezoneLoading) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: AppSpacing.xl,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(l10n.loading)),
        ],
      );
    }

    if (state is CompanyTimezoneFailure && state.options.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(companyTimezoneFailureMessage(state.failure, l10n)),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () =>
                context.read<CompanyTimezoneCubit>().loadOptions(),
            child: Text(l10n.retry),
          ),
        ],
      );
    }

    final options = state.options;
    final isSaving = state is CompanyTimezoneSaving;
    final selectedValue = options.any(
      (option) => option.value == _selectedTimezone,
    )
        ? _selectedTimezone
        : null;
    final hasChange = selectedValue != null && selectedValue != currentTimezone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.label,
            hintText: l10n.hint,
            border: const OutlineInputBorder(),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.value),
                ),
              )
              .toList(growable: false),
          onChanged: isSaving
              ? null
              : (value) => setState(() => _selectedTimezone = value),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: !isSaving && hasChange
              ? () => context
                    .read<CompanyTimezoneCubit>()
                    .updateBusinessTimezone(
                      currentCompanyContext: widget.currentCompanyContext,
                      businessTimezone: selectedValue,
                    )
              : null,
          child: Text(isSaving ? l10n.saving : l10n.save),
        ),
      ],
    );
  }
}
