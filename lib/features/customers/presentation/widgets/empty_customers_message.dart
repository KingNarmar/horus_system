import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';

class EmptyCustomersMessage extends StatelessWidget {
  final String message;

  const EmptyCustomersMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
