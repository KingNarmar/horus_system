import 'package:flutter/material.dart';

import '../models/app_shell_destination.dart';

abstract final class AppShellMobileMoreSheet {
  static void show({
    required BuildContext context,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: appShellDestinations.length,
          itemBuilder: (context, index) {
            final item = appShellDestinations[index];

            return ListTile(
              selected: index == selectedIndex,
              leading: Icon(index == selectedIndex ? item.selectedIcon : item.icon),
              title: Text(item.label),
              subtitle: Text(item.description),
              onTap: () {
                Navigator.of(context).pop();
                onSelect(index);
              },
            );
          },
        ),
      ),
    );
  }
}
