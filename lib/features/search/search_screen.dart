import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = ['Kaju Katli', 'Dark Chocolate Gelato', 'Truffle Cake', 'Motichoor'];
  List<String> _lastDeleted = [];

  static const List<String> _popularSearches = [
    'Pure Cow Ghee Sweets',
    'Gelato Tubs (500ml)',
    'Eggless Birthday Cakes',
    'Rasmalai & Sandesh',
    'Sugarfree Confectionery',
    'Dry Fruit Gift Hampers',
  ];

  void _clearRecent() {
    setState(() {
      _lastDeleted = List.from(_recentSearches);
      _recentSearches.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recent searches cleared', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.textPrimary,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () {
            setState(() {
              _recentSearches = List.from(_lastDeleted);
            });
          },
        ),
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    if (!_recentSearches.contains(query.trim())) {
      setState(() => _recentSearches.insert(0, query.trim()));
    }
    context.push('/search-results?q=${Uri.encodeComponent(query.trim())}');
  }

  void _simulateVoiceSearch() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusBottomSheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint20,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            const Text('Listening for sweets or parlours...', style: AppTypography.heading2),
            const SizedBox(height: 8),
            const Text('Say "Belgian Gelato" or "Anand Sweets"', style: AppTypography.bodySmall),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Couldn’t hear that. Please try again or type.')),
                      );
                    },
                    child: const Text('Simulate Error'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _performSearch('Kaju Katli');
                    },
                    child: const Text('Found "Kaju Katli"'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryTint10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutralBorder, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _performSearch,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      hintText: 'Search items or shops...',
                      hintStyle: AppTypography.bodySmall,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() => _searchController.clear());
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.mic, size: 20, color: AppColors.accent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _simulateVoiceSearch,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Searches
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Searches', style: AppTypography.sectionTitle),
                  TextButton(
                    onPressed: _clearRecent,
                    child: const Text('Clear all', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((s) {
                  return ActionChip(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.neutralBorder, width: 1),
                    avatar: const Icon(Icons.history, size: 16, color: AppColors.neutral),
                    label: Text(s, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
                    onPressed: () => _performSearch(s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Popular Searches with Trending Icon
            const Text('Popular Right Now', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.neutralLight, width: 1),
              ),
              child: Column(
                children: _popularSearches.map((pop) {
                  return ListTile(
                    leading: const Icon(Icons.trending_up, size: 20, color: AppColors.accent),
                    title: Text(pop, style: AppTypography.body),
                    trailing: const Icon(Icons.north_west, size: 16, color: AppColors.neutral),
                    onTap: () => _performSearch(pop),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

