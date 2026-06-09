import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../cubit/current_company_cubit.dart';
import '../cubit/current_company_state.dart';
import 'company_onboarding_page.dart';

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
    return BlocBuilder<CurrentCompanyCubit, CurrentCompanyState>(
      builder: (context, state) {
        if (state is CurrentCompanyLoading ||
            state is CurrentCompanyInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CurrentCompanyEmpty) {
          return const CompanyOnboardingPage();
        }

        if (state is CurrentCompanyLoaded) {
          return _CurrentCompanyLoadedView(
            companyName: state.context.company.name,
          );
        }

        if (state is CurrentCompanyFailure) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  state.failure.message,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const CompanyOnboardingPage();
      },
    );
  }
}

class _CurrentCompanyLoadedView extends StatelessWidget {
  final String companyName;

  const _CurrentCompanyLoadedView({required this.companyName});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('H.O.R.U.S System')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Company context loaded',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                companyName,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Next step: responsive app shell and protected business modules.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
