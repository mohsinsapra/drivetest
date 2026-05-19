import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/purchase_receipt.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.receipt});
  final PurchaseReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');
    final isIAP = receipt.paymentMethod == 'iap';

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(Translations.of(context).profile_receipt_title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // ── Paper receipt card ──────────────────────────────────────────
            _ReceiptCard(
              cs: cs,
              dateFmt: dateFmt,
              receipt: receipt,
              isIAP: isIAP,
            ),

            const SizedBox(height: 24),

            // ── Copy receipt number ─────────────────────────────────────────
            AppOutlinedButton(
              label: Translations.of(context).profile_receipt_copy_number,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: receipt.receiptNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Translations.of(context).profile_receipt_number_copied),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumWidth: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Paper receipt ─────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.cs,
    required this.dateFmt,
    required this.receipt,
    required this.isIAP,
  });

  final ColorScheme cs;
  final DateFormat dateFmt;
  final PurchaseReceipt receipt;
  final bool isIAP;

  String _durationLabel(int days, Translations t) {
    if (days >= 365) {
      return t.onb_duration_year_access.replaceAll('{n}', '${(days / 365).round()}');
    }
    if (days >= 30) {
      return t.onb_duration_months_access.replaceAll('{n}', '${(days / 30).round()}');
    }
    if (days == 1) return t.onb_duration_one_day;
    return t.onb_duration_days.replaceAll('{n}', '$days');
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header strip ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  t.profile_receipt_payment_receipt,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFmt.format(receipt.purchasedAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Zigzag tear ───────────────────────────────────────────────────
          CustomPaint(
            size: const Size(double.infinity, 14),
            painter: _TearPainter(cardColor: theme.cardColor),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(
                    label: t.profile_receipt_no,
                    value: receipt.receiptNumber,
                    mono: true,
                    highlight: true,
                    cs: cs),
                _divider(),
                _Row(label: t.profile_receipt_product, value: receipt.productName, cs: cs),
                _Row(
                  label: t.profile_receipt_duration,
                  value: receipt.durationDays > 0
                      ? _durationLabel(receipt.durationDays, t)
                      : '—',
                  cs: cs,
                ),
                _divider(),
                _Row(
                  label: t.profile_receipt_amount_paid,
                  value: '${receipt.amount} ${receipt.currency}',
                  bold: true,
                  cs: cs,
                ),
                _Row(
                  label: t.profile_receipt_payment_via,
                  value: isIAP ? t.profile_receipt_via_iap : t.profile_receipt_via_card,
                  cs: cs,
                ),
                _divider(),
                _Row(
                  label: isIAP ? t.profile_receipt_transaction_id : t.profile_receipt_payment_intent,
                  value: receipt.transactionRef.isNotEmpty
                      ? receipt.transactionRef
                      : '—',
                  mono: true,
                  small: true,
                  cs: cs,
                ),
                if (receipt.backendRef != null) ...[
                  _Row(
                    label: t.profile_receipt_reference_no,
                    value: receipt.backendRef!,
                    mono: true,
                    small: true,
                    cs: cs,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    t.profile_receipt_footer,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: List.generate(
            40,
            (i) => Expanded(
              child: Container(
                height: 1,
                color: i.isEven
                    ? cs.outlineVariant.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.cs,
    this.mono = false,
    this.bold = false,
    this.small = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final ColorScheme cs;
  final bool mono;
  final bool bold;
  final bool small;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: small ? 11 : 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: small ? 11 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
                color: highlight ? cs.primary : cs.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashed tear line (zigzag) ─────────────────────────────────────────────────

class _TearPainter extends CustomPainter {
  const _TearPainter({required this.cardColor});
  final Color cardColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = cardColor;
    const r = 7.0;
    final count = (size.width / (r * 2)).ceil() + 1;
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(Offset(i * r * 2 - r, 0), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Purchase history screen ───────────────────────────────────────────────────

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<PurchaseReceipt> _receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final box = await AppStorage.receiptsBox();
      final receipts = box.values
          .map((s) {
            try {
              return PurchaseReceipt.fromJsonString(s);
            } catch (_) {
              return null;
            }
          })
          .whereType<PurchaseReceipt>()
          .toList()
        ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      if (mounted) setState(() => _receipts = receipts);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(t.profile_purchase_history)),
      body: _loading
          ? const Center(child: AppLoadingIndicator())
          : _receipts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 56,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.profile_no_purchases,
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _receipts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = _receipts[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.receipt_long_rounded,
                              color: cs.primary, size: 20),
                        ),
                        title: Text(
                          r.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${r.receiptNumber}  ·  ${dateFmt.format(r.purchasedAt)}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        trailing: Text(
                          '${r.amount} ${r.currency}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ReceiptScreen(receipt: r)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
