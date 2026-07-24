import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminManufacturersScreen extends StatefulWidget {
  const AdminManufacturersScreen({Key? key}) : super(key: key);

  @override
  _AdminManufacturersScreenState createState() => _AdminManufacturersScreenState();
}

class _AdminManufacturersScreenState extends State<AdminManufacturersScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _manufacturers = [];
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
      final manufacturers = await _api.get('/catalog/manufacturers?limit=50');
      if (mounted) {
        setState(() {
          _manufacturers = manufacturers ?? [];
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

  Future<void> _toggleVerification(String id, bool currentStatus) async {
    try {
      await _api.patch('/catalog/manufacturers/$id/status', {
        'is_verified': !currentStatus,
      });
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'Manufacturer verified.' : 'Manufacturer unverified.'),
            backgroundColor: Colors.green,
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

  Widget _buildManufacturersTable() {
    if (_manufacturers.isEmpty) {
      return Center(child: Text('No manufacturers found.', style: TextStyle(color: Colors.grey.shade600)));
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
          DataColumn(label: Text('MANUFACTURER NAME')),
          DataColumn(label: Text('CONTACT EMAIL')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: _manufacturers.map((manufacturer) {
          final bool isVerified = manufacturer['is_verified'] ?? false;
          
          return DataRow(
            cells: [
              DataCell(Text((manufacturer['company_name'] ?? 'Unknown').toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(manufacturer['contact_email'] ?? 'N/A', style: TextStyle(color: Colors.grey.shade600))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.blue.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isVerified ? Colors.blue.shade200 : Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isVerified ? Icons.verified : Icons.pending_actions, size: 14, color: isVerified ? Colors.blue.shade700 : Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'VERIFIED' : 'PENDING',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVerified ? Colors.blue.shade700 : Colors.amber.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.inventory_2, size: 16),
                      label: const Text('Catalogue', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _toggleVerification(manufacturer['id'], isVerified),
                      style: TextButton.styleFrom(
                        backgroundColor: isVerified ? Colors.red.shade50 : AppTheme.accentColor,
                        foregroundColor: isVerified ? Colors.red : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isVerified ? 'Revoke' : 'Verify', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      'MANUFACTURERS',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify and onboard factory accounts.',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search manufacturers...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                      child: _buildManufacturersTable(),
                    ),
        ),
      ],
      ),
    );
  }
}
