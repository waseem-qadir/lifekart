import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class MfrOverviewScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const MfrOverviewScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  _MfrOverviewScreenState createState() => _MfrOverviewScreenState();
}

class _MfrOverviewScreenState extends State<MfrOverviewScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _analytics;
  List<dynamic> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _api.get('/portal/manufacturer/profile').catchError((_) => null);
      final products = await _api.get('/portal/manufacturer/products?limit=10').catchError((_) => <dynamic>[]);
      final analytics = await _api.get('/portal/manufacturer/analytics').catchError((_) => null);

      if (mounted) {
        setState(() {
          _profile = profile;
          _products = products is List ? products : [];
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll("Exception: ", "");
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final companyName = _profile?['company_name'] ?? 'Manufacturer Dashboard';
    final isVerified = _profile?['is_verified'] == true;
    final gstin = _profile?['gstin']?.toString() ?? 'Not set';
    final contractedRevenue = num.tryParse(_analytics?['contracted_revenue']?.toString() ?? '0') ?? 0;
    final activeAgreements = _analytics?['active_agreements'] ?? 0;

    return RefreshIndicator(
      color: AppTheme.accentColor,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              companyName.toString().toUpperCase(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              isVerified ? 'Verified manufacturer' : 'Pending verification',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // KPI Cards Row 1
            Row(
              children: [
                Expanded(child: _buildKpiCard('Products', _products.length.toString(), Icons.inventory_2_outlined, 'Active listings')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Status',
                    isVerified ? 'Verified' : 'Pending',
                    Icons.trending_up,
                    'Verification status',
                    valueColor: isVerified ? Colors.green.shade600 : Colors.red.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildKpiCard('GSTIN', gstin, Icons.badge_outlined, 'Tax identifier'),
            const SizedBox(height: 32),

            // Lifetime Performance
            const Text(
              'LIFETIME PERFORMANCE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),

            // Contracted Revenue — dark card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONTRACTED REVENUE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade400),
                      ),
                      const Icon(Icons.currency_rupee, color: AppTheme.accentColor, size: 22),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${_formatIndianNumber(contractedRevenue)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Locked-in value from 60-year agreements',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Active Agreements card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2), width: 2),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVE AGREEMENTS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade500),
                      ),
                      const Icon(Icons.description_outlined, color: AppTheme.accentColor, size: 22),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$activeAgreements',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Households actively subscribed to your catalog',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Recent Products
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RECENT PRODUCTS',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.onNavigate != null) widget.onNavigate!(1);
                        },
                        child: Row(
                          children: [
                            Text('Manage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.accentColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('NO PRODUCTS LISTED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onNavigate != null) widget.onNavigate!(1);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_products.take(5).map((product) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.inventory_2, size: 20, color: Colors.grey.shade400),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      product['sku']?.toString() ?? '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${product['unit_price_wholesale'] ?? 0}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${product['stock_quantity'] ?? 0} in stock',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, String subtitle, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade400)),
              Icon(icon, color: AppTheme.accentColor.withValues(alpha: 0.6), size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: value.length > 15 ? 16 : 24, color: valueColor ?? Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  String _formatIndianNumber(num value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)} L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} K';
    }
    return value.toStringAsFixed(0);
  }
}
