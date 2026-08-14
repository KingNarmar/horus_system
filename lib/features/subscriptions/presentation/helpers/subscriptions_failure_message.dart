import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../localization/subscriptions_localizations.dart';

String subscriptionsFailureMessage(
  Failure failure,
  SubscriptionsLocalizations l10n,
) {
  return switch (failure.code) {
    FailureCodes.permissionSubscriptionsView => l10n.permissionViewFailure,
    FailureCodes.subscriptionStatusInvalid => l10n.invalidStatusFailure,
    _ => l10n.genericFailure,
  };
}
