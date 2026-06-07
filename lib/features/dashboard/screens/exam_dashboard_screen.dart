import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';
import 'package:upgrader/upgrader.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_body.dart';
import '../widgets/dashboard_error_view.dart';

class ExamDashboardScreen extends StatefulWidget {
  const ExamDashboardScreen({super.key});

  @override
  State<ExamDashboardScreen> createState() => _ExamDashboardScreenState();
}

class _ExamDashboardScreenState extends State<ExamDashboardScreen> {
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().init();
    });
  }

  Future<void> _handleSubscribe() async {
    List<dynamic> products = [];
    try {
      products = await ApiService().fetchBCDSubscriptionProducts();
    } catch (_) {}
    if (!mounted || products.isEmpty) return;

    final result = await PaymentCoordinator.show(
      context,
      products: products,
      createStripeIntent: (p) =>
          ApiService().createBCDPaymentIntent(p['id'] as int),
      onStripePaymentConfirmed: (id) => ApiService().confirmBCDPayment(id),
      onIAPPurchaseConfirmed: (p, transactionId) =>
          ApiService().confirmBCDIAPPurchase(
        (p['id'] as num).toInt(),
        transactionId: transactionId,
      ),
    );

    if (result == null || !mounted) return;
    await DioClient().clearCache();
    BcdCache.instance.invalidate();
    if (mounted) context.read<DashboardProvider>().syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    return UpgradeAlert(
      upgrader: _upgrader,
      dialogStyle: defaultTargetPlatform == TargetPlatform.iOS
          ? UpgradeDialogStyle.cupertino
          : UpgradeDialogStyle.material,
      showIgnore: false,
      showLater: true,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: provider.status == DashboardStatus.error
            ? DashboardErrorView(
                errorKind: provider.errorKind,
                onRetry: () => context.read<DashboardProvider>().init(),
              )
            : DashboardBody(
                provider: provider,
                onSubscribe: _handleSubscribe,
                onRefresh: () => context.read<DashboardProvider>().syncNow(),
              ),
      ),
    );
  }
}

