import 'package:flutter/material.dart';

class RouteActivityDialog extends StatelessWidget {
  const RouteActivityDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      title: Text('Route activity'),
      content: Text('Activity timeline will be implemented here.'),
    );
  }
}
