import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_brand_profile.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/failures/company_branding_failure_codes.dart';
import '../cubit/company_branding_cubit.dart';
import '../cubit/company_branding_state.dart';
import '../cubit/current_company_cubit.dart';
import '../helpers/company_brand_logo_file_picker.dart';
import '../localization/company_branding_localizations.dart';
import 'company_brand_logo_selector.dart';

/// Company identity editor. All mutations go Cubit -> Domain -> Data -> RLS.
final class CompanyBrandingSettingsCard extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const CompanyBrandingSettingsCard({
    required this.currentCompanyContext,
    super.key,
  });

  @override
  State<CompanyBrandingSettingsCard> createState() =>
      _CompanyBrandingSettingsCardState();
}

final class _CompanyBrandingSettingsCardState
    extends State<CompanyBrandingSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  final _picker = const CompanyBrandLogoFilePicker();
  final _name = TextEditingController();
  final _businessType = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _registration = TextEditingController();
  String? _loadedCompanyId;

  @override
  void initState() {
    super.initState();
    context.read<CompanyBrandingCubit>().load(widget.currentCompanyContext);
  }

  @override
  void didUpdateWidget(covariant CompanyBrandingSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCompanyContext.companyId !=
        widget.currentCompanyContext.companyId) {
      _loadedCompanyId = null;
      context.read<CompanyBrandingCubit>().load(widget.currentCompanyContext);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _businessType,
      _phone,
      _email,
      _country,
      _city,
      _address,
      _registration,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _populate(CompanyBrandProfile profile) {
    _loadedCompanyId = profile.companyId;
    _name.text = profile.name;
    _businessType.text = profile.businessType ?? '';
    _phone.text = profile.phone ?? '';
    _email.text = profile.email ?? '';
    _country.text = profile.country ?? '';
    _city.text = profile.city ?? '';
    _address.text = profile.address ?? '';
    _registration.text = profile.taxRegistrationNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final brandingL10n = context.companyBrandingL10n;
    final l10n = context.l10n;
    final canManage = widget.currentCompanyContext.canManageCompany;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<CompanyBrandingCubit, CompanyBrandingState>(
      listener: (context, state) async {
        if (state is CompanyBrandingReady) {
          if (_loadedCompanyId != state.profile.companyId ||
              state.notice == CompanyBrandingNotice.profileSaved) {
            _populate(state.profile);
          }
          final failure = state.failure;
          if (failure != null) {
            _showMessage(brandingL10n.errorMessage(failure));
          }
          final notice = state.notice;
          if (notice != null) {
            final message = switch (notice) {
              CompanyBrandingNotice.profileSaved => brandingL10n.profileUpdated,
              CompanyBrandingNotice.logoSaved => brandingL10n.logoUpdated,
              CompanyBrandingNotice.logoRemoved => brandingL10n.logoRemoved,
            };
            _showMessage(message);
            await context
                .read<CurrentCompanyCubit>()
                .refreshSelectedCompanyInPlace(
                  widget.currentCompanyContext.companyId,
                );
          }
        } else if (state is CompanyBrandingFailure) {
          _showMessage(brandingL10n.errorMessage(state.failure));
        }
      },
      builder: (context, state) {
        final profile = switch (state) {
          CompanyBrandingReady(:final profile) => profile,
          CompanyBrandingSaving(:final profile) => profile,
          _ => null,
        };
        final logoBytes = switch (state) {
          CompanyBrandingReady(:final logoBytes) => logoBytes,
          CompanyBrandingSaving(:final logoBytes) => logoBytes,
          _ => null,
        };
        final saving = state is CompanyBrandingSaving;
        final logoFailure = state is CompanyBrandingReady
            ? state.failure?.code
            : null;
        final mustVerifyLogo =
            logoFailure == CompanyBrandingFailureCodes.uploadCompletionUnknown;
        final cleanupPending =
            logoFailure == CompanyBrandingFailureCodes.uploadCleanupPending;
        final canChangeLogo =
            !saving && canManage && !mustVerifyLogo && !cleanupPending;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  brandingL10n.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(brandingL10n.description),
                const SizedBox(height: AppSpacing.lg),
                if (profile == null)
                  if (state is CompanyBrandingFailure)
                    OutlinedButton(
                      onPressed: () => context
                          .read<CompanyBrandingCubit>()
                          .load(widget.currentCompanyContext),
                      child: Text(brandingL10n.retry),
                    )
                  else
                    const Center(child: CircularProgressIndicator())
                else ...[
                  CompanyBrandLogoSelector(
                    imageBytes: logoBytes,
                    hasLogo: profile.logoPath != null,
                    enabled: canChangeLogo,
                    onChoose: canManage ? _chooseLogo : null,
                    onRemove: canManage && profile.logoPath != null
                        ? () => context.read<CompanyBrandingCubit>().removeLogo(
                            widget.currentCompanyContext,
                          )
                        : null,
                  ),
                  if (mustVerifyLogo) ...[
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () => context
                          .read<CompanyBrandingCubit>()
                          .load(widget.currentCompanyContext),
                      child: Text(brandingL10n.reloadProfile),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width =
                            constraints.maxWidth >= AppSizes.dataTableBreakpoint
                            ? (constraints.maxWidth - AppSpacing.md) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            _field(
                              width,
                              _name,
                              l10n.companyNameLabel,
                              readOnly: !canManage || saving,
                              requiredName: true,
                            ),
                            _field(
                              width,
                              _businessType,
                              l10n.businessTypeLabel,
                              readOnly: !canManage || saving,
                            ),
                            _field(
                              width,
                              _phone,
                              l10n.phoneLabel,
                              readOnly: !canManage || saving,
                            ),
                            _field(
                              width,
                              _email,
                              l10n.emailLabel,
                              readOnly: !canManage || saving,
                            ),
                            _field(
                              width,
                              _country,
                              l10n.countryLabel,
                              readOnly: !canManage || saving,
                            ),
                            _field(
                              width,
                              _city,
                              l10n.cityLabel,
                              readOnly: !canManage || saving,
                            ),
                            _field(
                              width,
                              _address,
                              brandingL10n.address,
                              readOnly: !canManage || saving,
                            ),
                            _field(
                              width,
                              _registration,
                              brandingL10n.registration,
                              readOnly: !canManage || saving,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: FilledButton(
                        onPressed: saving ? null : _saveProfile,
                        child: Text(
                          saving ? brandingL10n.saving : brandingL10n.save,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    double width,
    TextEditingController controller,
    String label, {
    required bool readOnly,
    bool requiredName = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: requiredName
            ? (value) => value?.trim().isEmpty ?? true
                  ? context.companyBrandingL10n.nameRequired
                  : null
            : null,
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompanyBrandingCubit>().saveProfile(
      companyContext: widget.currentCompanyContext,
      name: _name.text,
      businessType: _businessType.text,
      phone: _phone.text,
      email: _email.text,
      country: _country.text,
      city: _city.text,
      address: _address.text,
      taxRegistrationNumber: _registration.text,
    );
  }

  Future<void> _chooseLogo() async {
    try {
      final selected = await _picker.pick();
      if (!mounted || selected == null) return;
      await context.read<CompanyBrandingCubit>().uploadLogo(
        companyContext: widget.currentCompanyContext,
        logo: selected,
      );
    } catch (_) {
      if (mounted) {
        _showMessage(context.companyBrandingL10n.imageReadFailed);
      }
    }
  }

  void _showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
