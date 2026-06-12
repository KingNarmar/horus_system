import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../models/app_shell_destination.dart';

class AppShellSidebarNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AppShellSidebarNav({
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: appShellDestinations.length,
      itemBuilder: (context, index) {
        final item = appShellDestinations[index];

        return ListTile(
          selected: selectedIndex == index,
          leading: Icon(selectedIndex == index ? item.selectedIcon : item.icon),
          title: Text(item.label(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          onTap: () => onSelect(index),
        );
      },
    );
  }
}
