import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../providers/babies_provider.dart';
import '../widgets/baby_card.dart';

class BabyListScreen extends ConsumerStatefulWidget {
  const BabyListScreen({super.key});

  @override
  ConsumerState<BabyListScreen> createState() => _BabyListScreenState();
}

class _BabyListScreenState extends ConsumerState<BabyListScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _sortBy = 'dol';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var babies = ref.watch(babiesProvider);

    // Apply search
    if (_searchController.text.isNotEmpty) {
      babies = ref
          .read(babiesProvider.notifier)
          .searchBabies(_searchController.text);
    }

    // Apply status filter
    if (_statusFilter != 'all') {
      babies = babies.where((b) => b.status == _statusFilter).toList();
    }

    // Apply sort
    babies = List.from(babies);
    switch (_sortBy) {
      case 'dol':
        babies.sort((a, b) => b.dayOfLife.compareTo(a.dayOfLife));
        break;
      case 'dob':
        babies.sort((a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
        break;
      case 'name':
        babies.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'ga':
        babies.sort((a, b) =>
            (a.gaWeeks * 7 + a.gaDays).compareTo(b.gaWeeks * 7 + b.gaDays));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'dol', child: Text('Sort by DOL')),
              const PopupMenuItem(value: 'dob', child: Text('Sort by DOB')),
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'ga', child: Text('Sort by GA')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or MRN...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _statusFilter == 'all',
                  onTap: () => setState(() => _statusFilter = 'all'),
                ),
                _FilterChip(
                  label: 'Admitted',
                  selected: _statusFilter == 'admitted',
                  onTap: () => setState(() => _statusFilter = 'admitted'),
                ),
                _FilterChip(
                  label: 'Discharged',
                  selected: _statusFilter == 'discharged',
                  onTap: () => setState(() => _statusFilter = 'discharged'),
                ),
                _FilterChip(
                  label: 'Transferred',
                  selected: _statusFilter == 'transferred',
                  onTap: () => setState(() => _statusFilter = 'transferred'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: babies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.child_care,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No patients found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/baby/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Baby'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: babies.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) =>
                        BabyCard(baby: babies[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/baby/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
