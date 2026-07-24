import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({Key? key}) : super(key: key);

  @override
  _DeliveriesScreenState createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _deliveries = [];
  List<dynamic> _substitutions = [];
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        _api.get('/scheduling/deliveries').catchError((_) => []),
        _api.get('/price-protection/substitutions/me').catchError((_) => []),
        _api.get('/gifting/received/deliveries').catchError((_) => []),
      ]);

      if (mounted) {
        setState(() {
          final myDeliveries = (futures[0] as List<dynamic>?) ?? [];
          final giftedDeliveries = (futures[2] as List<dynamic>?) ?? [];
          
          _deliveries = [...myDeliveries, ...giftedDeliveries];
          _deliveries.sort((a, b) {
            final dateA = DateTime.tryParse(a['scheduled_date'] ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['scheduled_date'] ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA); // Descending
          });
          
          _substitutions = (futures[1] as List<dynamic>?) ?? [];
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered': return Icons.check_circle;
      case 'pending': return Icons.access_time;
      case 'partially_filled': return Icons.warning;
      case 'in_transit': return Icons.local_shipping;
      case 'out_for_delivery': return Icons.airport_shuttle;
      case 'failed': return Icons.cancel;
      case 'returned': return Icons.replay;
      default: return Icons.inventory_2;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered': return Colors.green;
      case 'pending': return Colors.amber;
      case 'partially_filled': return Colors.orange;
      case 'in_transit': return Colors.blue;
      case 'out_for_delivery': return Colors.purple;
      case 'failed': return Colors.red;
      case 'returned': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Widget _buildDeliveryList(bool isActive) {
    final activeStatuses = ['pending', 'partially_filled', 'in_transit', 'out_for_delivery'];
    final historyStatuses = ['delivered', 'returned', 'failed'];

    final filtered = _deliveries.where((d) {
      final status = d['status'] ?? '';
      if (isActive) return activeStatuses.contains(status);
      return historyStatuses.contains(status) || (!activeStatuses.contains(status) && !historyStatuses.contains(status));
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('NO DELIVERIES FOUND', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                isActive ? 'You have no active deliveries right now.' : 'Your delivery history is empty.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final d = filtered[index];
                final status = d['status'] ?? 'unknown';
                final statusColor = _getStatusColor(status);
                
                final productName = (d['product'] != null ? d['product']['name'] : null) ?? 'Product ${d['product_id']?.toString().substring(0, 8)}';
                final qty = double.tryParse(d['quantity']?.toString() ?? '0') ?? 0;
                
                final price = double.tryParse(d['product']?['unit_price_wholesale']?.toString() ?? d['unit_price_applied']?.toString() ?? '0') ?? 0;
                
                final sub = _substitutions.firstWhere(
                  (s) => s['lifetime_subscription_id'] == d['subscription_id'] && s['substitution_type'] == 'TEMPORARY',
                  orElse: () => null,
                );

                final scheduledDate = DateTime.tryParse(d['scheduled_date'] ?? '');
                final actualDate = DateTime.tryParse(d['actual_delivery_date'] ?? '');
                final dateStr = (status == 'delivered' && actualDate != null)
                    ? '${actualDate.day}/${actualDate.month}/${actualDate.year}'
                    : scheduledDate != null
                        ? '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}'
                        : 'Unknown Date';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _showDeliveryDetailsSheet(context, d);
                      },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getStatusIcon(status), color: statusColor, size: 24),
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
                                    Text(
                                      '${qty.ceil()} units · ₹${price.toStringAsFixed(2)}/unit',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                    if (sub != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Text(
                                          '${sub['original_product_name']} is out of stock. We sent ${sub['substituted_product_name']} instead.',
                                          style: TextStyle(color: Colors.blue.shade800, fontSize: 10),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'delivered' ? 'Delivered on: $dateStr' : 'Scheduled for: $dateStr',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ),
                              Text(
                                status.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
              childCount: filtered.length,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    if (_error != null && !_error!.contains('permission')) {
      return Center(
        child: Text('Error loading deliveries:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
          child: Text(
            'DELIVERIES',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.accentColor,
          tabs: const [
            Tab(text: 'ACTIVE TRACKING'),
            Tab(text: 'HISTORY'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDeliveryList(true),
              _buildDeliveryList(false),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeliveryDetailsSheet(BuildContext context, Map<String, dynamic> delivery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveryDetailsSheet(delivery: delivery),
    );
  }
}

class _DeliveryDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const _DeliveryDetailsSheet({Key? key, required this.delivery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = delivery['status'] ?? 'unknown';
    final scheduledDate = DateTime.tryParse(delivery['scheduled_date'] ?? '');
    final actualDate = DateTime.tryParse(delivery['actual_delivery_date'] ?? '');
    
    final productName = (delivery['product'] != null ? delivery['product']['name'] : null) ?? 'Product';
    final qty = double.tryParse(delivery['quantity']?.toString() ?? '0') ?? 0;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DELIVERY DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Status', status.toString().toUpperCase()),
          _buildDetailRow('Product', productName),
          _buildDetailRow('Quantity', '${qty.ceil()} units'),
          _buildDetailRow('Scheduled For', scheduledDate != null ? '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}' : 'N/A'),
          if (actualDate != null)
            _buildDetailRow('Delivered On', '${actualDate.day}/${actualDate.month}/${actualDate.year}'),
          if (delivery['tracking_number'] != null)
            _buildDetailRow('Tracking', delivery['tracking_number']),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
