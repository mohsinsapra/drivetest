import 'package:flutter/material.dart';

class CircularProgressRing extends StatelessWidget {
  const CircularProgressRing({
    super.key,
    required this.value,
    required this.label,
    required this.trackColor,
    required this.progressColor,
    required this.textColor,
  });

  final double value;
  final String label;
  final Color trackColor;
  final Color progressColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 4,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
