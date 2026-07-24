import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CustomerDashboard extends StatefulWidget {
  final Function(int)? onNavigate;

  const CustomerDashboard({Key? key, this.onNavigate}) : super(key: key);

  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final ApiService _api = ApiService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _savings;
  List<dynamic> _subscriptions = [];
  bool _hasHousehold = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        _api.get('/price-protection/savings/me').catchError((_) => null),
        _api.get('/subscriptions/?status=active').catchError((_) => []),
        _api.get('/profiling/households/me').catchError((_) => null),
        _api.get('/gifting/received/subscriptions').catchError((_) => []),
      ]);

      final savingsData = futures[0] as Map<String, dynamic>?;
      final subsData = futures[1] as List<dynamic>? ?? [];
      final householdData = futures[2] as Map<String, dynamic>?;
      final giftedData = futures[3] as List<dynamic>? ?? [];

      final activeGifted = giftedData.where((s) => s['status'] == 'active').toList();

      if (mounted) {
        setState(() {
          _savings = savingsData;
          _subscriptions = [...subsData, ...activeGifted];
          _hasHousehold = householdData != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, int navIndex) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigate != null) widget.onNavigate!(navIndex);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: AppTheme.accentColor.withOpacity(0.6), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final firstName = (user?['full_name'] ?? 'User').split(' ')[0];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    final currentMonthSavings = (_savings?['current_month_savings'] ?? 0).toDouble();
    final totalSaved = (_savings?['total_saved'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $firstName',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            'Your lifetime savings at a glance.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Savings Banner
          if (currentMonthSavings > 0 || totalSaved > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.trending_down, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOU ARE SAVING ₹${currentMonthSavings.toStringAsFixed(0)} THIS MONTH!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.shade800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your LifeKart Price Ceiling automatically locked in lower prices against inflation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Stat Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Monthly Savings', '₹${currentMonthSavings.toStringAsFixed(0)}', Icons.trending_down, 4)), // Invoices tab (Index 4)
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Active Subs', '${_subscriptions.length}', Icons.shopping_bag, 2)), // Subscriptions tab (Index 2)
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard('Total Saved', '₹${totalSaved.toStringAsFixed(0)}', Icons.security, 4), // Invoices tab (Index 4)
          
          const SizedBox(height: 24),

          // Household Prompt
          if (!_hasHousehold)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SET UP YOUR HOUSEHOLD',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add family members to unlock personalized subscriptions.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppTheme.accentColor),
                ],
              ),
            ),

          // Quick Links
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Categories tab (Index 1)
                    if (widget.onNavigate != null) widget.onNavigate!(1); 
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.category, color: AppTheme.accentColor),
                        const SizedBox(height: 12),
                        Text('Browse Categories', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Shop Now →', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Agreements tab (Index 6)
                    if (widget.onNavigate != null) widget.onNavigate!(6);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.handshake, color: AppTheme.accentColor),
                        const SizedBox(height: 12),
                        Text('My Agreements', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('View →', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
