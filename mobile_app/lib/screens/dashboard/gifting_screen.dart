import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class GiftingScreen extends StatefulWidget {
  const GiftingScreen({Key? key}) : super(key: key);

  @override
  _GiftingScreenState createState() => _GiftingScreenState();
}

class _GiftingScreenState extends State<GiftingScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _api.get('/gifting/').catchError((_) => []);
      if (mounted) {
        setState(() {
          _orders = data as List<dynamic>? ?? [];
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

  Widget _buildGiftCard(Map<String, dynamic> order) {
    final name = order['beneficiary_name'] ?? 'Beneficiary';
    final relation = order['beneficiary_relationship'] ?? 'relation';
    final status = order['payment_status'] ?? 'pending';
    final startAge = order['start_age'] ?? 0;
    final endAge = order['end_age'] ?? 0;
    final itemsCount = (order['items'] as List?)?.length ?? 0;
    final totalLocked = double.tryParse(order['total_value_locked']?.toString() ?? '0') ?? 0;

    double monthlyCost = 0;
    if (order['items'] != null) {
      for (var item in order['items']) {
        final price = double.tryParse(item['locked_price']?.toString() ?? '0') ?? 0;
        final qty = double.tryParse(item['quantity_per_delivery']?.toString() ?? '0') ?? 0;
        final freq = double.tryParse(item['frequency_days']?.toString() ?? '30') ?? 30;
        monthlyCost += (price * qty * (30 / freq));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Can be expanded later for details
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(relation.toString().toUpperCase(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'paid' ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status == 'paid' ? 'ACTIVE' : 'PENDING',
                        style: TextStyle(color: status == 'paid' ? Colors.green.shade700 : Colors.amber.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Coverage: Age $startAge to $endAge', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('$itemsCount Products Locked', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.security, size: 16, color: AppTheme.accentColor),
                    const SizedBox(width: 8),
                    const Text('Protected against inflation', style: TextStyle(color: Colors.black, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total ${endAge - startAge}-Year Contract Value', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('₹${totalLocked.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Current Billing', style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('₹${monthlyCost.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accentColor, fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text(' / mo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                  'GIFTING',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.accentColor, size: 32),
                  onPressed: () {
                    _showCreateGiftSheet(context);
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
              'Secure a lifetime supply of essentials for your child or grandchild. Lock in today\'s prices and protect their future against inflation.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        ),
        if (_orders.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
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
                    const Icon(Icons.favorite, size: 64, color: AppTheme.accentColor),
                    const SizedBox(height: 16),
                    const Text('NO GIFTS CREATED YET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Text(
                      'Start building a legacy of care. Lock in wholesale prices on essentials for your loved ones from childhood through adulthood.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showCreateGiftSheet(context);
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Start a Gift Order', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGiftCard(_orders[index]),
                childCount: _orders.length,
              ),
            ),
          ),
      ],
    );
  }

  void _showCreateGiftSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateGiftSheet(
        api: _api,
        onSuccess: () => _loadData(),
      ),
    );
  }
}

class _CreateGiftSheet extends StatefulWidget {
  final ApiService api;
  final VoidCallback onSuccess;

  const _CreateGiftSheet({Key? key, required this.api, required this.onSuccess}) : super(key: key);

  @override
  __CreateGiftSheetState createState() => __CreateGiftSheetState();
}

class __CreateGiftSheetState extends State<_CreateGiftSheet> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _dob = '2020-01-01';
  String _relation = 'child';
  int _endAge = 18;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isSubmitting = true);
    try {
      // 1. Fetch a product to gift (since we don't have a product selector in this simple UI)
      final products = await widget.api.get('/catalog/products') as List<dynamic>;
      if (products.isEmpty) throw Exception("No products available to gift.");
      final productId = products.first['id'];

      // 2. Create the gift order
      await widget.api.post('/gifting/', {
        'beneficiary_name': _name,
        'beneficiary_dob': _dob,
        'beneficiary_relationship': _relation,
        'end_age': _endAge,
        'items': [
          {
            'product_id': productId,
            'age_trigger': 0,
            'frequency_days': 30,
            'quantity_per_delivery': 1.0,
          }
        ],
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gift Order Created!'), backgroundColor: Colors.green),
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
                const Text('CREATE GIFT ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Beneficiary Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              onSaved: (val) => _name = val!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _dob,
                    decoration: InputDecoration(labelText: 'DOB (YYYY-MM-DD)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => (val == null || val.length != 10) ? 'Invalid' : null,
                    onSaved: (val) => _dob = val!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _relation,
                    decoration: InputDecoration(labelText: 'Relation', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'child', child: Text('Child')),
                      DropdownMenuItem(value: 'grandchild', child: Text('Grandchild')),
                      DropdownMenuItem(value: 'niece', child: Text('Niece')),
                      DropdownMenuItem(value: 'nephew', child: Text('Nephew')),
                    ],
                    onChanged: (val) => setState(() => _relation = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _endAge.toString(),
              decoration: InputDecoration(labelText: 'End Age', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.number,
              validator: (val) => (val == null || int.tryParse(val) == null) ? 'Required' : null,
              onSaved: (val) => _endAge = int.parse(val!),
            ),
            const SizedBox(height: 8),
            Text('A bundle of essential products will automatically be added to this gift.', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
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
                    : const Text('Create Gift', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
