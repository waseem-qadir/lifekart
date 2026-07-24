import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminPartnersScreen extends StatefulWidget {
  const AdminPartnersScreen({Key? key}) : super(key: key);

  @override
  _AdminPartnersScreenState createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _partners = [];
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
      final partners = await _api.get('/corporate/partners');
      if (mounted) {
        setState(() {
          _partners = partners ?? [];
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

  Future<void> _handlePartnerAction(String partnerId, bool isSuspend) async {
    try {
      final endpoint = isSuspend ? 'suspend' : 'approve';
      await _api.post('/corporate/partners/$partnerId/$endpoint', {});
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuspend ? 'Partner suspended.' : 'Partner approved.'),
            backgroundColor: isSuspend ? Colors.orange : Colors.green,
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

  Widget _buildPartnersTable() {
    if (_partners.isEmpty) {
      return Center(child: Text('No corporate partners found.', style: TextStyle(color: Colors.grey.shade600)));
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.0),
        dataRowMaxHeight: 70,
        dataRowMinHeight: 60,
        columnSpacing: 48,
        columns: const [
          DataColumn(label: Text('COMPANY NAME')),
          DataColumn(label: Text('CONTACT EMAIL')),
          DataColumn(label: Text('ENROLLED')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: _partners.map((partner) {
          final bool isApproved = partner['status'] == 'active';
          
          return DataRow(
            cells: [
              DataCell(Text((partner['company_name'] ?? 'Unknown').toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(partner['contact_email'] ?? 'N/A', style: TextStyle(color: Colors.grey.shade600))),
              DataCell(Text('${partner['employee_count'] ?? 1}')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isApproved ? Colors.green.shade200 : Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isApproved ? Icons.check_circle_outline : Icons.pending_actions, size: 14, color: isApproved ? Colors.green.shade700 : Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        isApproved ? 'Verified' : 'Pending',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isApproved ? Colors.green.shade700 : Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                TextButton(
                  onPressed: () => _handlePartnerAction(partner['id'], isApproved),
                  style: TextButton.styleFrom(
                    backgroundColor: isApproved ? Colors.red.shade50 : AppTheme.accentColor,
                    foregroundColor: isApproved ? Colors.red : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isApproved ? 'Suspend' : 'Approve', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CORPORATE PARTNERS',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage B2B wholesale agreements and verify new corporate accounts.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
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
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: _buildPartnersTable(),
                    ),
        ),
      ],
      ),
    );
  }
}
