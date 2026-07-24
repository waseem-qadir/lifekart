import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CorpPayrollScreen extends StatefulWidget {
  const CorpPayrollScreen({Key? key}) : super(key: key);

  @override
  _CorpPayrollScreenState createState() => _CorpPayrollScreenState();
}

class _CorpPayrollScreenState extends State<CorpPayrollScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _deductions = [];
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
      final deductions = await _api.get('/payroll/deductions').catchError((e) {
        if (e.toString().toLowerCase().contains('not found')) return <dynamic>[];
        throw e;
      });
      final employees = await _api.get('/corporate/partners/me/employees').catchError((e) {
        if (e.toString().toLowerCase().contains('not found')) return <dynamic>[];
        throw e;
      });

      if (mounted) {
        setState(() {
          _deductions = deductions is List ? deductions : [];
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

  void _showGenerateSheet() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final startCtrl = TextEditingController(text: _formatDate(firstDay));
    final endCtrl = TextEditingController(text: _formatDate(lastDay));
    final deductionDateCtrl = TextEditingController(text: _formatDate(now));
    bool isGenerating = false;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long, color: AppTheme.accentColor, size: 22),
                          SizedBox(width: 8),
                          Text('GENERATE PAYROLL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      'This will calculate the total grocery subscription cost for all enrolled employees, apply your subsidy, and generate deduction amounts.',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('PAY PERIOD START'),
                            const SizedBox(height: 6),
                            _buildDateField(startCtrl, context, setModalState),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('PAY PERIOD END'),
                            const SizedBox(height: 6),
                            _buildDateField(endCtrl, context, setModalState),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('TARGET DEDUCTION DATE'),
                  const SizedBox(height: 6),
                  _buildDateField(deductionDateCtrl, context, setModalState),
                  const SizedBox(height: 24),

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
                          onPressed: isGenerating
                              ? null
                              : () async {
                                  setModalState(() => isGenerating = true);
                                  try {
                                    await _api.post('/payroll/deductions/bulk', {
                                      'pay_period_start': startCtrl.text,
                                      'pay_period_end': endCtrl.text,
                                      'deduction_date': deductionDateCtrl.text,
                                    });
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        const SnackBar(content: Text('Payroll deductions generated.'), backgroundColor: Colors.green),
                                      );
                                      _loadData();
                                    }
                                  } catch (e) {
                                    setModalState(() => isGenerating = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
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
                            isGenerating ? 'CALCULATING...' : 'RUN ENGINE',
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

  void _showProcessSheet(String deductionId) {
    final refCtrl = TextEditingController();
    bool isProcessing = false;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.accentColor, size: 22),
                        SizedBox(width: 8),
                        Text('MARK PROCESSED', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Mark this deduction as successfully processed in your HRMS/Payroll system.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),

                _buildLabel('HRMS/PAYROLL EXTERNAL REFERENCE ID'),
                const SizedBox(height: 6),
                TextField(
                  controller: refCtrl,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. TXN-998 (Optional)',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 24),

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
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setModalState(() => isProcessing = true);
                                try {
                                  final ref = refCtrl.text.trim();
                                  final endpoint = ref.isNotEmpty
                                      ? '/payroll/deductions/$deductionId/process?external_ref=${Uri.encodeComponent(ref)}'
                                      : '/payroll/deductions/$deductionId/process';
                                  await _api.post(endpoint, {});
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(content: Text('Deduction marked as processed.'), backgroundColor: Colors.green),
                                    );
                                    _loadData();
                                  }
                                } catch (e) {
                                  setModalState(() => isProcessing = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
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
                          isProcessing ? 'PROCESSING...' : 'CONFIRM',
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade500),
    );
  }

  Widget _buildDateField(TextEditingController ctrl, BuildContext ctx, StateSetter setModalState) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setModalState(() => ctrl.text = _formatDate(picked));
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _deductions.where((d) => d['status'] == 'pending').length;
    final processedCount = _deductions.where((d) => d['status'] == 'processed').length;

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
                        'PAYROLL',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generate employee salary deductions for grocery subscriptions.',
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
                      onTap: _showGenerateSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text('Generate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // KPI Cards
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.amber.shade600)),
                              const SizedBox(height: 8),
                              Text('$pendingCount', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.amber.shade900)),
                            ],
                          ),
                          Icon(Icons.access_time, size: 32, color: Colors.amber.shade200),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PROCESSED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.green.shade600)),
                              const SizedBox(height: 8),
                              Text('$processedCount', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.green.shade900)),
                            ],
                          ),
                          Icon(Icons.check_circle_outline, size: 32, color: Colors.green.shade200),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

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
                    : _deductions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'NO DEDUCTIONS GENERATED',
                                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generate your first bulk payroll file to get started.',
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
                                  dataRowMaxHeight: 80,
                                  dataRowMinHeight: 60,
                                  columnSpacing: 20,
                                  columns: const [
                                    DataColumn(label: Text('EMPLOYEE')),
                                    DataColumn(label: Text('PAY PERIOD')),
                                    DataColumn(label: Text('SUBSIDY / DEDUCT')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: _deductions.map((d) {
                                    final emp = _employees.firstWhere(
                                      (e) => e['id'] == d['employee_enrollment_id'],
                                      orElse: () => <String, dynamic>{},
                                    );
                                    final isPending = d['status'] == 'pending';

                                    String periodText = '';
                                    try {
                                      final start = DateTime.parse(d['pay_period_start']);
                                      final end = DateTime.parse(d['pay_period_end']);
                                      periodText = '${start.day} ${_monthName(start.month)} - ${end.day} ${_monthName(end.month)}';
                                    } catch (_) {}

                                    String dueText = '';
                                    try {
                                      final due = DateTime.parse(d['deduction_scheduled_date']);
                                      dueText = 'Due: ${due.day} ${_monthName(due.month)} ${due.year}';
                                    } catch (_) {}

                                    final subsidy = num.tryParse(d['employer_subsidy']?.toString() ?? '0') ?? 0;
                                    final deducted = num.tryParse(d['amount_deducted']?.toString() ?? '0') ?? 0;

                                    return DataRow(cells: [
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(emp['employee_id']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(emp['department']?.toString() ?? '—', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(periodText, style: const TextStyle(fontSize: 13)),
                                            Text(dueText, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('₹$subsidy (Subsidy)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                                            Text('₹$deducted', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isPending ? Colors.amber.shade50 : Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: isPending ? Colors.amber.shade200 : Colors.green.shade200),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPending ? Icons.access_time : Icons.check_circle,
                                                    size: 12,
                                                    color: isPending ? Colors.amber.shade700 : Colors.green.shade700,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isPending ? 'PENDING' : 'PROCESSED',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                      color: isPending ? Colors.amber.shade700 : Colors.green.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (d['external_ref'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'Ref: ${d['external_ref']}',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontFamily: 'monospace'),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        isPending
                                            ? GestureDetector(
                                                onTap: () => _showProcessSheet(d['id']),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.upload, size: 14, color: Colors.black54),
                                                      SizedBox(width: 4),
                                                      Text('Mark', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
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
}
