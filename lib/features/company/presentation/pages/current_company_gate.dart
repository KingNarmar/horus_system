import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../app_shell/presentation/pages/app_shell_page.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import 'company_entry_page.dart';

class CurrentCompanyGate extends StatefulWidget {
  const CurrentCompanyGate({super.key});

  @override
  State<CurrentCompanyGate> createState() => _CurrentCompanyGateState();
}

class _CurrentCompanyGateState extends State<CurrentCompanyGate> {
  @override
  void initState() {
    super.initState();
    context.read<CurrentCompanyCubit>().loadCurrentCompanyContext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CurrentCompanyCubit, CurrentCompanyState>(
      builder: (context, state) {
        if (state is CurrentCompanyLoading || state is CurrentCompanyInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CurrentCompanyEmpty) {
          return const CompanyEntryPage();
        }

        if (state is CurrentCompanyLoaded) {
          return AppShellPage(currentCompanyContext: state.context);
        }

        if (state is CurrentCompanyFailure) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.localizedErrorMessage(state.failure),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const CompanyEntryPage();
      },
    );
  }
}
