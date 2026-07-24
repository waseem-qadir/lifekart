import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminRoutingRulesScreen extends StatefulWidget {
  const AdminRoutingRulesScreen({Key? key}) : super(key: key);

  @override
  _AdminRoutingRulesScreenState createState() => _AdminRoutingRulesScreenState();
}

class _AdminRoutingRulesScreenState extends State<AdminRoutingRulesScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  String? _error;

  String? _selectedCategory;
  String? _selectedProduct;
  
  List<dynamic> _progressionRules = [];
  bool _isLoadingRules = false;

  List<dynamic> _substitutes = [];
  bool _isLoadingSubs = false;

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
      final categories = await _api.get('/catalog/categories?limit=50');
      final products = await _api.get('/catalog/products?limit=50');
      if (mounted) {
        setState(() {
          _categories = categories ?? [];
          _products = products ?? [];
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

  Future<void> _loadProgressionRules(String categoryId) async {
    setState(() => _isLoadingRules = true);
    try {
      final rules = await _api.get('/catalog/categories/$categoryId/progression-rules');
      if (mounted) {
        setState(() {
          _progressionRules = rules ?? [];
          _isLoadingRules = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRules = false);
    }
  }

  Future<void> _loadSubstitutes(String productId) async {
    setState(() => _isLoadingSubs = true);
    try {
      final subs = await _api.get('/catalog/products/$productId/substitutes');
      if (mounted) {
        setState(() {
          _substitutes = subs ?? [];
          _isLoadingSubs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSubs = false);
    }
  }

  String _getProductName(String productId) {
    try {
      final product = _products.firstWhere((p) => p['id'] == productId);
      return product['name'] ?? 'Unknown Product';
    } catch (_) {
      return 'Unknown Product';
    }
  }

  Widget _buildAgeProgressionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              const Text('AGE PROGRESSION MAP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Map how subscriptions evolve over time within a category (e.g. Diaper sizes).', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 24),
          
          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select Category'),
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['name']))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                    _loadProgressionRules(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Existing Rules list
          if (_isLoadingRules)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_selectedCategory != null && _progressionRules.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text('No progression rules mapped for this category.', style: TextStyle(color: Colors.grey.shade400)))
          else
            ..._progressionRules.map((rule) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getProductName(rule['specific_product_id']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Months: ${rule['start_age_months']} to ${rule['end_age_months']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                ],
              ),
            )).toList(),
          const SizedBox(height: 24),

          // Add New Rule Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADD NEW RULE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('-- Target Product --'),
                      items: const [],
                      onChanged: (val) {},
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('START (MONTHS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextField(decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('END (MONTHS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          TextField(decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('+ Map Progression', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstituteLogicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              const Text('SUBSTITUTE LOGIC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Map fallback products to fulfill subscriptions when an item goes out of stock.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 24),
          
          // Product Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select Product'),
                value: _selectedProduct,
                items: _products.map((p) => DropdownMenuItem<String>(value: p['id'], child: Text(p['name']))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedProduct = val);
                    _loadSubstitutes(val);
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          if (_isLoadingSubs)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_selectedProduct == null || _substitutes.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('No substitutes mapped for this product.', style: TextStyle(color: Colors.grey.shade400))))
          else
            ..._substitutes.map((sub) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getProductName(sub['substitute_product_id']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Priority Rank: ${sub['priority_rank']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                ],
              ),
            )).toList(),
          const SizedBox(height: 24),

          // Add Backup Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADD BACKUP PRODUCT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('SELECT BACKUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('-- Fallback Product --'),
                      items: const [],
                      onChanged: (val) {},
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('+ Map Substitute', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                      'ROUTING RULES',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure automated progression transitions and inventory substitutes.',
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        children: [
                          _buildAgeProgressionCard(),
                          const SizedBox(height: 24),
                          _buildSubstituteLogicCard(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ],
      ),
    );
  }
}
