import 'package:flutter/material.dart';

class AttemptGroupCard extends StatelessWidget {
  final String licence;
  final String status;
  final String dateRange;

  const AttemptGroupCard({
    super.key,
    required this.licence,
    required this.status,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                licence,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Chip(
                label: Text(status,
                    style: const TextStyle(color: Colors.green)),
                backgroundColor: Colors.green.shade50,
                avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(dateRange, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
