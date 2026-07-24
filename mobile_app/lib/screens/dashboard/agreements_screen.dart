import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({Key? key}) : super(key: key);

  @override
  _AgreementsScreenState createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _agreements = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAgreements();
  }

  Future<void> _loadAgreements() async {
    try {
      final response = await _api.get('/agreements/');
      if (mounted) {
        setState(() {
          _agreements = (response as List<dynamic>?) ?? [];
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'draft':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    if (_error != null && !_error!.contains('permission')) {
      return Center(
        child: Text('Error loading agreements:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_agreements.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agreements',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              'Your 60-year wholesale supply contracts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
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
                  const Icon(Icons.handshake, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('NO AGREEMENTS YET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    'Lock in wholesale prices for 60 years by creating your first contract.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {}, // Build contract logic
                    icon: const Icon(Icons.add),
                    label: const Text('Build Your First Contract'),
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
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 16.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agreements',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your 60-year wholesale supply contracts.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle, color: AppTheme.accentColor, size: 32),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final agreement = _agreements[index];
                final status = agreement['status'] ?? 'unknown';
                final statusColor = _getStatusColor(status);
                
                double totalValue = 0;
                if (agreement['total_contract_value'] != null) {
                  totalValue = double.tryParse(agreement['total_contract_value'].toString()) ?? 0;
                }
                
                DateTime? startDate = DateTime.tryParse(agreement['start_date'] ?? '');
                DateTime? endDate = DateTime.tryParse(agreement['end_date'] ?? '');
                
                final dateFormat = DateFormat('dd MMM yyyy');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_getStatusIcon(status), color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (startDate != null && endDate != null)
                                    Text(
                                      '${dateFormat.format(startDate)} → ${dateFormat.format(endDate)}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${totalValue.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                              ),
                              Text(
                                'Total Value',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Items List
                      if (agreement['items'] != null && (agreement['items'] as List).isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ...((agreement['items'] as List).take(3).map((item) {
                              final productName = (item['product'] != null ? item['product']['name'] : null) ?? item['product_id']?.toString().substring(0, 8);
                              final qty = double.tryParse(item['committed_monthly_qty']?.toString() ?? '0') ?? 0;
                              final price = double.tryParse(item['locked_unit_price']?.toString() ?? '0') ?? 0;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              productName,
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${qty.toStringAsFixed(0)} units',
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${price.toStringAsFixed(2)}/unit',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }).toList()),
                            if ((agreement['items'] as List).length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '+ ${(agreement['items'] as List).length - 3} more items',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Quick Action Footer
                      Row(
                        children: [
                          Text(
                            status == 'draft' ? 'Edit Contract' : 'View Details',
                            style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const Icon(Icons.arrow_right_alt, color: AppTheme.accentColor, size: 16),
                          const Spacer(),
                          if (agreement['price_ceiling_agreed'] != null)
                            Row(
                              children: [
                                const Icon(Icons.trending_down, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${agreement['price_ceiling_agreed']}% price ceiling',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: _agreements.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
      ],
    );
  }
}
