import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_status_filter.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
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
                    icon: const Icon(Icons.add),
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
  static const double _tableBreakpoint = 760;

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
              Text(currentState.failure.message, textAlign: TextAlign.center),
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
              final shouldUseTable = constraints.maxWidth >= _tableBreakpoint;

              if (shouldUseTable) {
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
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchCustomersHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SegmentedButton<CustomerStatusFilter>(
          segments: [
            ButtonSegment(
              value: CustomerStatusFilter.all,
              label: Text(l10n.customersStatusAllFilter),
            ),
            ButtonSegment(
              value: CustomerStatusFilter.active,
              label: Text(l10n.customersStatusActiveFilter),
            ),
            ButtonSegment(
              value: CustomerStatusFilter.inactive,
              label: Text(l10n.customersStatusInactiveFilter),
            ),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selected) =>
              onStatusFilterChanged(selected.first),
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
    final text = _CustomerActivityText(l10n.localeName);

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
            if (customer.contactPerson != null)
              Text(l10n.contactPersonLine(customer.contactPerson!)),
            if (customer.phone != null) Text(l10n.phoneLine(customer.phone!)),
            if (customer.email != null) Text(l10n.emailLine(customer.email!)),
            if (customer.city != null) Text(l10n.cityLine(customer.city!)),
            Text(
              l10n.statusLine(
                customer.isActive ? l10n.activeStatus : l10n.inactiveStatus,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onViewDetails(customer),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(text.viewDetails),
                ),
                if (canManageCustomers) ...[
                  OutlinedButton.icon(
                    onPressed: () => onEdit(customer),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.editCustomerButton),
                  ),
                  if (customer.isActive)
                    OutlinedButton.icon(
                      onPressed: () => onDeactivate(customer),
                      icon: const Icon(Icons.block_outlined),
                      label: Text(l10n.deactivateCustomerButton),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => onReactivate(customer),
                      icon: const Icon(Icons.check_circle_outline),
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
    final text = _CustomerActivityText(l10n.localeName);

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
              return DataRow(
                cells: [
                  DataCell(Text(customer.name)),
                  DataCell(Text(customer.contactPerson ?? '-')),
                  DataCell(Text(customer.phone ?? '-')),
                  DataCell(Text(customer.email ?? '-')),
                  DataCell(Text(customer.city ?? '-')),
                  DataCell(
                    Text(
                      customer.isActive
                          ? l10n.activeStatus
                          : l10n.inactiveStatus,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: text.viewDetails,
                          onPressed: () => onViewDetails(customer),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        if (canManageCustomers) ...[
                          IconButton(
                            tooltip: l10n.editCustomerButton,
                            onPressed: () => onEdit(customer),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          if (customer.isActive)
                            IconButton(
                              tooltip: l10n.deactivateCustomerButton,
                              onPressed: () => onDeactivate(customer),
                              icon: const Icon(Icons.block_outlined),
                            )
                          else
                            IconButton(
                              tooltip: l10n.reactivateCustomerButton,
                              onPressed: () => onReactivate(customer),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
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
    final text = _CustomerActivityText(l10n.localeName);
    final activity = state?.selectedCustomer?.id == customer.id
        ? state!.selectedCustomerActivity
        : const <AuditLog>[];
    final isLoading = state?.selectedCustomer?.id == customer.id &&
        (state?.isActivityLoading ?? false);
    final failure = state?.selectedCustomer?.id == customer.id
        ? state?.activityFailure
        : null;
    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
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
                      text.customerDetailsTitle(customer.name),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailsSection(
                title: text.basicInfo,
                children: [
                  _DetailRow(label: l10n.customerNameLabel, value: customer.name),
                  _DetailRow(
                    label: l10n.contactPersonLabel,
                    value: _optional(customer.contactPerson, text),
                  ),
                  _DetailRow(label: l10n.phoneLabel, value: _optional(customer.phone, text)),
                  _DetailRow(label: l10n.emailLabel, value: _optional(customer.email, text)),
                  _DetailRow(label: l10n.addressLabel, value: _optional(customer.address, text)),
                  _DetailRow(label: l10n.cityLabel, value: _optional(customer.city, text)),
                  _DetailRow(label: l10n.countryLabel, value: _optional(customer.country, text)),
                  _DetailRow(
                    label: l10n.taxRegistrationNumberLabel,
                    value: _optional(customer.taxRegistrationNumber, text),
                  ),
                  _DetailRow(
                    label: l10n.creditLimitLabel,
                    value: customer.creditLimit?.toStringAsFixed(2) ?? text.empty,
                  ),
                  _DetailRow(
                    label: l10n.statusHeader,
                    value: customer.isActive ? l10n.activeStatus : l10n.inactiveStatus,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: text.accountability,
                children: [
                  _DetailRow(
                    label: text.createdBy,
                    value: _actorName(createdLog, text),
                  ),
                  _DetailRow(
                    label: text.createdRole,
                    value: text.roleLabel(createdLog?.actorRole, l10n),
                  ),
                  _DetailRow(
                    label: text.createdAt,
                    value: createdLog == null
                        ? text.notAvailable
                        : _formatDateTime(context, createdLog.createdAt),
                  ),
                  _DetailRow(
                    label: text.lastActivityBy,
                    value: _actorName(latestLog, text),
                  ),
                  _DetailRow(
                    label: text.lastActivityRole,
                    value: text.roleLabel(latestLog?.actorRole, l10n),
                  ),
                  _DetailRow(
                    label: text.lastActivityAt,
                    value: latestLog == null
                        ? text.notAvailable
                        : _formatDateTime(context, latestLog.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: text.activityTimeline,
                children: [
                  if (isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(text.loadingActivity),
                      ],
                    )
                  else if (failure != null)
                    Text(failure.message)
                  else if (activity.isEmpty)
                    Text(text.noActivityFound)
                  else
                    ...activity.map(
                      (log) => _ActivityTimelineItem(log: log, text: text),
                    ),
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

  String _actorName(AuditLog? log, _CustomerActivityText text) {
    final name = log?.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log?.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return text.unknownUser;
  }

  String _optional(String? value, _CustomerActivityText text) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? text.empty : normalized;
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
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final AuditLog log;
  final _CustomerActivityText text;

  const _ActivityTimelineItem({required this.log, required this.text});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final changes = _buildChanges(log, l10n, text);
    final actorName = log.actorDisplayName?.trim().isNotEmpty == true
        ? log.actorDisplayName!.trim()
        : (log.actorEmail?.trim().isNotEmpty == true
            ? log.actorEmail!.trim()
            : text.unknownUser);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.history, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.actionLabel(log.action.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$actorName • ${text.roleLabel(log.actorRole, l10n)} • ${_formatDateTime(context, log.createdAt)}',
                ),
                if (changes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    text.changes,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...changes.map(
                    (change) => Text(
                      '${change.label}: ${change.oldValue} → ${change.newValue}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_AuditChange> _buildChanges(
    AuditLog log,
    dynamic l10n,
    _CustomerActivityText text,
  ) {
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
          label: text.fieldLabel(key, l10n),
          oldValue: text.valueLabel(key, oldValue, l10n),
          newValue: text.valueLabel(key, newValue, l10n),
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

class _CustomerActivityText {
  final String localeName;

  const _CustomerActivityText(this.localeName);

  bool get isArabic => localeName.startsWith('ar');

  String get viewDetails => isArabic ? 'التفاصيل' : 'Details';
  String get basicInfo => isArabic ? 'البيانات الأساسية' : 'Basic information';
  String get accountability => isArabic ? 'المسؤولية والمتابعة' : 'Accountability';
  String get activityTimeline => isArabic ? 'سجل النشاط' : 'Activity timeline';
  String get createdBy => isArabic ? 'أنشأه' : 'Created by';
  String get createdRole => isArabic ? 'دور المنشئ' : 'Created role';
  String get createdAt => isArabic ? 'تاريخ الإنشاء' : 'Created at';
  String get lastActivityBy => isArabic ? 'آخر إجراء بواسطة' : 'Last activity by';
  String get lastActivityRole => isArabic ? 'دور آخر مستخدم' : 'Last activity role';
  String get lastActivityAt => isArabic ? 'وقت آخر إجراء' : 'Last activity at';
  String get loadingActivity => isArabic ? 'جاري تحميل سجل النشاط...' : 'Loading activity...';
  String get noActivityFound => isArabic ? 'لا يوجد نشاط مسجل لهذا العميل.' : 'No activity found for this customer.';
  String get changes => isArabic ? 'التغييرات' : 'Changes';
  String get empty => isArabic ? 'فارغ' : 'Empty';
  String get unknownUser => isArabic ? 'مستخدم غير معروف' : 'Unknown user';
  String get notAvailable => isArabic ? 'غير متاح' : 'Not available';

  String customerDetailsTitle(String name) {
    return isArabic ? 'تفاصيل $name' : 'Customer details: $name';
  }

  String actionLabel(String action) {
    return switch (action) {
      'created' => isArabic ? 'تم الإنشاء' : 'Created',
      'updated' => isArabic ? 'تم التعديل' : 'Updated',
      'deactivated' => isArabic ? 'تم التعطيل' : 'Deactivated',
      'reactivated' => isArabic ? 'تم التفعيل' : 'Reactivated',
      'status_changed' => isArabic ? 'تم تغيير الحالة' : 'Status changed',
      _ => action,
    };
  }

  String roleLabel(String? role, dynamic l10n) {
    if (role == null || role.trim().isEmpty) return notAvailable;

    return switch (role) {
      'owner' => l10n.roleOwner,
      'admin' => l10n.roleAdmin,
      'operations' => l10n.roleOperations,
      'accountant' => l10n.roleAccountant,
      'viewer' => l10n.roleViewer,
      'driver' => l10n.roleDriver,
      _ => role,
    };
  }

  String fieldLabel(String key, dynamic l10n) {
    return switch (key) {
      'name' => l10n.customerNameLabel,
      'contact_person' => l10n.contactPersonLabel,
      'phone' => l10n.phoneLabel,
      'email' => l10n.emailLabel,
      'tax_registration_number' => l10n.taxRegistrationNumberLabel,
      'address' => l10n.addressLabel,
      'city' => l10n.cityLabel,
      'country' => l10n.countryLabel,
      'credit_limit' => l10n.creditLimitLabel,
      'is_active' => l10n.statusHeader,
      _ => key,
    };
  }

  String valueLabel(String key, Object? value, dynamic l10n) {
    if (value == null) return empty;
    final stringValue = value.toString().trim();
    if (stringValue.isEmpty) return empty;

    if (key == 'is_active') {
      if (value == true || stringValue == 'true') return l10n.activeStatus;
      if (value == false || stringValue == 'false') return l10n.inactiveStatus;
    }

    return stringValue;
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final localValue = value.toLocal();
  final materialLocalizations = MaterialLocalizations.of(context);
  final date = materialLocalizations.formatMediumDate(localValue);
  final time = TimeOfDay.fromDateTime(localValue).format(context);
  return '$date, $time';
}
