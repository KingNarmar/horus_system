import 'package:flutter/widgets.dart';
import 'package:horus_system/features/company/presentation/localization/company_timezone_localizations.dart';
import 'package:test/test.dart';

void main() {
  test('English timezone localization exposes searchable selector guidance', () {
    final l10n = CompanyTimezoneLocalizations.forLocale(const Locale('en'));

    expect(l10n.label, 'Timezone');
    expect(l10n.hint, 'Select the company business timezone');
    expect(l10n.pickerTitle, 'Select timezone');
    expect(l10n.searchHint, 'Search by city or IANA ID');
    expect(l10n.noResults, 'No matching timezones found.');
    expect(l10n.required, 'Business timezone is required.');
  });

  test('Arabic timezone localization exposes searchable selector guidance', () {
    final l10n = CompanyTimezoneLocalizations.forLocale(const Locale('ar'));

    expect(l10n.label, 'المنطقة الزمنية');
    expect(l10n.hint, 'اختر المنطقة الزمنية الخاصة بعمل الشركة');
    expect(l10n.pickerTitle, 'اختيار المنطقة الزمنية');
    expect(l10n.searchHint, 'ابحث باسم المدينة أو معرّف IANA');
    expect(l10n.noResults, 'لم يتم العثور على منطقة زمنية مطابقة.');
    expect(l10n.required, 'المنطقة الزمنية للشركة مطلوبة.');
  });
}
