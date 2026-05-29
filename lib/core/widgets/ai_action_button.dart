import 'package:flutter/material.dart';

class AiActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AiActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: cs.primary),
      label: Text(label, style: textTheme.labelMedium?.copyWith(color: cs.primary)),
      style: OutlinedButton.styleFrom(
        backgroundColor: cs.primary.withValues(alpha: 0.1),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
    );
  }
}
