import 'package:flutter/material.dart';

class UserHeaderWidget extends StatelessWidget {
  final double overallPercentage;

  const UserHeaderWidget({super.key, required this.overallPercentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 180, 139, 251),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.account_circle, // Lucid avatar icon alternative
              size: 48,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Your Performance",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "${(overallPercentage).toStringAsFixed(1)}%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Overall Score",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: overallPercentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
