import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class MfrSettingsScreen extends StatefulWidget {
  const MfrSettingsScreen({Key? key}) : super(key: key);

  @override
  _MfrSettingsScreenState createState() => _MfrSettingsScreenState();
}

class _MfrSettingsScreenState extends State<MfrSettingsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  Map<String, dynamic>? _profile;
  String? _error;

  final _companyNameCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _gstinCtrl.dispose();
    _contactEmailCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.get('/portal/manufacturer/profile');
      if (mounted) {
        setState(() {
          _profile = data;
          _populateForm(data);
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll("Exception: ", "");
        setState(() {
          if (msg.toLowerCase().contains('not found') || msg.contains('404')) {
            _profile = null;
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
    _gstinCtrl.text = p?['gstin']?.toString() ?? '';
    _contactEmailCtrl.text = p?['contact_email']?.toString() ?? '';
    _address1Ctrl.text = p?['address_line1']?.toString() ?? '';
    _address2Ctrl.text = p?['address_line2']?.toString() ?? '';
    _cityCtrl.text = p?['city']?.toString() ?? '';
    _stateCtrl.text = p?['state']?.toString() ?? '';
    _pincodeCtrl.text = p?['pincode']?.toString() ?? '';
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      // Only send non-empty values to avoid backend min_length validation
      final payload = <String, dynamic>{};
      if (_companyNameCtrl.text.trim().isNotEmpty) payload['company_name'] = _companyNameCtrl.text.trim();
      if (_gstinCtrl.text.trim().isNotEmpty) payload['gstin'] = _gstinCtrl.text.trim();
      if (_contactEmailCtrl.text.trim().isNotEmpty) payload['contact_email'] = _contactEmailCtrl.text.trim();
      if (_address1Ctrl.text.trim().isNotEmpty) payload['address_line1'] = _address1Ctrl.text.trim();
      if (_address2Ctrl.text.trim().isNotEmpty) payload['address_line2'] = _address2Ctrl.text.trim();
      if (_cityCtrl.text.trim().isNotEmpty) payload['city'] = _cityCtrl.text.trim();
      if (_stateCtrl.text.trim().isNotEmpty) payload['state'] = _stateCtrl.text.trim();
      if (_pincodeCtrl.text.trim().isNotEmpty) payload['pincode'] = _pincodeCtrl.text.trim();

      Map<String, dynamic> res;
      if (_profile != null) {
        res = await _api.patch('/portal/manufacturer/profile', payload);
      } else {
        res = await _api.post('/portal/manufacturer/profile', payload);
      }

      if (mounted) {
        setState(() {
          _profile = res;
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green),
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
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade500));
  }

  Widget _buildReadOnly(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
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
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: AppTheme.accentColor)));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SETTINGS', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 24),

            // Profile Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('COMPANY PROFILE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                      if (_profile != null && !_isEditing)
                        GestureDetector(
                          onTap: () => setState(() => _isEditing = true),
                          child: const Text('EDIT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.accentColor)),
                        ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Company Name
                  _buildLabel('COMPANY NAME'),
                  const SizedBox(height: 6),
                  _isEditing ? _buildTextField(_companyNameCtrl) : _buildReadOnly(_profile?['company_name']?.toString() ?? ''),
                  const SizedBox(height: 16),

                  // GSTIN & Contact Email
                  Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('GSTIN'),
                          const SizedBox(height: 6),
                          _isEditing ? _buildTextField(_gstinCtrl) : _buildReadOnly(_profile?['gstin']?.toString() ?? ''),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('CONTACT EMAIL'),
                          const SizedBox(height: 6),
                          _isEditing ? _buildTextField(_contactEmailCtrl, keyboard: TextInputType.emailAddress) : _buildReadOnly(_profile?['contact_email']?.toString() ?? ''),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Location Section
                  const Text('LOCATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                  const Divider(height: 24),

                  _buildLabel('ADDRESS LINE 1'),
                  const SizedBox(height: 6),
                  _isEditing ? _buildTextField(_address1Ctrl) : _buildReadOnly(_profile?['address_line1']?.toString() ?? ''),
                  const SizedBox(height: 16),

                  _buildLabel('ADDRESS LINE 2'),
                  const SizedBox(height: 6),
                  _isEditing ? _buildTextField(_address2Ctrl) : _buildReadOnly(_profile?['address_line2']?.toString() ?? ''),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('CITY'),
                          const SizedBox(height: 6),
                          _isEditing ? _buildTextField(_cityCtrl) : _buildReadOnly(_profile?['city']?.toString() ?? ''),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('STATE'),
                          const SizedBox(height: 6),
                          _isEditing ? _buildTextField(_stateCtrl) : _buildReadOnly(_profile?['state']?.toString() ?? ''),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('PINCODE'),
                          const SizedBox(height: 6),
                          _isEditing ? _buildTextField(_pincodeCtrl, keyboard: TextInputType.number) : _buildReadOnly(_profile?['pincode']?.toString() ?? ''),
                        ]),
                      ),
                    ],
                  ),

                  // Actions
                  if (_isEditing) ...[
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_profile != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _populateForm(_profile);
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
                        if (_profile != null) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleSave,
                            icon: const Icon(Icons.save, size: 20),
                            label: Text(
                              _isSaving ? 'SAVING...' : 'SAVE PROFILE',
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
