import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
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
  final _noScreenshot = kIsWeb ? null : NoScreenshot.instance;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader();
    _applyScreenshotPolicy();
    AppStorage.allowScreenshotsNotifier.addListener(_applyScreenshotPolicy);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<DashboardProvider>().init();
      if (mounted) _applyScreenshotPolicy();
    });
  }

  @override
  void dispose() {
    AppStorage.allowScreenshotsNotifier.removeListener(_applyScreenshotPolicy);
    super.dispose();
  }

  void _applyScreenshotPolicy() async {
    if (AppStorage.allowScreenshots()) {
      await _noScreenshot?.screenshotOn();
    } else {
      await _noScreenshot?.screenshotOff();
    }
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
      child: CupertinoScaffold(
        body: Scaffold(
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
      ),
    );
  }
}
