import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'customer_dashboard.dart';
import 'categories_screen.dart';
import 'agreements_screen.dart';
import 'subscriptions_screen.dart';
import 'deliveries_screen.dart';
import 'invoices_screen.dart';
import 'household_screen.dart';
import 'community_screen.dart';
import 'gifting_screen.dart';
import 'received_gifts_screen.dart';
import 'legacy_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_users_screen.dart';
import 'admin_manufacturers_screen.dart';
import 'admin_routing_rules_screen.dart';
import 'admin_legacy_claims_screen.dart';
import 'admin_partners_screen.dart';
import 'admin_catalogue_screen.dart';
import 'admin_analytics_screen.dart';
import 'corp_overview_screen.dart';
import 'corp_employees_screen.dart';
import 'corp_payroll_screen.dart';
import 'corp_settings_screen.dart';
import 'mfr_overview_screen.dart';
import 'mfr_products_screen.dart';
import 'mfr_settings_screen.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  NavItem(this.label, this.icon, this.screen);
}

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({Key? key}) : super(key: key);

  @override
  _DashboardLayoutState createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _currentIndex = 0;

  // Placeholder for unimplemented screens
  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  List<NavItem> _getNavItems(String role) {
    switch (role) {
      case 'customer':
        return [
          NavItem(
            'Overview',
            Icons.dashboard,
            CustomerDashboard(
              onNavigate: (index) {
                if (mounted && index >= 0 && index < 11) {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
            ),
          ),
          NavItem('Categories', Icons.category, const CategoriesScreen()),
          NavItem('Subscriptions', Icons.shopping_bag, const SubscriptionsScreen()),
          NavItem('Deliveries', Icons.local_shipping, const DeliveriesScreen()),
          NavItem('Invoices', Icons.receipt, const InvoicesScreen()),
          NavItem('Household', Icons.home, const HouseholdScreen()),
          NavItem('Agreements', Icons.handshake, const AgreementsScreen()),
          NavItem('Gifting', Icons.card_giftcard, const GiftingScreen()),
          NavItem('Received Gifts', Icons.redeem, const ReceivedGiftsScreen()),
          NavItem('Community', Icons.people, const CommunityScreen()),
          NavItem('Legacy', Icons.account_balance, const LegacyScreen()),
        ];
      case 'manufacturer':
        return [
          NavItem('Overview', Icons.dashboard, MfrOverviewScreen(
            onNavigate: (index) {
              if (mounted && index >= 0 && index < 3) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
          )),
          NavItem('Products', Icons.inventory_2, const MfrProductsScreen()),
          NavItem('Settings', Icons.settings, const MfrSettingsScreen()),
        ];
      case 'corporate_admin':
        return [
          NavItem('Overview', Icons.dashboard, CorpOverviewScreen(
            onNavigate: (index) {
              if (mounted && index >= 0 && index < 4) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
          )),
          NavItem('Employees', Icons.group, const CorpEmployeesScreen()),
          NavItem('Payroll', Icons.credit_card, const CorpPayrollScreen()),
          NavItem('Settings', Icons.settings, const CorpSettingsScreen()),
        ];
      case 'superadmin':
        return [
          NavItem('Overview', Icons.dashboard, const AdminOverviewScreen()),
          NavItem('Manufacturers', Icons.domain, const AdminManufacturersScreen()),
          NavItem('Routing Rules', Icons.trending_up, const AdminRoutingRulesScreen()),
          NavItem('Legacy & Claims', Icons.security, const AdminLegacyClaimsScreen()),
          NavItem('Users', Icons.group, const AdminUsersScreen()),
          NavItem('Partners', Icons.handshake, const AdminPartnersScreen()),
          NavItem('Catalogue', Icons.inventory_2, const AdminCatalogueScreen()),
          NavItem('Analytics', Icons.analytics, const AdminAnalyticsScreen()),
        ];
      default:
        return [
          NavItem('Overview', Icons.dashboard, const CustomerDashboard()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    
    // Default to customer if role is somehow missing, though it shouldn't be
    final String role = user?['role'] ?? 'customer';
    final navItems = _getNavItems(role);

    // Safety bounds check
    if (_currentIndex >= navItems.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceMuted,
      appBar: AppBar(
        title: Text(navItems[_currentIndex].label),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Custom Drawer Header matching web design
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?['full_name'] ?? 'User',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['email'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Scrollable Navigation List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final isActive = _currentIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isActive ? AppTheme.accentColor : Colors.grey.shade600,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? AppTheme.accentColor : Colors.grey.shade800,
                        ),
                      ),
                      selected: isActive,
                      selectedTileColor: AppTheme.accentColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                        Navigator.pop(context); // Close the drawer
                      },
                    ),
                  );
                },
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade400),
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hoverColor: Colors.red.shade50,
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  auth.logout();
                },
              ),
            ),
          ],
        ),
      ),
      body: navItems[_currentIndex].screen,
    );
  }
}
