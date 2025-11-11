import 'package:flutter/material.dart';

import '../data/models/inventory.dart';

class TimerProgressIndicator extends StatelessWidget {
  const TimerProgressIndicator({
    super.key,
    required this.value,
    required bool isVisible,
    required this.inventory,
  }) : _isVisible = isVisible;

  final double? value;
  final bool _isVisible;
  final Inventory inventory;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      value: value,
      backgroundColor:
      _isVisible && inventory.duration > 0
          ? Theme.of(context).brightness == Brightness.light
          ? Colors.grey[200]
          : Colors.black
          : null,
      valueColor: AlwaysStoppedAnimation<Color>(
        inventory.isPaused
            ? Colors.amber
            : Theme.of(context).brightness == Brightness.light
            ? Colors.deepPurple
            : Colors.deepPurpleAccent,
      ),
      year2023: false,
    );
  }
}