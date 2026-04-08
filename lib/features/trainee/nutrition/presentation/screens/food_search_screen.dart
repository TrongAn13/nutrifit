import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'barcode_scanner_screen.dart';
import 'food_detail_screen.dart';
import 'components/food_quick_view_sheet.dart';

import '../../data/models/food_model.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../logic/food_bloc.dart';
import '../../logic/food_state.dart';
import '../../logic/nutrition_bloc.dart';
import '../../logic/nutrition_event.dart';
import '../../logic/nutrition_state.dart';
import '../../../tracking/data/models/daily_log_model.dart';

// ── Dark theme constants ──
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kSurface = Color(0xFF12141A);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0x14FFFFFF); // white 8%

/// Food search screen acting as a "cart" — lets the trainee browse multiple tabs,
/// pick foods, and confirm them all at once for a given meal.
///
/// Arguments:
///   [mealName] – display name of the meal slot (e.g. "Bữa sáng").
///   [date]     – the date the foods will be logged to.
class FoodSearchScreen extends StatefulWidget {
  final String mealName;
  final DateTime date;

  const FoodSearchScreen({
    super.key,
    required this.mealName,
    required this.date,
  });

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Temporary cart holding selected foods per meal slot.
  final Map<String, List<FoodModel>> _selectedFoodsByMeal = {
    'Bữa sáng': [],
    'Bữa trưa': [],
    'Bữa tối': [],
    'Bữa phụ': [],
  };

  String _selectedCategory = 'Tất cả';
  late String _currentMealName;

  // ── Quick Log form controllers ──
  final _quickNameCtrl = TextEditingController();
  final _quickCalCtrl = TextEditingController();
  final _quickProteinCtrl = TextEditingController();
  final _quickFatCtrl = TextEditingController();
  final _quickCarbsCtrl = TextEditingController();

  bool _hasPrepopulatedMeals = false;

  @override
  void initState() {
    super.initState();
    _currentMealName = widget.mealName;
    _tabController = TabController(length: 4, vsync: this);
  }

  void _prepopulateMeals(DailyLogModel? log) {
    if (log != null &&
        log.date.year == widget.date.year &&
        log.date.month == widget.date.month &&
        log.date.day == widget.date.day) {
      setState(() {
        for (final meal in log.meals) {
          final mName = _mealKeyMap.entries
              .firstWhere(
                (e) => e.value == meal.mealType,
                orElse: () => const MapEntry('Bữa phụ', 'snack'),
              )
              .key;
          _selectedFoodsByMeal[mName]!.add(
            FoodModel(
              foodId: meal.mealId, // Storing mealId as foodId
              name: meal.name,
              category: '#SAVED#', // Flag to avoid re-saving duplicate entries
              calories: meal.calories,
              protein: meal.protein,
              fat: meal.fat,
              carbs: meal.carbs,
              createdAt: DateTime.now(),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickNameCtrl.dispose();
    _quickCalCtrl.dispose();
    _quickProteinCtrl.dispose();
    _quickFatCtrl.dispose();
    _quickCarbsCtrl.dispose();
    super.dispose();
  }

  // ── Cart helpers ──

  void _addToCart(FoodModel food) {
    // Generate an ID for the new meal entry
    final mealKey = _mealKeyMap[_currentMealName] ?? 'snack';
    final mealId = 'meal_${DateTime.now().millisecondsSinceEpoch}_${food.foodId}';
    
    // Save to the database immediately so the parent dashboard updates
    final entry = MealEntry(
      mealId: mealId,
      mealType: mealKey,
      name: food.name,
      calories: food.calories,
      protein: food.protein,
      fat: food.fat,
      carbs: food.carbs,
    );
    context.read<NutritionBloc>().add(NutritionMealAdded(entry, date: widget.date));

    // Keep it in the cart with #SAVED# category so it can be un-added from the cart
    // and won't be saved again by _saveFoods.
    final savedFood = food.copyWith(
      foodId: mealId,
      category: '#SAVED#',
    );

    setState(() {
      _selectedFoodsByMeal[_currentMealName] ??= [];
      _selectedFoodsByMeal[_currentMealName]!.add(savedFood);
    });
  }

  void _removeFromCart(String mealName, int index) {
    setState(() {
      _selectedFoodsByMeal[mealName]?.removeAt(index);
    });
  }

  /// Count of items in the CURRENT meal only.
  int get _currentMealItemCount =>
      (_selectedFoodsByMeal[_currentMealName] ?? []).length;

  int get _cartTotalItems =>
      _selectedFoodsByMeal.values.fold(0, (sum, list) => sum + list.length);

  /// Map Vietnamese meal name → Firestore meal type key.
  static const _mealKeyMap = {
    'Bữa sáng': 'breakfast',
    'Bữa trưa': 'lunch',
    'Bữa tối': 'dinner',
    'Bữa phụ': 'snack',
  };

  /// Extracted save logic to use when pressing Complete or Back.
  Future<void> _saveFoods() async {
    List<MealEntry> allEntries = [];

    for (final entry in _selectedFoodsByMeal.entries) {
      final mealName = entry.key;
      final foods = entry.value;

      if (foods.isEmpty) continue;

      final mealKey = _mealKeyMap[mealName] ?? 'snack';

      allEntries.addAll(
        foods.where((f) => f.category != '#SAVED#').map((food) {
          return MealEntry(
            mealId:
                'meal_${DateTime.now().millisecondsSinceEpoch}_${food.foodId}',
            mealType: mealKey,
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            fat: food.fat,
            carbs: food.carbs,
          );
        }),
      );
    }

    if (allEntries.isEmpty) return;

    try {
      await NutritionRepository().addMealEntries(allEntries, date: widget.date);
      for (final list in _selectedFoodsByMeal.values) {
        list.clear();
      }
    } catch (e) {
      debugPrint('Error auto-saving foods: $e');
    }
  }

  /// Save selected foods as MealEntries and navigate to MealDetailScreen.
  Future<void> _onComplete(BuildContext context) async {
    if (_cartTotalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _kCardBg,
          content: Text(
            'Please select at least one item.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
      return;
    }

    await _saveFoods();

    if (context.mounted) {
      context.pop('go_to_meal_detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NutritionBloc, NutritionState>(
      listener: (context, state) {
        if (!_hasPrepopulatedMeals && state is NutritionLoaded) {
          _hasPrepopulatedMeals = true;
          _prepopulateMeals(state.dailyLog);
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _saveFoods();
        },
        child: Scaffold(
          backgroundColor: _kBg,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // ── Search bar + Quick actions ──
              _SearchAndActions(onBarcodeScan: _openBarcodeScanner),
              const SizedBox(height: 4),

              // ── TabBar ──
              _buildTabBar(context),

              // ── TabBarView ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RecentTab(
                      onAddFood: _addToCart,
                      onFoodTap: _openFoodDetail,
                      mealType: _mealKeyMap[widget.mealName] ?? 'snack',
                    ),
                    BlocBuilder<FoodBloc, FoodState>(
                      builder: (context, foodState) {
                        if (foodState is FoodLoading ||
                            foodState is FoodInitial) {
                          return const Center(
                            child: CircularProgressIndicator(color: _kLime),
                          );
                        }
                        if (foodState is FoodError) {
                          return Center(
                            child: Text(
                              'Error: ${foodState.message}',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                              ),
                            ),
                          );
                        }
                        final loaded = foodState as FoodLoaded;
                        final allFoods = [
                          ...loaded.systemFoods,
                          ...loaded.userFoods,
                        ];
                        // Build categories dynamically
                        final categories = [
                          'Tất cả',
                          ...{for (final f in allFoods) f.category},
                        ];
                        return _PopularTab(
                          foods: allFoods,
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (cat) =>
                              setState(() => _selectedCategory = cat),
                          onAddFood: _addToCart,
                          onFoodTap: _openFoodDetail,
                        );
                      },
                    ),
                    const _CollectionsTab(),
                    _QuickLogTab(
                      nameCtrl: _quickNameCtrl,
                      calCtrl: _quickCalCtrl,
                      proteinCtrl: _quickProteinCtrl,
                      fatCtrl: _quickFatCtrl,
                      carbsCtrl: _quickCarbsCtrl,
                      onQuickLog: _handleQuickLog,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Bottom Cart Bar ──
          bottomNavigationBar: _buildBottomBar(context),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final dateLabel = '${widget.date.day}/${widget.date.month}';

    return AppBar(
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          await _saveFoods();
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        },
      ),
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          '$_currentMealName • $dateLabel',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TabBar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: _kBg,
      child: TabBar(
        controller: _tabController,
        labelColor: _kLime,
        unselectedLabelColor: Colors.white54,
        indicatorColor: _kLime,
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: false,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: const [
          Tab(text: 'Recent'),
          Tab(text: 'Popular'),
          Tab(text: 'Saved'),
          Tab(text: 'Quick Log'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Cart Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ── Left: meal button with badge (current meal count only) ──
            Expanded(
              child: GestureDetector(
                onTap: _showCartSheet,
                child: Row(
                  children: [
                    // Icon with per-meal badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white70,
                          size: 22,
                        ),
                        if (_currentMealItemCount > 0)
                          Positioned(
                            top: -6,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: _kLime,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_currentMealItemCount',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currentMealName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // ── Right: complete button ──
            FilledButton(
              onPressed: () => _onComplete(context),
              style: FilledButton.styleFrom(
                backgroundColor: _kLime,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cart BottomSheet
  // ─────────────────────────────────────────────────────────────────────────

  bool _isCartSheetOpen = false;

  void _showCartSheet() async {
    if (_isCartSheetOpen || !ModalRoute.of(context)!.isCurrent) return;

    _isCartSheetOpen = true;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CartBottomSheet(
        selectedFoodsByMeal: _selectedFoodsByMeal,
        mealName: _currentMealName,
        onRemoveFood: (meal, index) {
          _removeFromCart(meal, index);
        },
        onDeleteSavedFood: (meal, index, foodId) {
          _removeFromCart(meal, index);
          context.read<NutritionBloc>().add(
            NutritionMealDeleted(date: widget.date, mealId: foodId),
          );
        },
        onMealChanged: (newMeal) {
          setState(() => _currentMealName = newMeal);
        },
      ),
    );
    _isCartSheetOpen = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Log handler
  // ─────────────────────────────────────────────────────────────────────────

  void _handleQuickLog() {
    final name = _quickNameCtrl.text.trim();
    final cal = double.tryParse(_quickCalCtrl.text.trim()) ?? 0;
    final protein = double.tryParse(_quickProteinCtrl.text.trim()) ?? 0;
    final fat = double.tryParse(_quickFatCtrl.text.trim()) ?? 0;
    final carbs = double.tryParse(_quickCarbsCtrl.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _kCardBg,
          content: Text(
            'Please enter food name',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final food = FoodModel(
      foodId: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: 'Quick Log',
      calories: cal,
      protein: protein,
      fat: fat,
      carbs: carbs,
      createdAt: DateTime.now(),
    );

    _addToCart(food);

    // Clear fields
    _quickNameCtrl.clear();
    _quickCalCtrl.clear();
    _quickProteinCtrl.clear();
    _quickFatCtrl.clear();
    _quickCarbsCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _kCardBg,
        content: Text(
          'Added "$name" to cart',
          style: GoogleFonts.inter(color: _kLime),
        ),
      ),
    );
  }

  /// Opens the barcode scanner, then navigates to FoodDetailScreen.
  void _openBarcodeScanner() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      final food = FoodModel(
        foodId: 'barcode_${result['barcode'] ?? DateTime.now().millisecondsSinceEpoch}',
        name: result['name'] as String? ?? 'Unknown',
        category: 'Barcode',
        calories: (result['calories'] as num?)?.toDouble() ?? 0,
        protein: (result['protein'] as num?)?.toDouble() ?? 0,
        fat: (result['fat'] as num?)?.toDouble() ?? 0,
        carbs: (result['carbs'] as num?)?.toDouble() ?? 0,
        imageUrl: result['imageUrl'] as String?,
        createdAt: DateTime.now(),
      );
      // Open detail screen so user can review before logging
      _openFoodDetail(food);
    }
  }

  /// Opens [FoodQuickViewSheet] for preview and quick log.
  /// If the user clicks on the name, it navigates to [FoodDetailScreen].
  /// If the user logs the food (returns a FoodModel), it is added to the cart.
  void _openFoodDetail(FoodModel food) async {
    final result = await showModalBottomSheet<FoodModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodQuickViewSheet(
        food: food,
        mealName: _currentMealName,
        date: widget.date,
      ),
    );

    if (result != null && mounted) {
      _addToCart(result);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Search Bar & Quick Actions
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchAndActions extends StatelessWidget {
  final VoidCallback? onBarcodeScan;

  const _SearchAndActions({this.onBarcodeScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.white38, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search food...',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick action cards
          Row(
            children: [
              _QuickActionCard(
                icon: Icons.document_scanner_outlined,
                label: 'Scan AI',
              ),
              const SizedBox(width: 10),
              _QuickActionCard(
                icon: Icons.qr_code_scanner,
                label: 'Barcode',
                onTap: onBarcodeScan,
              ),
              const SizedBox(width: 10),
              _QuickActionCard(
                icon: Icons.mic_none_outlined,
                label: 'Voice',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: _kLime),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Cart BottomSheet (Two-column layout)
// ═══════════════════════════════════════════════════════════════════════════════

/// Custom bottom sheet displaying a meal-type sidebar and selected foods list.
class _CartBottomSheet extends StatefulWidget {
  final Map<String, List<FoodModel>> selectedFoodsByMeal;
  final String mealName;
  final void Function(String meal, int index) onRemoveFood;
  final void Function(String meal, int index, String foodId)? onDeleteSavedFood;
  final ValueChanged<String>? onMealChanged;

  const _CartBottomSheet({
    required this.selectedFoodsByMeal,
    required this.mealName,
    required this.onRemoveFood,
    this.onDeleteSavedFood,
    this.onMealChanged,
  });

  @override
  State<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<_CartBottomSheet> {
  static const _mealSlots = [
    {'label': 'Bữa sáng', 'key': 'breakfast'},
    {'label': 'Bữa trưa', 'key': 'lunch'},
    {'label': 'Bữa tối', 'key': 'dinner'},
    {'label': 'Bữa phụ', 'key': 'snack'},
  ];

  late String _selectedMeal;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.mealName;
  }

  List<FoodModel> get _currentList =>
      widget.selectedFoodsByMeal[_selectedMeal] ?? [];

  double get _totalCalories =>
      _currentList.fold(0, (sum, f) => sum + f.calories);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.6,
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Two-column body
          Expanded(
            child: Row(
              children: [
                // ── Left column: Meal menu (Flex 3) ──
                Flexible(
                  flex: 3,
                  child: Container(
                    color: _kSurface,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _mealSlots.length,
                      itemBuilder: (_, index) {
                        final slot = _mealSlots[index];
                        final label = slot['label']!;
                        final isSelected = label == _selectedMeal;
                        final itemCount =
                            (widget.selectedFoodsByMeal[label] ?? []).length;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedMeal = label);
                            if (widget.onMealChanged != null) {
                              widget.onMealChanged!(label);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _kCardBg
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: _kLime.withValues(alpha: 0.3))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (itemCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kLime,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$itemCount',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Right column: Selected foods (Flex 7) ──
                Flexible(
                  flex: 7,
                  child: Container(
                    color: _kCardBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header — shows count for THIS meal only
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${_currentList.length} items • ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: '${_totalCalories.toInt()} Cal',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: _kLime,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),

                        // Food list or empty state
                        Expanded(
                          child: _currentList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.no_food_outlined,
                                        size: 48,
                                        color: Colors.white24,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No food logged yet.',
                                        style: GoogleFonts.inter(
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  itemCount: _currentList.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color:
                                        Colors.white.withValues(alpha: 0.06),
                                  ),
                                  itemBuilder: (_, index) {
                                    final food = _currentList[index];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.restaurant,
                                          size: 18,
                                          color: _kCardBg,
                                        ),
                                      ),
                                      title: Text(
                                        food.name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${food.calories.toInt()} Cal • 100g',
                                        style: GoogleFonts.inter(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white38,
                                        ),
                                        onPressed: () {
                                          if (food.category == '#SAVED#') {
                                            widget.onDeleteSavedFood?.call(
                                              _selectedMeal,
                                              index,
                                              food.foodId,
                                            );
                                          } else {
                                            widget.onRemoveFood(
                                              _selectedMeal,
                                              index,
                                            );
                                          }
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1 — Recent
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentTab extends StatelessWidget {
  final ValueChanged<FoodModel> onAddFood;
  final ValueChanged<FoodModel> onFoodTap;
  final String mealType;

  const _RecentTab({
    required this.onAddFood,
    required this.onFoodTap,
    required this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NutritionBloc, NutritionState>(
      builder: (context, state) {
        // Extract logged meals for this meal type from the daily log
        List<MealEntry> recentMeals = [];
        if (state is NutritionLoaded && state.dailyLog != null) {
          final allMeals = state.dailyLog!.meals.toList();

          // Deduplicate by name (keep the first occurrence)
          final seenNames = <String>{};
          for (final meal in allMeals) {
            if (seenNames.add(meal.name.toLowerCase())) {
              recentMeals.add(meal);
            }
          }
        }

        if (recentMeals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    'No recent items for this meal.',
                    style: GoogleFonts.inter(color: Colors.white38),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: recentMeals.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          itemBuilder: (context, index) {
            final meal = recentMeals[index];
            final foodModel = FoodModel(
              foodId: meal.mealId,
              name: meal.name,
              category: 'Recent',
              calories: meal.calories,
              protein: meal.protein,
              fat: meal.fat,
              carbs: meal.carbs,
              imageUrl: null, // Since MealEntry doesn't store imageUrl yet
              createdAt: DateTime.now(),
            );

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              onTap: () => onFoodTap(foodModel),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 22,
                  color: _kCardBg,
                ),
              ),
              title: Text(
                meal.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                '${meal.calories.toInt()} Cal',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add, color: _kLime),
                onPressed: () => onAddFood(foodModel),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2 — Popular
// ═══════════════════════════════════════════════════════════════════════════════

class _PopularTab extends StatelessWidget {
  final List<FoodModel> foods;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<FoodModel> onAddFood;
  final ValueChanged<FoodModel> onFoodTap;

  const _PopularTab({
    required this.foods,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onAddFood,
    required this.onFoodTap,
  });

  @override
  Widget build(BuildContext context) {
    final filteredFoods = selectedCategory == 'Tất cả'
        ? foods
        : foods.where((f) => f.category == selectedCategory).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category sidebar ──
        SizedBox(
          width: 100,
          child: Container(
            color: _kSurface,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              itemBuilder: (_, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;

                return GestureDetector(
                  onTap: () => onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _kCardBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: _kLime.withValues(alpha: 0.3),
                            )
                          : null,
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Vertical divider
        Container(
          width: 0.5,
          color: Colors.white.withValues(alpha: 0.08),
        ),

        // ── Food list ──
        Expanded(
          child: filteredFoods.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No food in this category.',
                      style: GoogleFonts.inter(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: filteredFoods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final food = filteredFoods[index];
                    return _PopularFoodItem(
                      food: food,
                      onAdd: () => onAddFood(food),
                      onTap: () => onFoodTap(food),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// A single row in the Popular tab food list.
class _PopularFoodItem extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const _PopularFoodItem({
    required this.food,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
        children: [
          // Image or Placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                ? Image.network(
                    food.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),

          // Name & calories
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${food.calories.toInt()} Cal • 100g',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Add button
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _kLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.restaurant, size: 22, color: _kCardBg),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 3 — Collections
// ═══════════════════════════════════════════════════════════════════════════════

class _CollectionsTab extends StatelessWidget {
  const _CollectionsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select collection type',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'My Foods',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Empty state
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.collections_bookmark_outlined,
                    size: 64,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You have no saved foods yet.',
                    style: GoogleFonts.inter(color: Colors.white38),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to create food flow
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Create New Food',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kLime,
                      side: const BorderSide(color: _kLime),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 4 — Quick Log
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickLogTab extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController calCtrl;
  final TextEditingController proteinCtrl;
  final TextEditingController fatCtrl;
  final TextEditingController carbsCtrl;
  final VoidCallback onQuickLog;

  const _QuickLogTab({
    required this.nameCtrl,
    required this.calCtrl,
    required this.proteinCtrl,
    required this.fatCtrl,
    required this.carbsCtrl,
    required this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _inputField(label: 'Food Name', controller: nameCtrl),
          const SizedBox(height: 14),
          _inputField(
            label: 'Calories (Cal)',
            controller: calCtrl,
            isNumeric: true,
          ),
          const SizedBox(height: 14),

          // Macro row
          Row(
            children: [
              Expanded(
                child: _inputField(
                  label: 'Protein (g)',
                  controller: proteinCtrl,
                  isNumeric: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  label: 'Fat (g)',
                  controller: fatCtrl,
                  isNumeric: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  label: 'Carbs (g)',
                  controller: carbsCtrl,
                  isNumeric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onQuickLog,
              style: FilledButton.styleFrom(
                backgroundColor: _kLime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Quick Log',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white38),
        filled: true,
        fillColor: _kCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kLime),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
