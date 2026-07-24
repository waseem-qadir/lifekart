import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _nearbyGroups = [];
  List<dynamic> _myGroups = [];
  Map<String, dynamic>? _household;
  String _searchPincode = '';
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    try {
      final hhData = await _api.get('/profiling/households/me').catchError((_) => null);
      if (mounted) {
        setState(() {
          _household = hhData;
          _searchPincode = hhData?['pincode'] ?? '';
        });
      }
      await Future.wait([
        _loadMyGroups(),
        if (_searchPincode.isNotEmpty) _loadNearbyGroups(_searchPincode)
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMyGroups() async {
    try {
      final myGroupsData = await _api.get('/community/me/groups').catchError((_) => []);
      if (mounted) {
        setState(() {
          _myGroups = myGroupsData as List<dynamic>? ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadNearbyGroups(String pincode) async {
    try {
      final groupsData = await _api.get('/community/groups?pincode=$pincode').catchError((_) => []);
      if (mounted) {
        setState(() {
          _nearbyGroups = groupsData as List<dynamic>? ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSearch() async {
    setState(() => _isLoading = true);
    await _loadNearbyGroups(_searchPincode);
    setState(() => _isLoading = false);
  }

  Widget _buildGroupCard(Map<String, dynamic> group, bool isMyGroup) {
    final name = group['name'] ?? 'Unknown Group';
    final minHouseholds = group['min_households_for_pooling'] ?? 10;
    final memberCount = group['member_count'] ?? 0;
    final status = group['status'] ?? 'pending';
    final isAdmin = _household?['id'] == group['admin_household_id'];
    
    final pct = (memberCount / minHouseholds) * 100.0;
    final cappedPct = pct > 100.0 ? 100.0 : pct;

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_city, color: AppTheme.accentColor, size: 24),
                ),
                if (isMyGroup)
                  Row(
                    children: [
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 12, color: Colors.indigo.shade700),
                              const SizedBox(width: 4),
                              Text('Admin', style: TextStyle(color: Colors.indigo.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: status == 'active' ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text(status.toUpperCase(), style: TextStyle(color: status == 'active' ? Colors.green.shade800 : Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Text('$minHouseholds Households Tier', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [group['locality'], group['pincode']].where((e) => e != null && e.toString().isNotEmpty).join(', '),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$memberCount / $minHouseholds Joined', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('${cappedPct.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: cappedPct / 100.0,
                backgroundColor: Colors.grey.shade200,
                color: isMyGroup ? Colors.green : AppTheme.accentColor,
                minHeight: 8,
              ),
            ),
            if (memberCount < minHouseholds) ...[
              const SizedBox(height: 8),
              Text('${minHouseholds - memberCount} more needed', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            ],
            const SizedBox(height: 20),
            if (isMyGroup)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share, size: 14),
                      label: const Text('Invite', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text('View', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.group_add, size: 14),
                  label: const Text('Join Pool', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMMUNITY',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.accentColor, size: 32),
                onPressed: () {
                  _showCreateGroupSheet(context);
                },
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.accentColor,
          tabs: [
            const Tab(text: 'DISCOVER NEARBY'),
            Tab(text: 'MY GROUPS (${_myGroups.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Discover Tab
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(24.0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration.collapsed(hintText: 'Enter pincode...'),
                                onChanged: (val) => _searchPincode = val,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _handleSearch,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                              child: const Text('Search'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_nearbyGroups.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('NO POOLS FOUND', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to start a wholesale pool in $_searchPincode.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildGroupCard(_nearbyGroups[index], false),
                          childCount: _nearbyGroups.length,
                        ),
                      ),
                    ),
                ],
              ),
              // My Groups Tab
              CustomScrollView(
                slivers: [
                  if (_myGroups.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.group_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('NO GROUPS YET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(
                                  'Switch to Discover to find pools in your area.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildGroupCard(_myGroups[index], true),
                          childCount: _myGroups.length,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateGroupSheet(
        api: _api,
        defaultPincode: _searchPincode,
        onSuccess: () => _initialLoad(),
      ),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  final ApiService api;
  final String defaultPincode;
  final VoidCallback onSuccess;

  const _CreateGroupSheet({Key? key, required this.api, required this.defaultPincode, required this.onSuccess}) : super(key: key);

  @override
  __CreateGroupSheetState createState() => __CreateGroupSheetState();
}

class __CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _city = '';
  String _state = '';
  late String _pincode;
  bool _isPrivate = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pincode = widget.defaultPincode;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isSubmitting = true);
    try {
      await widget.api.post('/community/groups', {
        'name': _name,
        'city': _city,
        'state': _state,
        'pincode': _pincode,
        'is_private': _isPrivate,
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community pool created successfully!'), backgroundColor: Colors.green),
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
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
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
                const Text('CREATE POOL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Pool Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              onSaved: (val) => _name = val!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                    onSaved: (val) => _city = val!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'State', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                    onSaved: (val) => _state = val!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _pincode,
              decoration: InputDecoration(labelText: 'Pincode', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              keyboardType: TextInputType.number,
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              onSaved: (val) => _pincode = val!,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Make Pool Private', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Only people with an invite link can join', style: TextStyle(fontSize: 12)),
              value: _isPrivate,
              onChanged: (val) => setState(() => _isPrivate = val),
              activeColor: AppTheme.accentColor,
              contentPadding: EdgeInsets.zero,
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
                    : const Text('Create Pool', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
