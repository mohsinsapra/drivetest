// features/payment/payment_method_sheet.dart

import 'package:flutter/material.dart';

class PaymentMethodSheet extends StatelessWidget {
  final Function(String) onSelected;

  PaymentMethodSheet({super.key, required this.onSelected});

  final List<Map<String, String>> paymentMethods = [
    {'id': 'card', 'name': 'Card'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Set a height or let it adjust based on content
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          ...paymentMethods.map((method) {
            return ListTile(
              leading: _getPaymentMethodIcon(method['id']!),
              title: Text(method['name']!),
              onTap: () {
                onSelected(method['id']!);
              },
            );
          }),
        ],
      ),
    );
  }

  // Helper method to get icons based on payment method
  Widget _getPaymentMethodIcon(String methodId) {
    switch (methodId) {
      case 'card':
        return const Icon(Icons.credit_card);
      case 'google_pay':
        return Image.asset(
          'assets/google_pay.png', // Ensure you have this asset
          width: 24,
          height: 24,
        );
      case 'apple_pay':
        return Image.asset(
          'assets/apple_pay.png', // Ensure you have this asset
          width: 24,
          height: 24,
        );
      // Add more cases as needed
      default:
        return const Icon(Icons.payment);
    }
  }
}
