import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminLegacyClaimsScreen extends StatefulWidget {
  const AdminLegacyClaimsScreen({Key? key}) : super(key: key);

  @override
  _AdminLegacyClaimsScreenState createState() => _AdminLegacyClaimsScreenState();
}

class _AdminLegacyClaimsScreenState extends State<AdminLegacyClaimsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _nominees = [];
  List<dynamic> _claims = [];
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
      final nominees = await _api.get('/legacy/admin/nominees');
      final claims = await _api.get('/legacy/activations?status=pending_verification');
      
      if (mounted) {
        setState(() {
          _nominees = nominees ?? [];
          _claims = claims ?? [];
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

  Future<void> _verifyNominee(String nomineeId) async {
    try {
      await _api.post('/legacy/admin/nominees/$nomineeId/verify', {});
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominee verified successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleClaim(String activationId, bool approve) async {
    try {
      if (approve) {
        await _api.post('/legacy/activations/$activationId/approve', {});
      } else {
        await _api.post('/legacy/activations/$activationId/reject', {
          'rejection_reason': 'Rejected by admin during manual review.'
        });
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Claim approved.' : 'Claim rejected.'),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildNomineesTable() {
    if (_nominees.isEmpty) {
      return Center(child: Text('No pending nominees.', style: TextStyle(color: Colors.grey.shade600)));
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.0),
        dataRowMaxHeight: 80,
        dataRowMinHeight: 60,
        columnSpacing: 32,
        columns: const [
          DataColumn(label: Text('NOMINEE NAME')),
          DataColumn(label: Text('CONTACT EMAIL')),
          DataColumn(label: Text('RELATION')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ACTION')),
        ],
        rows: _nominees.map((nominee) {
          return DataRow(
            cells: [
              DataCell(Text((nominee['nominee_name'] ?? 'Unknown').toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(nominee['nominee_email'] ?? 'N/A')),
              DataCell(Text(nominee['relationship'] ?? 'N/A')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                  child: Text('PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                ),
              ),
              DataCell(
                ElevatedButton(
                  onPressed: () => _verifyNominee(nominee['id']),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Verify Nominee'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      ),
    );
  }

  Widget _buildClaimsTable() {
    if (_claims.isEmpty) {
      return Center(child: Text('No pending death claims.', style: TextStyle(color: Colors.grey.shade600)));
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.0),
        dataRowMaxHeight: 80,
        dataRowMinHeight: 60,
        columnSpacing: 32,
        columns: const [
          DataColumn(label: Text('DATE SUBMITTED')),
          DataColumn(label: Text('DECEASED ACCOUNT')),
          DataColumn(label: Text('NOMINEE DETAILS')),
          DataColumn(label: Text('DOCUMENT')),
          DataColumn(label: Text('ACTION')),
        ],
        rows: _claims.map((claim) {
          return DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jun 23, 2026'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text('1 Subs', style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                    )
                  ],
                ),
              ),
              DataCell(Text(claim['reported_by_name'] ?? 'Unknown')),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nominee - ${claim['relationship'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(claim['reported_by_name'] ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              DataCell(
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description, size: 16, color: Colors.blue),
                  label: const Text('View Certificate', style: TextStyle(color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    side: BorderSide(color: Colors.blue.shade100),
                    elevation: 0,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _handleClaim(claim['id'], false),
                      child: const Text('REJECT CLAIM', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleClaim(claim['id'], true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white, elevation: 0),
                      child: const Text('APPROVE TRANSFER'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEGACY & CLAIMS',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review death verification claims and approve 60-year subscription transfers.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              children: [
                const Expanded(
                  child: TabBar(
                    isScrollable: true,
                    labelColor: AppTheme.accentColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.accentColor,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'DEATH CLAIMS'),
                      Tab(text: 'NOMINEE KYC'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.accentColor),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                : _error != null
                    ? Center(
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
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('FILTER:', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text('Pending', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Icon(Icons.keyboard_arrow_down, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildClaimsTable(),
                                  _buildNomineesTable(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      ),
    );
  }
}
