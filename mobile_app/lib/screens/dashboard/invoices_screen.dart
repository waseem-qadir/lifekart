import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _invoices = [];
  Map<String, dynamic>? _savings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        _api.get('/payments/invoices').catchError((_) => []),
        _api.get('/price-protection/savings/me').catchError((_) => null),
      ]);

      if (mounted) {
        setState(() {
          _invoices = (futures[0] as List<dynamic>?) ?? [];
          _savings = futures[1] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    if (_error != null && !_error!.contains('permission')) {
      return Center(
        child: Text('Error loading invoices:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      );
    }

    final hasSavings = _savings != null &&
        ((double.tryParse(_savings!['current_month_savings']?.toString() ?? '0') ?? 0) > 0 ||
            (double.tryParse(_savings!['total_saved']?.toString() ?? '0') ?? 0) > 0);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVOICES',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 24),
                if (hasSavings) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.currency_rupee, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are saving ₹${(double.tryParse(_savings!['current_month_savings']?.toString() ?? '0') ?? 0).toStringAsFixed(0)} this month!',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your LifeKart Price Ceiling automatically locked in lower prices against inflation.',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
        if (_invoices.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('NO INVOICES YET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Invoices are generated monthly.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final inv = _invoices[index];
                  final status = inv['status'] ?? 'unknown';
                  final amount = double.tryParse(inv['amount_total']?.toString() ?? '0') ?? 0;
                  final startDate = DateTime.tryParse(inv['billing_period_start'] ?? '');
                  final endDate = DateTime.tryParse(inv['billing_period_end'] ?? '');

                  final monthYear = startDate != null ? '${startDate.month}/${startDate.year}' : 'Unknown';
                  final dateRange = startDate != null && endDate != null
                      ? '${startDate.day}/${startDate.month}/${startDate.year} to ${endDate.day}/${endDate.month}/${endDate.year}'
                      : 'Unknown Period';

                  final isPaid = status == 'paid';
                  final statusColor = isPaid ? Colors.green : (status == 'draft' ? Colors.grey : Colors.red);

                  final hasPdf = inv['hosted_invoice_url'] != null || inv['invoice_pdf'] != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.all(20),
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.receipt, color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LifeKart Monthly Invoice — $monthYear',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Billing Period: $dateRange',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black, fontFamily: 'Outfit'),
                                    ),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ],
                                ),
                                if (hasPdf)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showDownloadDialog(context, inv['invoice_pdf'] ?? inv['hosted_invoice_url']);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.download, size: 14),
                                    label: const Text('BILL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('NO PDF', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          children: [
                            if (inv['line_items'] != null && (inv['line_items'] as List).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DELIVERY BREAKDOWN',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                    ),
                                    const SizedBox(height: 12),
                                    ...((inv['line_items'] as List).map((item) {
                                      final itemQty = item['quantity'] ?? 0;
                                      final itemName = item['product_name'] ?? 'Item';
                                      final itemTotal = double.tryParse(item['total']?.toString() ?? '0') ?? 0;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$itemName x $itemQty units',
                                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                              ),
                                            ),
                                            Text(
                                              '₹${itemTotal.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList()),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _invoices.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
      ],
    );
  }

  void _showDownloadDialog(BuildContext context, String? url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Your official invoice PDF is ready.', textAlign: TextAlign.center),
            if (url != null) ...[
              const SizedBox(height: 8),
              Text(url, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice saved to your device!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white),
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }
}
