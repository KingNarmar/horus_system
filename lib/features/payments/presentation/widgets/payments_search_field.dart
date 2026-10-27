import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';

/// Keeps the visible search text synchronized with the Cubit's query,
/// including when a reconnect temporarily replaces the Payments list.
final class PaymentsSearchField extends StatefulWidget {
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;

  const PaymentsSearchField({
    required this.query,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  @override
  State<PaymentsSearchField> createState() => _PaymentsSearchFieldState();
}

final class _PaymentsSearchFieldState extends State<PaymentsSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant PaymentsSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.query) return;
    _controller.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(AppIcons.search),
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
