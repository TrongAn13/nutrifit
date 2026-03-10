import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../tracking/data/models/daily_log_model.dart';
import '../../data/models/food_model.dart';
import '../../logic/food_bloc.dart';
import '../../logic/food_event.dart';
import '../../logic/food_state.dart';
import '../widgets/add_food_detail_sheet.dart';
import '../widgets/add_food_sheet.dart';

/// Food library screen with two tabs: System foods and User foods.
///
/// When [mealType] is provided, tapping a food item opens [AddFoodDetailSheet]
/// to log the food into the day's meal. Otherwise behaves as a browse-only library.
class FoodLibraryScreen extends StatelessWidget {
  final String? mealType;

  const FoodLibraryScreen({super.key, this.mealType});

  @override
  Widget build(BuildContext context) {
    context.read<FoodBloc>().add(const FoodLoadRequested());

    return Scaffold(
      appBar: AppBar(
        title: Text(mealType != null ? 'Chọn món ăn' : 'Thư viện thực phẩm'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo món mới'),
      ),
      body: BlocBuilder<FoodBloc, FoodState>(
        builder: (context, state) {
          if (state is FoodLoading || state is FoodInitial) {
            return const _ShimmerList();
          }
          if (state is FoodError) {
            return _ErrorBody(
              message: state.message,
              onRetry: () =>
                  context.read<FoodBloc>().add(const FoodLoadRequested()),
            );
          }
          final loaded = state as FoodLoaded;
          return _FoodTabs(
            systemFoods: loaded.systemFoods,
            userFoods: loaded.userFoods,
            mealType: mealType,
          );
        },
      ),
    );
  }

  void _showAddFoodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<FoodBloc>(),
        child: const AddFoodSheet(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TabBar Body
// ─────────────────────────────────────────────────────────────────────────────

class _FoodTabs extends StatefulWidget {
  final List<FoodModel> systemFoods;
  final List<FoodModel> userFoods;
  final String? mealType;

  const _FoodTabs({
    required this.systemFoods,
    required this.userFoods,
    this.mealType,
  });

  @override
  State<_FoodTabs> createState() => _FoodTabsState();
}

class _FoodTabsState extends State<_FoodTabs> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter by search
    final filteredSystem = widget.systemFoods
        .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final filteredUser = widget.userFoods
        .where((f) => f.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ── Tabs ──
          TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Hệ thống (${filteredSystem.length})'),
              Tab(text: 'Của tôi (${filteredUser.length})'),
            ],
          ),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              children: [
                _FoodList(foods: filteredSystem, mealType: widget.mealType),
                _FoodList(
                  foods: filteredUser,
                  isUserTab: true,
                  mealType: widget.mealType,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food List
// ─────────────────────────────────────────────────────────────────────────────

class _FoodList extends StatelessWidget {
  final List<FoodModel> foods;
  final bool isUserTab;
  final String? mealType;

  const _FoodList({required this.foods, this.isUserTab = false, this.mealType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUserTab ? Icons.egg_outlined : Icons.restaurant_outlined,
              size: 48,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isUserTab
                  ? 'Bạn chưa tạo món ăn nào'
                  : 'Không tìm thấy thực phẩm',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: foods.length,
      separatorBuilder: (_, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final food = foods[index];
        return Card(
          child: ListTile(
            onTap: mealType != null
                ? () => _openFoodDetailSheet(context, food)
                : null,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.restaurant_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            title: Text(food.name, style: theme.textTheme.bodyLarge),
            subtitle: Text(
              '${food.calories.toInt()} kcal · P: ${food.protein.toInt()}g · F: ${food.fat.toInt()}g · C: ${food.carbs.toInt()}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                food.category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  /// Opens the detail sheet for quantity input, pops with MealEntry result.
  void _openFoodDetailSheet(BuildContext context, FoodModel food) async {
    final entry = await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddFoodDetailSheet(food: food, mealType: mealType!),
    );

    if (entry != null && context.mounted) {
      // Pop FoodLibraryScreen with the MealEntry so the caller can handle it
      Navigator.of(context).pop(entry);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Shimmer.fromColors(
      baseColor: isLight ? Colors.grey.shade300 : Colors.grey.shade700,
      highlightColor: isLight ? Colors.grey.shade100 : Colors.grey.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 8,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
