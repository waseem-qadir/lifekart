import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

import 'admin_manufacturers_screen.dart';
import 'admin_routing_rules_screen.dart';
import 'admin_legacy_claims_screen.dart';
import 'admin_catalogue_screen.dart';
import 'admin_partners_screen.dart';
import 'admin_users_screen.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({Key? key}) : super(key: key);

  @override
  _AdminOverviewScreenState createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _metrics;
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
      final metrics = await _api.get('/analytics/admin/metrics');
      if (mounted) {
        setState(() {
          _metrics = metrics;
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

  Widget _buildKpiCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AppTheme.accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(String title, String subtitle, IconData icon, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
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
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final activeHouseholds = _metrics?['total_active_households'] ?? 0;
    final totalPartners = _metrics?['total_corporate_partners'] ?? 0;
    final unverifiedMfrs = _metrics?['unverified_manufacturers'] ?? 0;
    final lifetimeContracts = _metrics?['total_lifetime_contracts'] ?? 0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 16.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN DASHBOARD',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  'Platform overview and management',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildKpiCard('Active Households', activeHouseholds.toString(), Icons.groups),
              _buildKpiCard('Corporate Partners', totalPartners.toString(), Icons.domain),
              _buildKpiCard('Unverified Mfrs', unverifiedMfrs.toString(), Icons.shield_outlined),
              _buildKpiCard('Lifetime Contracts', lifetimeContracts.toString(), Icons.shield_outlined),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildNavigationCard(
                'Manufacturers',
                'Verify and onboard factory accounts',
                Icons.domain,
                const AdminManufacturersScreen(),
              ),
              const SizedBox(height: 16),
              _buildNavigationCard(
                'Routing Rules',
                'Configure product substitutes and age progression logic',
                Icons.trending_up,
                const AdminRoutingRulesScreen(),
              ),
              const SizedBox(height: 16),
              _buildNavigationCard(
                'Legacy & Claims',
                'Process death certificates and contract transfers',
                Icons.security,
                const AdminLegacyClaimsScreen(),
              ),
              const SizedBox(height: 16),
              _buildNavigationCard(
                'Manage Catalogue',
                'Create and update product categories',
                Icons.inventory_2,
                const AdminCatalogueScreen(),
              ),
              const SizedBox(height: 16),
              _buildNavigationCard(
                'Approve Partners',
                'Review and approve corporate partnership requests',
                Icons.domain_verification,
                const AdminPartnersScreen(),
              ),
              const SizedBox(height: 16),
              _buildNavigationCard(
                'Manage Users',
                'View, activate, and deactivate user accounts',
                Icons.group,
                const AdminUsersScreen(),
              ),
            ]),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
      ],
    );
  }
}
