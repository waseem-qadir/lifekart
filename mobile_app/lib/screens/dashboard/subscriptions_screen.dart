import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionsScreenState createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _subscriptions = [];
  List<dynamic> _substitutions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final subsFuture = _api.get('/subscriptions/');
      final substFuture = _api.get('/price-protection/substitutions/me');

      final results = await Future.wait([
        subsFuture.catchError((_) => []),
        substFuture.catchError((_) => []),
      ]);

      if (mounted) {
        setState(() {
          _subscriptions = (results[0] as List<dynamic>?) ?? [];
          _substitutions = (results[1] as List<dynamic>?) ?? [];
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

  Color _getStatusColor(String status, bool pausePending) {
    if (status == 'active' && pausePending) return Colors.amber;
    if (status == 'active') return Colors.green;
    if (status == 'paused') return Colors.amber;
    return Colors.grey;
  }

  String _getStatusText(String status, bool pausePending, bool isSuggested, bool isModified) {
    if (isSuggested && status != 'active') return 'SUGGESTED';
    if (pausePending) return 'PAUSE PENDING';
    if (status == 'paused') return 'ACTIVE (DELIVERIES PAUSED)';
    if (isModified) return 'MODIFIED';
    return status.toUpperCase();
  }

  Future<void> _toggleStatus(String subId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'paused' : 'active';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus == 'paused' ? 'Pause Subscription?' : 'Resume Subscription?'),
        content: Text(newStatus == 'paused' 
          ? 'Are you sure you want to pause this subscription? Future deliveries will be put on hold until you resume.' 
          : 'Are you sure you want to resume this subscription?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: newStatus == 'paused' ? Colors.amber : Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true), 
            child: Text(newStatus == 'paused' ? 'Pause' : 'Resume'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _api.patch('/agreements/me/items/$subId/status', {
        'status': newStatus,
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully ${newStatus == 'paused' ? 'paused' : 'resumed'} subscription.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
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
        child: Text('Error loading subscriptions:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_subscriptions.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MY SUBSCRIPTIONS',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  const Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('NO SUBSCRIPTIONS YET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    'Sign an agreement or create a household to get started.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 24.0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'MY SUBSCRIPTIONS',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sub = _subscriptions[index];
                final status = sub['status'] ?? 'unknown';
                final pausePending = sub['pause_after_next_delivery'] == true;
                final isSuggested = sub['source'] == 'ai_generated';
                
                final isModified = _substitutions.any((s) => s['lifetime_subscription_id'] == sub['id'] && s['substitution_type'] == 'PERMANENT');

                final statusColor = _getStatusColor(status, pausePending);
                final statusText = _getStatusText(status, pausePending, isSuggested, isModified);

                final qty = sub['quantity_per_delivery'] ?? 0;
                final freq = sub['frequency_days'] ?? 0;
                final price = sub['locked_unit_price'] ?? 0;
                final productName = (sub['product'] != null ? sub['product']['name'] : null) ?? 'Product ${sub['product_id']?.toString().substring(0, 8)}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag, color: Colors.grey, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      Text(
                                        '${qty.toStringAsFixed(0)} units × every ${freq}d · ₹$price/unit',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                      if (isSuggested)
                                        const Text(
                                          '· Suggested',
                                          style: TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (status == 'active' || status == 'paused')
                              IconButton(
                                icon: Icon(status == 'active' ? Icons.pause : Icons.play_arrow),
                                color: status == 'active' ? Colors.amber : Colors.green,
                                onPressed: () => _toggleStatus(sub['id'], status),
                              ),
                          ],
                        ),
                      ),
                      if (isModified)
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A product in this subscription was permanently discontinued. Your contract is being fulfilled with an Equal Grade substitute.',
                                  style: TextStyle(color: Colors.red.shade900, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
              childCount: _subscriptions.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
      ],
    );
  }
}
