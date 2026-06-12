import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_status_filter.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../localization/customers_localizations_x.dart';
import '../widgets/customer_form_dialog.dart';

class CustomersPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const CustomersPage({required this.currentCompanyContext, super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomersCubit>().loadCustomers(widget.currentCompanyContext);
  }

  Future<void> _openCustomerForm({Customer? customer}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CustomerFormDialog(
        customer: customer,
        onSubmit: (data) {
          final cubit = context.read<CustomersCubit>();
          if (customer == null) {
            return cubit.addCustomer(
              name: data.name,
              contactPerson: data.contactPerson,
              phone: data.phone,
              email: data.email,
              taxRegistrationNumber: data.taxRegistrationNumber,
              address: data.address,
              city: data.city,
              country: data.country,
              creditLimit: data.creditLimit,
            );
          }
          return cubit.updateCustomer(
            customer: customer,
            name: data.name,
            contactPerson: data.contactPerson,
            phone: data.phone,
            email: data.email,
            taxRegistrationNumber: data.taxRegistrationNumber,
            address: data.address,
            city: data.city,
            country: data.country,
            creditLimit: data.creditLimit,
          );
        },
      ),
    );
  }

  Future<void> _openCustomerDetails(Customer customer) async {
    final cubit = context.read<CustomersCubit>();
    cubit.loadCustomerActivity(customer);
    await showDialog<void>(
      context: context,
      builder: (_) => BlocBuilder<CustomersCubit, CustomersState>(
        builder: (context, state) {
          return _CustomerDetailsDialog(
            customer: customer,
            state: state is CustomersLoaded ? state : null,
          );
        },
      ),
    );
    cubit.clearCustomerActivity();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        final cubit = context.read<CustomersCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.customersTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (state is CustomersLoaded && state.canManageCustomers)
                  FilledButton.icon(
                    onPressed: () => _openCustomerForm(),
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.addCustomerButton),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _CustomersStateView(
              state: state,
              onRetry: () => cubit.loadCustomers(widget.currentCompanyContext),
              onViewDetails: _openCustomerDetails,
              onEdit: (customer) => _openCustomerForm(customer: customer),
              onDeactivate: cubit.deactivateCustomer,
              onReactivate: cubit.reactivateCustomer,
              onSearchChanged: cubit.setSearchQuery,
              onStatusFilterChanged: cubit.setStatusFilter,
            ),
          ],
        );
      },
    );
  }
}

class _CustomersStateView extends StatelessWidget {
  final CustomersState state;
  final VoidCallback onRetry;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusFilterChanged;

  const _CustomersStateView({
    required this.state,
    required this.onRetry,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentState = state;

    if (currentState is CustomersInitial || currentState is CustomersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentState is CustomersFailure) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Text(
                l10n.localizedErrorMessage(currentState.failure.message),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }

    if (currentState is! CustomersLoaded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomersFilters(
          statusFilter: currentState.statusFilter,
          onSearchChanged: onSearchChanged,
          onStatusFilterChanged: onStatusFilterChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        if (currentState.allCustomers.isEmpty)
          _EmptyCustomersMessage(message: l10n.noCustomersFound)
        else if (currentState.customers.isEmpty)
          _EmptyCustomersMessage(message: l10n.noCustomersMatchFilters)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
                return _CustomersTable(
                  customers: currentState.customers,
                  canManageCustomers: currentState.canManageCustomers,
                  onViewDetails: onViewDetails,
                  onEdit: onEdit,
                  onDeactivate: onDeactivate,
                  onReactivate: onReactivate,
                );
              }
              return _CustomersCards(
                customers: currentState.customers,
                canManageCustomers: currentState.canManageCustomers,
                onViewDetails: onViewDetails,
                onEdit: onEdit,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              );
            },
          ),
      ],
    );
  }
}

class _CustomersFilters extends StatelessWidget {
  final CustomerStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusFilterChanged;

  const _CustomersFilters({
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.searchFieldMaxWidth),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(AppIcons.search),
              hintText: l10n.searchCustomersHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SegmentedButton<CustomerStatusFilter>(
          segments: [
            ButtonSegment(value: CustomerStatusFilter.all, label: Text(l10n.customersStatusAllFilter)),
            ButtonSegment(value: CustomerStatusFilter.active, label: Text(l10n.customersStatusActiveFilter)),
            ButtonSegment(value: CustomerStatusFilter.inactive, label: Text(l10n.customersStatusInactiveFilter)),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selected) => onStatusFilterChanged(selected.first),
        ),
      ],
    );
  }
}

class _EmptyCustomersMessage extends StatelessWidget {
  final String message;

  const _EmptyCustomersMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _CustomersCards extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const _CustomersCards({
    required this.customers,
    required this.canManageCustomers,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: customers
          .map(
            (customer) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CustomerCard(
                customer: customer,
                canManageCustomers: canManageCustomers,
                onViewDetails: onViewDetails,
                onEdit: onEdit,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool canManageCustomers;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const _CustomerCard({
    required this.customer,
    required this.canManageCustomers,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (customer.contactPerson != null) Text(l10n.contactPersonLine(customer.contactPerson!)),
            if (customer.phone != null) Text(l10n.phoneLine(customer.phone!)),
            if (customer.email != null) Text(l10n.emailLine(customer.email!)),
            if (customer.city != null) Text(l10n.cityLine(customer.city!)),
            Text(l10n.statusLine(customer.isActive ? l10n.activeStatus : l10n.inactiveStatus)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onViewDetails(customer),
                  icon: const Icon(AppIcons.view),
                  label: Text(l10n.customerViewDetails),
                ),
                if (canManageCustomers) ...[
                  OutlinedButton.icon(
                    onPressed: () => onEdit(customer),
                    icon: const Icon(AppIcons.edit),
                    label: Text(l10n.editCustomerButton),
                  ),
                  if (customer.isActive)
                    OutlinedButton.icon(
                      onPressed: () => onDeactivate(customer),
                      icon: const Icon(AppIcons.deactivate),
                      label: Text(l10n.deactivateCustomerButton),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => onReactivate(customer),
                      icon: const Icon(AppIcons.reactivate),
                      label: Text(l10n.reactivateCustomerButton),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const _CustomersTable({
    required this.customers,
    required this.canManageCustomers,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSizes.desktopMinWidth),
          child: DataTable(
            columns: [
              DataColumn(label: Text(l10n.customerNameHeader)),
              DataColumn(label: Text(l10n.contactHeader)),
              DataColumn(label: Text(l10n.phoneLabel)),
              DataColumn(label: Text(l10n.emailLabel)),
              DataColumn(label: Text(l10n.cityLabel)),
              DataColumn(label: Text(l10n.statusHeader)),
              DataColumn(label: Text(l10n.actionsHeader)),
            ],
            rows: customers.map((customer) {
              return DataRow(cells: [
                DataCell(Text(customer.name)),
                DataCell(Text(customer.contactPerson ?? '-')),
                DataCell(Text(customer.phone ?? '-')),
                DataCell(Text(customer.email ?? '-')),
                DataCell(Text(customer.city ?? '-')),
                DataCell(Text(customer.isActive ? l10n.activeStatus : l10n.inactiveStatus)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.customerViewDetails,
                      onPressed: () => onViewDetails(customer),
                      icon: const Icon(AppIcons.view),
                    ),
                    if (canManageCustomers) ...[
                      IconButton(
                        tooltip: l10n.editCustomerButton,
                        onPressed: () => onEdit(customer),
                        icon: const Icon(AppIcons.edit),
                      ),
                      if (customer.isActive)
                        IconButton(
                          tooltip: l10n.deactivateCustomerButton,
                          onPressed: () => onDeactivate(customer),
                          icon: const Icon(AppIcons.deactivate),
                        )
                      else
                        IconButton(
                          tooltip: l10n.reactivateCustomerButton,
                          onPressed: () => onReactivate(customer),
                          icon: const Icon(AppIcons.reactivate),
                        ),
                    ],
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CustomerDetailsDialog extends StatelessWidget {
  final Customer customer;
  final CustomersLoaded? state;

  const _CustomerDetailsDialog({required this.customer, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activity = state?.selectedCustomer?.id == customer.id ? state!.selectedCustomerActivity : const <AuditLog>[];
    final isLoading = state?.selectedCustomer?.id == customer.id && (state?.isActivityLoading ?? false);
    final failure = state?.selectedCustomer?.id == customer.id ? state?.activityFailure : null;
    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.detailsDialogMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.customerDetailsTitle(customer.name),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailsSection(
                title: l10n.customerBasicInfo,
                children: [
                  _DetailRow(label: l10n.customerNameLabel, value: customer.name),
                  _DetailRow(label: l10n.contactPersonLabel, value: _optional(customer.contactPerson, l10n)),
                  _DetailRow(label: l10n.phoneLabel, value: _optional(customer.phone, l10n)),
                  _DetailRow(label: l10n.emailLabel, value: _optional(customer.email, l10n)),
                  _DetailRow(label: l10n.addressLabel, value: _optional(customer.address, l10n)),
                  _DetailRow(label: l10n.cityLabel, value: _optional(customer.city, l10n)),
                  _DetailRow(label: l10n.countryLabel, value: _optional(customer.country, l10n)),
                  _DetailRow(label: l10n.taxRegistrationNumberLabel, value: _optional(customer.taxRegistrationNumber, l10n)),
                  _DetailRow(label: l10n.creditLimitLabel, value: customer.creditLimit?.toStringAsFixed(2) ?? l10n.customerEmptyValue),
                  _DetailRow(label: l10n.statusHeader, value: customer.isActive ? l10n.activeStatus : l10n.inactiveStatus),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.customerAccountability,
                children: [
                  _DetailRow(label: l10n.customerCreatedBy, value: _actorName(createdLog, l10n)),
                  _DetailRow(label: l10n.customerCreatedRole, value: l10n.customerAuditRoleLabel(createdLog?.actorRole)),
                  _DetailRow(label: l10n.customerCreatedAt, value: createdLog == null ? l10n.customerNotAvailable : _formatDateTime(context, createdLog.createdAt)),
                  _DetailRow(label: l10n.customerLastActivityBy, value: _actorName(latestLog, l10n)),
                  _DetailRow(label: l10n.customerLastActivityRole, value: l10n.customerAuditRoleLabel(latestLog?.actorRole)),
                  _DetailRow(label: l10n.customerLastActivityAt, value: latestLog == null ? l10n.customerNotAvailable : _formatDateTime(context, latestLog.createdAt)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.customerActivityTimeline,
                children: [
                  if (isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          height: AppSizes.iconSm,
                          width: AppSizes.iconSm,
                          child: CircularProgressIndicator(strokeWidth: AppSizes.loadingIndicatorStrokeWidth),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.customerLoadingActivity),
                      ],
                    )
                  else if (failure != null)
                    Text(l10n.localizedErrorMessage(failure.message))
                  else if (activity.isEmpty)
                    Text(l10n.customerNoActivityFound)
                  else
                    ...activity.map((log) => _ActivityTimelineItem(log: log)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AuditLog? _findOldestAction(List<AuditLog> logs, String action) {
    for (final log in logs.reversed) {
      if (log.action.value == action) return log;
    }
    return null;
  }

  String _actorName(AuditLog? log, AppLocalizations l10n) {
    final name = log?.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log?.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return l10n.customerUnknownUser;
  }

  String _optional(String? value, AppLocalizations l10n) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? l10n.customerEmptyValue : normalized;
  }
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.detailsLabelWidth,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final AuditLog log;

  const _ActivityTimelineItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final changes = _buildChanges(log, l10n);
    final actorName = log.actorDisplayName?.trim().isNotEmpty == true
        ? log.actorDisplayName!.trim()
        : (log.actorEmail?.trim().isNotEmpty == true ? log.actorEmail!.trim() : l10n.customerUnknownUser);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(AppIcons.auditHistory, size: AppSizes.iconSm),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customerAuditActionLabel(log.action.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('$actorName • ${l10n.customerAuditRoleLabel(log.actorRole)} • ${_formatDateTime(context, log.createdAt)}'),
                if (changes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.customerChanges, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  ...changes.map((change) => Text('${change.label}: ${change.oldValue} → ${change.newValue}')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_AuditChange> _buildChanges(AuditLog log, AppLocalizations l10n) {
    final oldValues = log.oldValues;
    final newValues = log.newValues;
    if (oldValues == null || newValues == null) return const [];

    const visibleKeys = [
      'name',
      'contact_person',
      'phone',
      'email',
      'tax_registration_number',
      'address',
      'city',
      'country',
      'credit_limit',
      'is_active',
    ];

    final changes = <_AuditChange>[];
    for (final key in visibleKeys) {
      final oldValue = oldValues[key];
      final newValue = newValues[key];
      if (_valuesEqual(oldValue, newValue)) continue;
      changes.add(
        _AuditChange(
          label: l10n.customerAuditFieldLabel(key),
          oldValue: l10n.customerAuditValueLabel(key, oldValue),
          newValue: l10n.customerAuditValueLabel(key, newValue),
        ),
      );
    }
    return changes;
  }

  bool _valuesEqual(Object? oldValue, Object? newValue) {
    return oldValue?.toString() == newValue?.toString();
  }
}

class _AuditChange {
  final String label;
  final String oldValue;
  final String newValue;

  const _AuditChange({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });
}

String _formatDateTime(BuildContext context, DateTime value) {
  final localValue = value.toLocal();
  final materialLocalizations = MaterialLocalizations.of(context);
  final date = materialLocalizations.formatMediumDate(localValue);
  final time = TimeOfDay.fromDateTime(localValue).format(context);
  return '$date, $time';
}
