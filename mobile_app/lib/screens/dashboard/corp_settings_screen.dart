import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CorpSettingsScreen extends StatefulWidget {
  const CorpSettingsScreen({Key? key}) : super(key: key);

  @override
  _CorpSettingsScreenState createState() => _CorpSettingsScreenState();
}

class _CorpSettingsScreenState extends State<CorpSettingsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  Map<String, dynamic>? _partner;
  String? _error;

  // Form controllers
  final _companyNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _subsidyPctCtrl = TextEditingController();
  final _maxBenefitCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _subsidyPctCtrl.dispose();
    _maxBenefitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final partner = await _api.get('/corporate/partners/me');
      if (mounted) {
        setState(() {
          _partner = partner;
          _populateForm(partner);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll("Exception: ", "");
        setState(() {
          if (msg.toLowerCase().contains('not found')) {
            // No profile yet — force edit mode to create
            _partner = null;
            _isEditing = true;
            _isLoading = false;
          } else {
            _error = msg;
            _isLoading = false;
          }
        });
      }
    }
  }

  void _populateForm(Map<String, dynamic>? p) {
    _companyNameCtrl.text = p?['company_name']?.toString() ?? '';
    _contactEmailCtrl.text = p?['contact_email']?.toString() ?? '';
    _subsidyPctCtrl.text = (p?['subsidy_percentage'] ?? 0).toString();
    _maxBenefitCtrl.text = (p?['max_employee_benefit'] ?? 0).toString();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final body = {
        'company_name': _companyNameCtrl.text.trim(),
        'contact_email': _contactEmailCtrl.text.trim(),
        'subsidy_percentage': double.tryParse(_subsidyPctCtrl.text) ?? 0,
        'max_employee_benefit': double.tryParse(_maxBenefitCtrl.text) ?? 0,
      };

      Map<String, dynamic> res;
      if (_partner != null) {
        res = await _api.patch('/corporate/partners/me', body);
      } else {
        res = await _api.post('/corporate/partners', body);
      }

      if (mounted) {
        setState(() {
          _partner = res;
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade500),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, String? prefix, String? suffix}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixText: prefix,
        suffixText: suffix,
        prefixStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 16),
        suffixStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 16),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accentColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

    final status = _partner?['partnership_status'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'SETTINGS',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your company profile and subsidy rules',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Pending Banner
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
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.amber.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your corporate account is under review. Subsidies will not be activated until approved.',
                            style: TextStyle(fontSize: 13, color: Colors.amber.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Settings Card
            Container(
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
                  // Card Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'COMPANY PROFILE & SUBSIDY',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                      ),
                      if (_partner != null && !_isEditing)
                        GestureDetector(
                          onTap: () => setState(() => _isEditing = true),
                          child: const Text(
                            'EDIT',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.accentColor),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Company Name
                  _buildLabel('COMPANY NAME'),
                  const SizedBox(height: 6),
                  _isEditing
                      ? _buildTextField(_companyNameCtrl)
                      : _buildReadOnlyField(_partner?['company_name']?.toString() ?? '—'),
                  const SizedBox(height: 20),

                  // Contact Email
                  _buildLabel('CONTACT EMAIL'),
                  const SizedBox(height: 6),
                  _isEditing
                      ? _buildTextField(_contactEmailCtrl, keyboardType: TextInputType.emailAddress)
                      : _buildReadOnlyField(_partner?['contact_email']?.toString() ?? '—'),
                  const SizedBox(height: 20),

                  // Subsidy Percentage
                  _buildLabel('SUBSIDY PERCENTAGE (%)'),
                  const SizedBox(height: 6),
                  _isEditing
                      ? _buildTextField(_subsidyPctCtrl, keyboardType: TextInputType.number, suffix: '%')
                      : _buildReadOnlyField('${_partner?['subsidy_percentage'] ?? 0}%'),
                  Text(
                    "Percentage of employee's grocery bill subsidized by the company.",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),

                  // Max Benefit
                  _buildLabel('MAX BENEFIT PER EMPLOYEE (₹)'),
                  const SizedBox(height: 6),
                  _isEditing
                      ? _buildTextField(_maxBenefitCtrl, keyboardType: TextInputType.number, prefix: '₹ ')
                      : _buildReadOnlyField('₹${_partner?['max_employee_benefit'] ?? 0}'),
                  Text(
                    'Cap the monthly subsidy amount per employee.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),

                  // Save / Cancel buttons
                  if (_isEditing) ...[
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_partner != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _populateForm(_partner);
                                setState(() => _isEditing = false);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                            ),
                          ),
                        if (_partner != null) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            icon: const Icon(Icons.save, size: 20),
                            label: Text(
                              _isSaving ? 'SAVING...' : 'SAVE SETTINGS',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
