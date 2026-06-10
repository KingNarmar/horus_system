import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';

class CompanyLogoutButton extends StatelessWidget {
  const CompanyLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.read<AuthCubit>().logout(),
      icon: const Icon(Icons.logout_outlined),
      label: const Text('Logout'),
    );
  }
}
