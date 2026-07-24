import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AdminAnalyticsScreenState createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  
  Map<String, dynamic>? _metrics;
  List<dynamic>? _trend;
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
      final trend = await _api.get('/analytics/admin/trend');
      
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _trend = trend;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(String title, String subtitle, List<FlSpot> spots, Color color, List<String> labels, bool isCurrency) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          isCurrency ? '₹${value.toInt()}' : value.toInt().toString(),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(labels[index], style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade200, width: 2),
                    left: BorderSide(color: Colors.blue.shade200, width: 2),
                    right: BorderSide(color: Colors.blue.shade200, width: 2),
                    top: BorderSide(color: Colors.blue.shade200, width: 2),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
        body: Center(
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
        ),
      );
    }

    // Extract Metrics
    final int activeHouseholds = _metrics?['total_active_households'] ?? 0;
    final int lifetimeContracts = _metrics?['total_lifetime_contracts'] ?? 0;
    final int corporatePartners = _metrics?['total_corporate_partners'] ?? 0;
    final rawSavings = _metrics?['avg_monthly_saved'] ?? 0;
    final double avgSaved = rawSavings is String ? double.tryParse(rawSavings) ?? 0.0 : (rawSavings as num).toDouble();

    // Extract Trend Data
    List<FlSpot> contractsSpots = [];
    List<FlSpot> savingsSpots = [];
    List<String> labels = [];

    if (_trend != null && _trend!.isNotEmpty) {
      for (int i = 0; i < _trend!.length; i++) {
        final item = _trend![i];
        final double contracts = (item['contracts'] as num).toDouble();
        final double savings = (item['savings'] as num).toDouble();
        
        contractsSpots.add(FlSpot(i.toDouble(), contracts));
        savingsSpots.add(FlSpot(i.toDouble(), savings));
        
        // Parse date for label (e.g. 2026-05-01)
        final period = item['period'] as String;
        labels.add(period);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ANALYTICS',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.accentColor),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),
          ),
          
          // KPI Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildKpiCard('Active Households', activeHouseholds.toString(), Icons.people_outline, Colors.orange),
                _buildKpiCard('Lifetime Contracts', lifetimeContracts.toString(), Icons.shield_outlined, Colors.blue),
                _buildKpiCard('Corporate Partners', corporatePartners.toString(), Icons.domain, Colors.green),
                _buildKpiCard('Avg Monthly Saved', '₹${avgSaved.toStringAsFixed(0)}', Icons.trending_up, Colors.purple),
              ],
            ),
          ),

          // Charts
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildLineChartCard(
                  'GROWTH TREND (CONTRACTS)', 
                  'Historical lifetime contracts signed over the last snapshots', 
                  contractsSpots, 
                  Colors.blue.shade400, 
                  labels,
                  false,
                ),
                const SizedBox(height: 24),
                _buildLineChartCard(
                  'SAVINGS IMPACT', 
                  'Average household monthly savings impact over time', 
                  savingsSpots, 
                  Colors.purple.shade400, 
                  labels,
                  true,
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
