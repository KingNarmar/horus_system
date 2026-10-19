import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/route_entity.dart';
import '../cubit/route_default_freight_rate_cubit.dart';
import '../helpers/routes_failure_message.dart';
import '../localization/routes_localizations_x.dart';

final class RouteDefaultFreightRateDialog extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;
  final RouteEntity route;

  const RouteDefaultFreightRateDialog({
    required this.currentCompanyContext,
    required this.route,
    super.key,
  });

  @override
  State<RouteDefaultFreightRateDialog> createState() =>
      _RouteDefaultFreightRateDialogState();
}

final class _RouteDefaultFreightRateDialogState
    extends State<RouteDefaultFreightRateDialog> {
  final TextEditingController _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rate = widget.route.defaultFreightRatePerTon;
    final company = widget.currentCompanyContext.company;
    final configuration = CurrencyConfiguration.tryCreate(
      currencyCode: company.baseCurrencyCode,
      fractionDigits: company.baseCurrencyFractionDigits,
    );
    if (rate != null && configuration != null) {
      _rateController.text = const MoneyDecimalCodec().encodeNonNegative(
        rate,
        configuration: configuration,
      );
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<RouteDefaultFreightRateCubit, RouteDefaultFreightRateState>(
      listener: (context, state) {
        if (state is RouteDefaultFreightRateSaved) {
          Navigator.of(context).pop(state.route);
        }
      },
      builder: (context, state) {
        final saving = state is RouteDefaultFreightRateSaving;
        return PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: Text(l10n.routeDefaultFreightRatePerTonLabel),
            content: SizedBox(
              width: AppSizes.formDialogMaxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.route.displayName),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _rateController,
                    enabled: !saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.routeDefaultFreightRatePerTonLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (state is RouteDefaultFreightRateFailure) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      routesFailureMessage(context, state.failure),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () => context.read<RouteDefaultFreightRateCubit>().save(
                        currentCompanyContext: widget.currentCompanyContext,
                        route: widget.route,
                        rateInput: _rateController.text,
                      ),
                child: Text(l10n.saveButton),
              ),
            ],
          ),
        );
      },
    );
  }
}
