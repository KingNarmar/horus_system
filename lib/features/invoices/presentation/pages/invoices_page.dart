import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../di/invoices_dependencies.dart';
import '../../domain/entities/invoice.dart';
import '../cubit/invoice_details_cubit.dart';
import '../cubit/invoice_details_state.dart';
import '../cubit/invoices_cubit.dart';
import '../cubit/invoices_state.dart';
import '../localization/invoice_failure_localizations_x.dart';
import '../localization/invoices_localizations.dart';
import '../widgets/invoice_cancel_dialog.dart';
import '../widgets/invoice_details_dialog.dart';
import '../widgets/invoice_draft_dialog.dart';
import '../widgets/invoice_issue_dialog.dart';
import '../widgets/invoices_state_view.dart';

final class InvoicesPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const InvoicesPage({required this.currentCompanyContext, super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

final class _InvoicesPageState extends State<InvoicesPage> {
  @override
  void initState() {
    super.initState();
    context.read<InvoicesCubit>().loadInvoices(widget.currentCompanyContext);
  }

  @override
  void didUpdateWidget(covariant InvoicesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContext = oldWidget.currentCompanyContext;
    final newContext = widget.currentCompanyContext;
    if (oldContext.companyId != newContext.companyId ||
        oldContext.role != newContext.role) {
      context.read<InvoicesCubit>().loadInvoices(newContext);
    }
  }

  Future<void> _openCreateDraft(InvoicesLoaded state) async {
    if (state.billableTrips.isEmpty || state.isBillableTripsLoading) return;
    final cubit = context.read<InvoicesCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => InvoiceDraftDialog(
        billableTrips: state.billableTrips,
        currencyFractionDigits:
            state.currentCompanyContext.company.baseCurrencyFractionDigits ?? 0,
        onSubmit: cubit.createDraftFromTrip,
      ),
    );
  }

  Future<void> _openDetails(Invoice invoice) async {
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider<InvoiceDetailsCubit>(
        create: (_) =>
            InvoicesDependencies.createInvoiceDetailsCubit()
              ..loadInvoiceDetails(
                currentCompanyContext: widget.currentCompanyContext,
                invoiceId: invoice.id,
              ),
        child: _InvoiceDetailsHost(
          currentCompanyContext: widget.currentCompanyContext,
          invoiceId: invoice.id,
        ),
      ),
    );
    if (mounted) {
      await context.read<InvoicesCubit>().refresh();
    }
  }

  void _showListFeedback(BuildContext context, InvoicesLoaded state) {
    final strings = context.invoicesL10n;
    final message = switch (state.feedback) {
      InvoiceListFeedback.draftCreated => strings.draftCreated,
      InvoiceListFeedback.draftUpdated => strings.draftUpdated,
      null =>
        state.mutationFailure == null
            ? null
            : context.localizedInvoiceFailure(state.mutationFailure!),
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    context.read<InvoicesCubit>().clearFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    return BlocConsumer<InvoicesCubit, InvoicesState>(
      listenWhen: (previous, current) {
        if (current is! InvoicesLoaded) return false;
        if (previous is! InvoicesLoaded) {
          return current.feedback != null || current.mutationFailure != null;
        }
        return previous.feedback != current.feedback ||
            previous.mutationFailure != current.mutationFailure;
      },
      listener: (context, state) {
        if (state is InvoicesLoaded) _showListFeedback(context, state);
      },
      builder: (context, state) {
        final cubit = context.read<InvoicesCubit>();
        final loaded = state is InvoicesLoaded ? state : null;
        final canCreate =
            loaded?.canManageInvoiceDrafts == true &&
            loaded!.billableTrips.isNotEmpty &&
            !loaded.isBillableTripsLoading &&
            loaded.billableTripsFailure == null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  strings.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
                final addButton = loaded?.canManageInvoiceDrafts == true
                    ? FilledButton.icon(
                        key: const ValueKey('invoiceAddDraftButton'),
                        onPressed: canCreate
                            ? () => _openCreateDraft(loaded)
                            : null,
                        icon: const Icon(AppIcons.add),
                        label: Text(strings.newDraft),
                      )
                    : null;

                if (constraints.maxWidth < AppSizes.detailsStackBreakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      if (addButton != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        addButton,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    ?addButton,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            InvoicesStateView(
              state: state,
              onRetry: () => cubit.loadInvoices(widget.currentCompanyContext),
              onRetryBillableTrips: () => cubit.loadBillableTrips(),
              onSearchChanged: cubit.setSearchQuery,
              onStatusFilterChanged: cubit.setStatusFilter,
              onViewDetails: _openDetails,
            ),
          ],
        );
      },
    );
  }
}

final class _InvoiceDetailsHost extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;

  const _InvoiceDetailsHost({
    required this.currentCompanyContext,
    required this.invoiceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceDetailsCubit, InvoiceDetailsState>(
      listenWhen: (previous, current) {
        if (current is! InvoiceDetailsLoaded) return false;
        if (previous is! InvoiceDetailsLoaded) {
          return current.feedback != null || current.mutationFailure != null;
        }
        return previous.feedback != current.feedback ||
            previous.mutationFailure != current.mutationFailure;
      },
      listener: (context, state) {
        if (state is! InvoiceDetailsLoaded) return;
        final strings = context.invoicesL10n;
        final message = switch (state.feedback) {
          InvoiceDetailsFeedback.issued => strings.invoiceIssued,
          InvoiceDetailsFeedback.cancelled => strings.invoiceCancelled,
          null =>
            state.mutationFailure == null
                ? null
                : context.localizedInvoiceFailure(state.mutationFailure!),
        };
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<InvoiceDetailsCubit>().clearFeedback();
      },
      builder: (context, state) {
        final cubit = context.read<InvoiceDetailsCubit>();
        return InvoiceDetailsDialog(
          state: state,
          onRetry: () => cubit.loadInvoiceDetails(
            currentCompanyContext: currentCompanyContext,
            invoiceId: invoiceId,
          ),
          onIssue: (invoice) => _issue(context, invoice),
          onCancel: (_) => _cancel(context),
        );
      },
    );
  }

  Future<void> _issue(BuildContext context, Invoice invoice) async {
    final dates = await showDialog<InvoiceIssueDates>(
      context: context,
      builder: (_) => InvoiceIssueDialog(
        initialDate: invoice.issueDate?.value ?? invoice.createdAt,
        issueDate: invoice.issueDate?.value,
        dueDate: invoice.dueDate?.value,
      ),
    );
    if (dates == null || !context.mounted) return;
    await context.read<InvoiceDetailsCubit>().issueInvoice(
      issueDate: dates.issueDate,
      dueDate: dates.dueDate,
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const InvoiceCancelDialog(),
    );
    if (reason == null || !context.mounted) return;
    await context.read<InvoiceDetailsCubit>().cancelInvoice(reason: reason);
  }
}
