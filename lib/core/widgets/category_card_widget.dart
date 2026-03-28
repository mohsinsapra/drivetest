import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: category['name'] == 'Karta'
                      ? Colors.green.withValues(alpha: 0.15)
                      : (category['is_subscribed'] == false
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15)),
                  radius: 18,
                  child: Icon(
                    category['name'] == 'Karta'
                        ? LucideIcons.unlock
                        : (category['is_subscribed'] == false
                            ? LucideIcons.lock
                            : LucideIcons.unlock),
                    size: 20,
                    color: category['name'] == 'Karta'
                        ? Colors.green
                        : (category['is_subscribed'] == false
                            ? Colors.red
                            : Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
