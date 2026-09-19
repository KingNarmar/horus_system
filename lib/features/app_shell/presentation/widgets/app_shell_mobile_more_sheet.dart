import 'package:flutter/material.dart';

import '../models/app_shell_destination.dart';

abstract final class AppShellMobileMoreSheet {
  static void show({
    required BuildContext context,
    required List<AppShellDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: destinations.length,
          itemBuilder: (context, index) {
            final item = destinations[index];

            return ListTile(
              selected: index == selectedIndex,
              leading: Icon(
                index == selectedIndex ? item.selectedIcon : item.icon,
              ),
              title: Text(item.label(context)),
              subtitle: Text(item.description(context)),
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
