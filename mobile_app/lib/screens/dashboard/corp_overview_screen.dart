import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CorpOverviewScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const CorpOverviewScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  _CorpOverviewScreenState createState() => _CorpOverviewScreenState();
}

class _CorpOverviewScreenState extends State<CorpOverviewScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _partner;
  List<dynamic> _employees = [];
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
      final partner = await _api.get('/corporate/partners/me').catchError((_) => null);
      final employees = await _api.get('/corporate/partners/me/employees').catchError((_) => <dynamic>[]);

      if (mounted) {
        setState(() {
          _partner = partner;
          _employees = employees is List ? employees : [];
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

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
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
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(String title, String subtitle, IconData icon, int navIndex) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(navIndex);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade300),
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

    final companyName = _partner?['company_name'] ?? 'Corporate Dashboard';
    final status = _partner?['partnership_status'] ?? 'unknown';
    final activeCount = _employees.where((e) => e['is_active'] == true).length;

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
              'Manage your employee subscriptions and payroll deductions',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Pending Approval Banner
            if (status == 'pending')
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade600, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCOUNT PENDING APPROVAL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your corporate account is under review by LifeKart administrators. Subsidies will not be activated until approved.',
                            style: TextStyle(fontSize: 13, color: Colors.amber.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // KPI Cards
            Row(
              children: [
                Expanded(child: _buildKpiCard('Employees Added', _employees.length.toString(), Icons.people_outline, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('Active Enrollments', activeCount.toString(), Icons.check_circle_outline, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            _buildKpiCard(
              'Account Status',
              status == 'pending' ? 'Pending Approval' : status.toString().toUpperCase(),
              Icons.verified_outlined,
              status == 'active' ? Colors.green : AppTheme.accentColor,
            ),
            const SizedBox(height: 32),

            // Navigation Cards
            _buildNavCard(
              'Manage Employees',
              '${_employees.length} enrollments',
              Icons.group,
              1, // Employees drawer index
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              'Payroll Hub',
              'Generate deduction files',
              Icons.receipt_long,
              2, // Payroll drawer index
            ),
          ],
        ),
      ),
    );
  }
}
