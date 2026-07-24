import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class LegacyScreen extends StatefulWidget {
  const LegacyScreen({Key? key}) : super(key: key);

  @override
  _LegacyScreenState createState() => _LegacyScreenState();
}

class _LegacyScreenState extends State<LegacyScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _nominees = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _api.get('/legacy/nominees').catchError((_) => []);
      if (mounted) {
        setState(() {
          _nominees = data as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNomineeCard(Map<String, dynamic> nominee) {
    final name = nominee['nominee_name'] ?? 'Unknown';
    final relation = nominee['nominee_relationship'] ?? 'other';
    final isPrimary = nominee['is_primary'] == true;
    final isVerified = nominee['is_verified'] == true;
    final email = nominee['nominee_email'] ?? '—';
    final phone = nominee['nominee_phone'] ?? '—';
    final aadhaar = nominee['nominee_aadhaar'] ?? 'Not Provided';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('PRIMARY', style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ],
                  ],
                ),
                Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
              ],
            ),
            Text(relation.toString().toUpperCase(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('AADHAAR', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(aadhaar, style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.schedule,
                  color: isVerified ? Colors.green : Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isVerified ? 'VERIFIED' : 'PENDING VERIFICATION',
                  style: TextStyle(color: isVerified ? Colors.green.shade700 : Colors.amber.shade700, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ],
            ),
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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LEGACY SETTINGS',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.accentColor, size: 32),
                  onPressed: () {
                    _showAddNomineeSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Assign successors to inherit your lifetime grocery subscriptions.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade100),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.accentColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('IN THE EVENT OF YOUR PASSING', style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        Text(
                          'Your registered nominees can securely file a death verification claim through our public portal. Once verified, your lifetime subscriptions will automatically transfer to their household at no extra cost.',
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        const Text('VIEW PUBLIC CLAIM PORTAL →', style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_nominees.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.security, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('NO NOMINEES REGISTERED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Secure your legacy by adding a trusted family member.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNomineeCard(_nominees[index]),
                childCount: _nominees.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showAddNomineeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddNomineeSheet(
        api: _api,
        onSuccess: () => _loadData(),
      ),
    );
  }
}

class _AddNomineeSheet extends StatefulWidget {
  final ApiService api;
  final VoidCallback onSuccess;

  const _AddNomineeSheet({Key? key, required this.api, required this.onSuccess}) : super(key: key);

  @override
  __AddNomineeSheetState createState() => __AddNomineeSheetState();
}

class __AddNomineeSheetState extends State<_AddNomineeSheet> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _relation = 'child';
  String _email = '';
  String _phone = '';
  String _aadhaar = '';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isSubmitting = true);
    try {
      await widget.api.post('/legacy/nominees', {
        'nominee_name': _name,
        'nominee_relationship': _relation,
        'nominee_email': _email,
        'nominee_phone': _phone,
        'nominee_aadhaar': _aadhaar.isNotEmpty ? _aadhaar : null,
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominee added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ADD NOMINEE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              onSaved: (val) => _name = val!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _relation,
              decoration: InputDecoration(labelText: 'Relationship', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                DropdownMenuItem(value: 'child', child: Text('Child')),
                DropdownMenuItem(value: 'parent', child: Text('Parent')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (val) => setState(() => _relation = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => (val == null || val.isEmpty || !val.contains('@')) ? 'Invalid' : null,
                    onSaved: (val) => _email = val!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    keyboardType: TextInputType.phone,
                    validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                    onSaved: (val) => _phone = val!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Aadhaar Number (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.number,
              onSaved: (val) => _aadhaar = val ?? '',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Nominee', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
