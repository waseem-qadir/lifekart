import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CorpEmployeesScreen extends StatefulWidget {
  const CorpEmployeesScreen({Key? key}) : super(key: key);

  @override
  _CorpEmployeesScreenState createState() => _CorpEmployeesScreenState();
}

class _CorpEmployeesScreenState extends State<CorpEmployeesScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
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
      final employees = await _api.get('/corporate/partners/me/employees');
      if (mounted) {
        setState(() {
          _employees = employees is List ? employees : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // If 404 (no partner yet), treat as empty list
          final msg = e.toString().replaceAll("Exception: ", "");
          if (msg.toLowerCase().contains('not found')) {
            _employees = [];
            _isLoading = false;
          } else {
            _error = msg;
            _isLoading = false;
          }
        });
      }
    }
  }

  void _showEnrollSheet({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final householdCtrl = TextEditingController(text: existing?['household_id'] ?? '');
    final employeeIdCtrl = TextEditingController(text: existing?['employee_id'] ?? '');
    final departmentCtrl = TextEditingController(text: existing?['department'] ?? '');
    final designationCtrl = TextEditingController(text: existing?['designation'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'EDIT EMPLOYEE' : 'ENROLL EMPLOYEE',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info banner (only for new enrollments)
                  if (!isEdit)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text(
                        'The employee must already have a LifeKart Household account. Enter their Household ID to link their account to your corporate subsidy.',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                      ),
                    ),

                  // Household ID
                  _buildLabel('HOUSEHOLD ID (UUID)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: householdCtrl,
                    enabled: !isEdit,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. 550e8400-e29b-41d4-a716-446655440000',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: isEdit ? Colors.grey.shade100 : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Employee ID
                  _buildLabel('INTERNAL EMPLOYEE ID *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: employeeIdCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. EMP-1042',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Department & Designation
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('DEPARTMENT'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: departmentCtrl,
                              decoration: InputDecoration(
                                hintText: 'Engineering',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('DESIGNATION'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: designationCtrl,
                              decoration: InputDecoration(
                                hintText: 'Senior Eng.',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setModalState(() => isSaving = true);
                                  try {
                                    if (isEdit) {
                                      await _api.patch('/corporate/employees/${existing['id']}', {
                                        'employee_id': employeeIdCtrl.text,
                                        'department': departmentCtrl.text,
                                        'designation': designationCtrl.text,
                                      });
                                    } else {
                                      await _api.post('/corporate/partners/me/employees', {
                                        'household_id': householdCtrl.text.trim(),
                                        'employee_id': employeeIdCtrl.text.trim(),
                                        'department': departmentCtrl.text.trim(),
                                        'designation': designationCtrl.text.trim(),
                                      });
                                    }
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEdit ? 'Employee updated.' : 'Employee enrolled.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadData();
                                    }
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString().replaceAll("Exception: ", "")),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            isSaving ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'ENROLL'),
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(Map<String, dynamic> emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Subsidy', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to revoke ${emp['employee_id']}'s corporate subsidy?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.delete('/corporate/employees/${emp['id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee subsidy revoked.'), backgroundColor: Colors.green),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey.shade500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMPLOYEE ROSTER',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage corporate subsidies for your staff.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.accentColor),
                      onPressed: _loadData,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showEnrollSheet(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text('Enroll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
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
                    : _employees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'NO EMPLOYEES ENROLLED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap the button above to onboard your first employee.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1.0),
                                  dataRowMaxHeight: 72,
                                  dataRowMinHeight: 60,
                                  columnSpacing: 24,
                                  columns: const [
                                    DataColumn(label: Text('EMPLOYEE ID')),
                                    DataColumn(label: Text('DEPT & ROLE')),
                                    DataColumn(label: Text('ENROLLED')),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: _employees.map((emp) {
                                    final enrolledAt = emp['enrolled_at'] ?? '';
                                    String enrolledDate = '';
                                    if (enrolledAt.toString().isNotEmpty) {
                                      try {
                                        final d = DateTime.parse(enrolledAt.toString());
                                        enrolledDate = '${d.day} ${_monthName(d.month)} ${d.year}';
                                      } catch (_) {
                                        enrolledDate = enrolledAt.toString();
                                      }
                                    }

                                    return DataRow(cells: [
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              emp['employee_id']?.toString() ?? '—',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              (emp['household_id'] ?? '').toString().length > 12
                                                  ? '${emp['household_id'].toString().substring(0, 12)}...'
                                                  : emp['household_id']?.toString() ?? '',
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontFamily: 'monospace'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(emp['department']?.toString() ?? '—', style: const TextStyle(fontSize: 13)),
                                            Text(emp['designation']?.toString() ?? '—', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(enrolledDate, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade400),
                                              onPressed: () => _showEnrollSheet(existing: emp),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                                              onPressed: () => _confirmRemove(emp),
                                              tooltip: 'Revoke',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
