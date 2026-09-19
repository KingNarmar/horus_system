import 'package:flutter/material.dart';

import '../../../../core/constants/app_date_constraints.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';

final class FleetLicenseExpirySelection {
  final BusinessDate? newValue;

  const FleetLicenseExpirySelection({this.newValue});
}

Future<FleetLicenseExpirySelection?> selectFleetLicenseExpiryUpdate(
  BuildContext context,
  BusinessDate? currentValue, {
  required BusinessDate currentBusinessDate,
}) async {
  final choice = await showDialog<_ExpiryChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.fleetLicenseExpiryUpdateTitle),
      content: Text(dialogContext.l10n.fleetLicenseExpiryUpdateMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.l10n.cancelButton),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_ExpiryChoice.keepCurrent),
          child: Text(dialogContext.l10n.fleetLicenseExpiryKeepCurrent),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_ExpiryChoice.update),
          child: Text(dialogContext.l10n.fleetLicenseExpiryUpdateButton),
        ),
      ],
    ),
  );

  if (choice == null || !context.mounted) return null;
  if (choice == _ExpiryChoice.keepCurrent) {
    return const FleetLicenseExpirySelection();
  }

  final picked = await showDatePicker(
    context: context,
    initialDate: BusinessDateDateTimeAdapter.toDateTime(
      currentValue ?? currentBusinessDate,
    ),
    firstDate: fleetLicenseExpiryFirstDate(currentBusinessDate),
    lastDate: fleetLicenseExpiryLastDate(currentBusinessDate),
  );
  if (picked == null) return null;
  return FleetLicenseExpirySelection(
    newValue: BusinessDateDateTimeAdapter.fromDateTime(picked),
  );
}

DateTime fleetLicenseExpiryFirstDate(BusinessDate currentBusinessDate) {
  return DateTime(
    currentBusinessDate.year - AppDateConstraints.fleetLicenseExpiryPastYears,
    currentBusinessDate.month,
    currentBusinessDate.day,
  );
}

DateTime fleetLicenseExpiryLastDate(BusinessDate currentBusinessDate) {
  return DateTime(
    currentBusinessDate.year + AppDateConstraints.fleetLicenseExpiryFutureYears,
    currentBusinessDate.month,
    currentBusinessDate.day,
  );
}

enum _ExpiryChoice { keepCurrent, update }
