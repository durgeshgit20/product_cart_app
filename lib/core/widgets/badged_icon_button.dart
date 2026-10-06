import 'package:flutter/material.dart';

/// An app-bar icon button with a small badge showing [count], hidden at zero.
class BadgedIconButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final int count;

  /// What a screen reader says for the badge, e.g. "3 in Cart".
  final String badgeSemanticsLabel;
  final VoidCallback onPressed;

  /// Key for the inner [IconButton], so it can be found and tapped.
  final Key? buttonKey;

  const BadgedIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.count,
    required this.badgeSemanticsLabel,
    required this.onPressed,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          key: buttonKey,
          tooltip: tooltip,
          icon: icon,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: CircleAvatar(
                radius: 9,
                backgroundColor: colorScheme.error,
                child: Text(
                  '$count',
                  semanticsLabel: badgeSemanticsLabel,
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
