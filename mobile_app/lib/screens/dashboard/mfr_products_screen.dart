import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class MfrProductsScreen extends StatefulWidget {
  const MfrProductsScreen({Key? key}) : super(key: key);

  @override
  _MfrProductsScreenState createState() => _MfrProductsScreenState();
}

class _MfrProductsScreenState extends State<MfrProductsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.get('/portal/manufacturer/products?limit=50');
      if (mounted) {
        setState(() {
          _products = data is List ? data : [];
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

  void _showProductSheet({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final skuCtrl = TextEditingController(text: existing?['sku'] ?? '');
    final wholesaleCtrl = TextEditingController(text: existing?['unit_price_wholesale']?.toString() ?? '');
    final retailCtrl = TextEditingController(text: existing?['unit_price_retail']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: existing?['stock_quantity']?.toString() ?? '0');
    final moqCtrl = TextEditingController(text: existing?['min_order_quantity']?.toString() ?? '1');
    final imageCtrl = TextEditingController(text: existing?['image_url'] ?? '');
    String? selectedCategoryId = existing?['category_id'];
    String? selectedUnitSize = existing?['unit_size'];
    List<dynamic> categories = [];
    bool isSaving = false;
    bool categoriesLoading = true;

    const unitSizes = ['piece', 'pack', 'kg', 'g', 'liter', 'ml', 'pair', 'dozen', 'box'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Load categories on first build
          if (categoriesLoading) {
            _api.get('/catalog/categories?limit=100').then((data) {
              setModalState(() {
                categories = data is List ? data : [];
                categoriesLoading = false;
              });
            }).catchError((_) {
              setModalState(() => categoriesLoading = false);
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'EDIT PRODUCT' : 'ADD NEW PRODUCT',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Scrollable form body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabel('PRODUCT NAME *'),
                          const SizedBox(height: 6),
                          _buildField(nameCtrl, hint: 'e.g. Premium Aluminium Foil'),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('SKU *'),
                                  const SizedBox(height: 6),
                                  _buildField(skuCtrl, hint: 'e.g. FOIL-PREM-50'),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('CATEGORY *'),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: categoriesLoading
                                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                        : DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: selectedCategoryId,
                                              hint: const Text('Select', style: TextStyle(fontSize: 14)),
                                              items: categories.map((cat) => DropdownMenuItem<String>(
                                                value: cat['id']?.toString(),
                                                child: Text(cat['name']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                                              )).toList(),
                                              onChanged: (val) => setModalState(() => selectedCategoryId = val),
                                            ),
                                          ),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('WHOLESALE PRICE (₹) *'),
                                  const SizedBox(height: 6),
                                  _buildField(wholesaleCtrl, hint: '0.00', keyboard: TextInputType.number),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('RETAIL / MRP (₹) *'),
                                  const SizedBox(height: 6),
                                  _buildField(retailCtrl, hint: '0.00', keyboard: TextInputType.number),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('UNIT SIZE'),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: selectedUnitSize,
                                        hint: const Text('Select', style: TextStyle(fontSize: 14)),
                                        items: unitSizes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                                        onChanged: (val) => setModalState(() => selectedUnitSize = val),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('STOCK *'),
                                  const SizedBox(height: 6),
                                  _buildField(stockCtrl, keyboard: TextInputType.number),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('MOQ *'),
                                  const SizedBox(height: 6),
                                  _buildField(moqCtrl, keyboard: TextInputType.number),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  _buildLabel('IMAGE URL'),
                                  const SizedBox(height: 6),
                                  _buildField(imageCtrl, hint: 'https://...'),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Actions
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
                                            final payload = <String, dynamic>{
                                              'name': nameCtrl.text.trim(),
                                              'sku': skuCtrl.text.trim(),
                                              'category_id': selectedCategoryId,
                                              'unit_price_wholesale': double.tryParse(wholesaleCtrl.text) ?? 0,
                                              'unit_price_retail': double.tryParse(retailCtrl.text) ?? 0,
                                              'min_order_quantity': int.tryParse(moqCtrl.text) ?? 1,
                                              'stock_quantity': int.tryParse(stockCtrl.text) ?? 0,
                                            };
                                            if (selectedUnitSize != null && selectedUnitSize!.isNotEmpty) payload['unit_size'] = selectedUnitSize;
                                            if (imageCtrl.text.trim().isNotEmpty) payload['image_url'] = imageCtrl.text.trim();

                                            if (isEdit) {
                                              await _api.patch('/portal/manufacturer/products/${existing['id']}', payload);
                                            } else {
                                              await _api.post('/portal/manufacturer/products', payload);
                                            }
                                            if (mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(this.context).showSnackBar(
                                                SnackBar(content: Text(isEdit ? 'Product updated.' : 'Product added.'), backgroundColor: Colors.green),
                                              );
                                              _loadData();
                                            }
                                          } catch (e) {
                                            setModalState(() => isSaving = false);
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
                                    isSaving ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'ADD PRODUCT'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDiscontinue(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discontinue Product?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to permanently discontinue \"${product['name']}\"?"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                'Warning: This will trigger automatic substitutions for all active agreements tied to this product.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Discontinue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.delete('/portal/manufacturer/products/${product['id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product discontinued.'), backgroundColor: Colors.green),
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
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade500));
  }

  Widget _buildField(TextEditingController ctrl, {String? hint, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accentColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('PRODUCTS', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.refresh, color: AppTheme.accentColor), onPressed: _loadData),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showProductSheet(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                        ]),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('NO PRODUCTS YET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500)),
                              const SizedBox(height: 4),
                              Text('Tap + New to add your first product.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                            ]),
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
                                  dataRowMinHeight: 56,
                                  columnSpacing: 20,
                                  columns: const [
                                    DataColumn(label: Text('NAME')),
                                    DataColumn(label: Text('SKU')),
                                    DataColumn(label: Text('PRICE (₹)')),
                                    DataColumn(label: Text('STOCK')),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: _products.map((p) {
                                    final stock = p['stock_quantity'] ?? 0;
                                    final lowStock = stock is num && stock <= 10;
                                    return DataRow(cells: [
                                      DataCell(Text(p['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(p['sku']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                                      DataCell(Text('₹${p['unit_price_wholesale'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: lowStock ? Colors.red.shade50 : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$stock',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: lowStock ? Colors.red.shade700 : Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(mainAxisSize: MainAxisSize.min, children: [
                                          GestureDetector(
                                            onTap: () => _showProductSheet(existing: p),
                                            child: Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentColor)),
                                          ),
                                          const SizedBox(width: 16),
                                          GestureDetector(
                                            onTap: () => _confirmDiscontinue(p),
                                            child: Text('Discontinue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade500)),
                                          ),
                                        ]),
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
