import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import '../providers/dashboard_provider.dart';

class DashboardErrorView extends StatelessWidget {
  const DashboardErrorView({
    super.key,
    required this.errorKind,
    required this.onRetry,
  });

  final DashboardErrorKind errorKind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    final (icon, message) = switch (errorKind) {
      DashboardErrorKind.network => (
          Icons.wifi_off_rounded,
          t.dash_network_error,
        ),
      DashboardErrorKind.server => (
          Icons.cloud_off_rounded,
          t.dash_server_error,
        ),
      DashboardErrorKind.unknown => (
          Icons.error_outline_rounded,
          t.dash_unknown_error,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: cs.error),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            AppFilledButton(
              label: t.dash_retry,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
