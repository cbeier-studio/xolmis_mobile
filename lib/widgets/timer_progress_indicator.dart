import 'package:material_ui/material_ui.dart';

import '../data/models/inventory.dart';

/// Displays the circular progress state of an inventory timer with smooth value and color transitions.
class TimerProgressIndicator extends StatelessWidget {
  /// Creates a timer progress indicator for [inventory].
  const TimerProgressIndicator({
    super.key,
    required this.value,
    required bool isVisible,
    required this.inventory,
  }) : _isVisible = isVisible;

  final double? value;
  final bool _isVisible;
  final Inventory inventory;

  Color _getValueColor(BuildContext context, double? progress) {
    if (inventory.isPaused) {
      return Colors.amber;
    }
    if (progress != null && progress >= 0.85) {
      return Colors.redAccent;
    }
    return Theme.of(context).brightness == Brightness.light
        ? Colors.deepPurple
        : Colors.deepPurpleAccent;
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = _getValueColor(context, value);
    final targetValue = (value != null && value!.clamp(0.0, 1.0).isFinite)
        ? value!.clamp(0.0, 1.0)
        : null;

    final backgroundColor = _isVisible && inventory.duration > 0
        ? (Theme.of(context).brightness == Brightness.light
            ? Colors.grey[200]
            : Colors.black)
        : null;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: targetColor, end: targetColor),
      duration: const Duration(milliseconds: 300),
      builder: (context, animatedColor, child) {
        final currentColor = animatedColor ?? targetColor;
        if (targetValue == null) {
          return CircularProgressIndicator(
            value: null,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(currentColor),
            year2023: false,
          );
        }
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: targetValue, end: targetValue),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, animatedProgress, child) {
            return CircularProgressIndicator(
              value: animatedProgress,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(currentColor),
              year2023: false,
            );
          },
        );
      },
    );
  }
}
