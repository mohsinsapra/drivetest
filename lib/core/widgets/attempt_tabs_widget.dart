import 'package:flutter/material.dart';

class AttemptTabsWidget extends StatelessWidget {
  final List<String> tabNames;
  final ValueChanged<int> onTabChanged;
  final int selectedIndex;

  const AttemptTabsWidget({
    super.key,
    required this.tabNames,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabNames.length, (index) {
        final isActive = selectedIndex == index;
        return GestureDetector(
          onTap: () => onTabChanged(index),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? Colors.orange : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              tabNames[index],
              style: TextStyle(
                color: isActive ? Colors.orange : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
