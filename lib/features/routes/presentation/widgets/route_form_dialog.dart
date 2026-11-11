import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/widgets/app_form_failure_notice.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/route_entity.dart';
import '../localization/routes_localizations_x.dart';
import '../helpers/routes_failure_message.dart';

class RouteFormData {
  final String loadingLocation;
  final String unloadingLocation;
  final String? governorateFrom;
  final String? governorateTo;
  final String? defaultFreightRatePerTonInput;
  final String? notes;

  const RouteFormData({
    required this.loadingLocation,
    required this.unloadingLocation,
    this.governorateFrom,
    this.governorateTo,
    this.defaultFreightRatePerTonInput,
    this.notes,
  });
}

class RouteFormDialog extends StatefulWidget {
  final String title;
  final bool canEditFreightRate;
  final RouteEntity? route;
  final CurrencyConfiguration? financialConfiguration;
  final Future<Failure?> Function(RouteFormData data) onSubmit;

  const RouteFormDialog({
    required this.title,
    required this.canEditFreightRate,
    required this.onSubmit,
    required this.financialConfiguration,
    this.route,
    super.key,
  });

  @override
  State<RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<RouteFormDialog> {
  static const _moneyCodec = MoneyDecimalCodec();
  static const _moneyInputParser = MoneyInputParser();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _loadingController;
  late final TextEditingController _unloadingController;
  late final TextEditingController _governorateFromController;
  late final TextEditingController _governorateToController;
  late final TextEditingController _defaultFreightRateController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;
  Failure? _submissionFailure;

  // Existing Route prices are edited only in the financial-rate dialog.
  bool get _canEnterInitialRate =>
      widget.route == null && widget.canEditFreightRate;

  @override
  void initState() {
    super.initState();

    final route = widget.route;

    _loadingController = TextEditingController(
      text: route?.loadingLocation ?? '',
    );
    _unloadingController = TextEditingController(
      text: route?.unloadingLocation ?? '',
    );
    _governorateFromController = TextEditingController(
      text: route?.governorateFrom ?? '',
    );
    _governorateToController = TextEditingController(
      text: route?.governorateTo ?? '',
    );
    _defaultFreightRateController = TextEditingController(
      text: _formatRate(route),
    );
    _notesController = TextEditingController(text: route?.notes ?? '');
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _unloadingController.dispose();
    _governorateFromController.dispose();
    _governorateToController.dispose();
    _defaultFreightRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title),
          if (_submissionFailure != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppFormFailureNotice(
              message: routesFailureMessage(context, _submissionFailure!),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _loadingController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.loadingLocationLabel,
                  ),
                  validator: (value) {
                    return value == null || value.trim().isEmpty
                        ? l10n.loadingLocationRequired
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _unloadingController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.unloadingLocationLabel,
                  ),
                  validator: (value) {
                    return value == null || value.trim().isEmpty
                        ? l10n.unloadingLocationRequired
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _governorateFromController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.governorateFromLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _governorateToController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.governorateToLabel,
                  ),
                ),
                if (_canEnterInitialRate) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _defaultFreightRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.routeDefaultFreightRatePerTonLabel,
                    ),
                    validator: (_) {
                      return _defaultFreightRateValid
                          ? null
                          : l10n.defaultFreightPriceInvalid;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.routeNotesLabel),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: const Icon(AppIcons.add),
          label: Text(l10n.saveButton),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submissionFailure = null;
    });

    final failure = await widget.onSubmit(
      RouteFormData(
        loadingLocation: _loadingController.text.trim(),
        unloadingLocation: _unloadingController.text.trim(),
        governorateFrom: _optional(_governorateFromController.text),
        governorateTo: _optional(_governorateToController.text),
        defaultFreightRatePerTonInput: _canEnterInitialRate
            ? _optional(_defaultFreightRateController.text)
            : null,
        notes: _optional(_notesController.text),
      ),
    );

    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSubmitting = false;
      _submissionFailure = failure;
    });
  }

  bool get _defaultFreightRateValid {
    final text = _defaultFreightRateController.text.trim();
    if (text.isEmpty) return true;

    final configuration = widget.financialConfiguration;
    if (configuration == null) return false;

    return _moneyInputParser.tryParseMinorUnits(
          text.replaceAll(',', '.'),
          fractionDigits: configuration.fractionDigits,
        ) !=
        null;
  }

  String _formatRate(RouteEntity? route) {
    final rate = route?.defaultFreightRatePerTon;
    if (rate == null) return '';

    final configuration = widget.financialConfiguration;
    if (configuration == null) return '';

    return _moneyCodec.encodeNonNegative(rate, configuration: configuration);
  }

  String? _optional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
