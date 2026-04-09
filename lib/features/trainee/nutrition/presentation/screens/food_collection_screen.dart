import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrifit/features/trainee/nutrition/presentation/screens/create_food_step1_screen.dart';
import '../../logic/nutrition_bloc.dart';
import '../../logic/nutrition_event.dart';

import '../../data/models/recipe_model.dart';
import '../../data/models/food_model.dart';
import 'recipe_detail_screen.dart';
import 'components/food_quick_view_sheet.dart';
import 'recipe_favorite_store.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../../tracking/data/models/daily_log_model.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kSurface = Color(0xFF12141A);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0x18FFFFFF);
const Color _kTextSecondary = Color(0xFF8A8F9D);
const Color _kDropdownBg = Color(0xFF1E2128);

// ── Collection types ──────────────────────────────────────────────────────────

enum _CollectionType {
  customFood,
  favoriteFood,
  favoriteRecipe,
  scannedFood,
}

extension _CollectionTypeX on _CollectionType {
  String get label {
    switch (this) {
      case _CollectionType.customFood:
        return 'Thực phẩm tự tạo';
      case _CollectionType.favoriteFood:
        return 'Thực phẩm yêu thích';
      case _CollectionType.favoriteRecipe:
        return 'Công thức yêu thích';
      case _CollectionType.scannedFood:
        return 'Thực phẩm đã scan';
    }
  }

  IconData get phosphorIcon {
    switch (this) {
      case _CollectionType.customFood:
        return PhosphorIconsRegular.cookingPot;
      case _CollectionType.favoriteFood:
        return PhosphorIconsRegular.heart;
      case _CollectionType.favoriteRecipe:
        return PhosphorIconsRegular.bookmarkSimple;
      case _CollectionType.scannedFood:
        return PhosphorIconsRegular.barcode;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class FoodCollectionScreen extends StatefulWidget {
  const FoodCollectionScreen({super.key});

  @override
  State<FoodCollectionScreen> createState() => _FoodCollectionScreenState();
}

class _FoodCollectionScreenState extends State<FoodCollectionScreen> {
  _CollectionType _selected = _CollectionType.customFood;
  bool _dropdownOpen = false;
  final _dropdownKey = GlobalKey();
  final _stackKey = GlobalKey();

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap outside to close dropdown
      onTap: () {
        if (_dropdownOpen) setState(() => _dropdownOpen = false);
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(context),
        floatingActionButton: _selected == _CollectionType.customFood
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateFoodStep1Screen(isMeal: false)),
                  );
                },
                backgroundColor: _kLime,
                child: const Icon(Icons.add, color: _kBg),
              )
            : null,
        body: Stack(
          key: _stackKey,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterRow(),
                const SizedBox(height: 8),
                Expanded(child: _buildBody()),
              ],
            ),
            // Dropdown overlay
            if (_dropdownOpen) _buildDropdownOverlay(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
      ),
      title: Text(
        'Bộ sưu tập',
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  // ── Filter Row ──────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Chọn loại bộ sưu tập',
            style: GoogleFonts.inter(
                color: _kLime, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              key: _dropdownKey,
              onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selected.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _dropdownOpen
                          ? PhosphorIcons.caretUp()
                          : PhosphorIcons.caretDown(),
                      color: _kTextSecondary,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdown Overlay ────────────────────────────────────────────────────────

  Widget _buildDropdownOverlay() {
    final RenderBox? buttonBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;

    if (buttonBox == null || stackBox == null) return const SizedBox.shrink();

    final size = buttonBox.size;
    final offset = buttonBox.localToGlobal(Offset.zero, ancestor: stackBox);

    return Positioned(
      top: offset.dy,
      left: offset.dx,
      width: size.width,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _kDropdownBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _CollectionType.values.asMap().entries.map((entry) {
              final i = entry.key;
              final type = entry.value;
              final isSelected = type == _selected;
              final isLast = i == _CollectionType.values.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selected = type;
                        _dropdownOpen = false;
                      });
                    },
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(16) : Radius.zero,
                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              type.label,
                              style: GoogleFonts.inter(
                                color: isSelected ? _kLime : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(PhosphorIcons.caretUp(),
                                color: _kTextSecondary, size: 13),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.06), indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_selected == _CollectionType.favoriteRecipe) {
      return ValueListenableBuilder<Map<String, RecipeModel>>(
        valueListenable: RecipeFavoriteStore.favorites,
        builder: (context, favMap, _) {
          final recipes = favMap.values.toList();
          if (recipes.isEmpty) return _buildEmpty();
          return _buildRecipeGrid(recipes);
        },
      );
    }

    if (_selected == _CollectionType.customFood) {
      final userId = _currentUserId;
      if (userId == null) return _buildEmpty();

      final stream = FirebaseFirestore.instance
          .collection('trainee_food')
          .where('userId', isEqualTo: userId)
          .where('isMeal', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots();

      return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kLime));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty();
          }
          final foods = snapshot.data!.docs.map((doc) {
            return FoodModel.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();
          return _buildFoodGrid(foods);
        },
      );
    }

    return _buildEmpty();
  }

  // ── Recipe Grid ─────────────────────────────────────────────────────────────

  Widget _buildRecipeGrid(List<RecipeModel> recipes) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) => _RecipeCard(recipe: recipes[index]),
    );
  }

  Widget _buildFoodGrid(List<FoodModel> foods) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: foods.length,
      itemBuilder: (context, index) => _FoodCard(food: foods[index]),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _kCardBg,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: Icon(PhosphorIcons.basket(), size: 40, color: _kTextSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có dữ liệu',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Bộ sưu tập "${_selected.label}" của bạn đang trống.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _kTextSecondary, fontSize: 13),
            ),
          ),
          if (_selected == _CollectionType.favoriteRecipe) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Nhấn ❤️ trên trang chi tiết công thức để thêm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: _kTextSecondary, fontSize: 12),
              ),
            ),
          ],
          if (_selected == _CollectionType.customFood) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateFoodStep1Screen(isMeal: false)),
                );
              },
              icon: const Icon(Icons.add, color: _kBg, size: 20),
              label: Text(
                'Tạo thực phẩm mới',
                style: GoogleFonts.inter(color: _kBg, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kLime,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Recipe card ───────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final emoji = switch (recipe.mealTime) {
      'breakfast' => '🍳',
      'lunch' => '🍱',
      'dinner' => '🌙',
      'snack' => '🫐',
      _ => '🥗',
    };

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (takes 65% of card height — keeps it roughly square visually)
            Expanded(
              flex: 65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                      ? Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _EmojiPlaceholder(emoji: emoji),
                        )
                      : _EmojiPlaceholder(emoji: emoji),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showOptions(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(PhosphorIcons.dotsThreeVertical(), color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Info
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${recipe.calories.toInt()} Calo  •  ${recipe.servings} khẩu phần',
                      style: GoogleFonts.inter(color: _kLime, fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.heart(PhosphorIconsStyle.fill), color: Colors.redAccent, size: 20),
              title: Text('Bỏ yêu thích', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
              onTap: () {
                RecipeFavoriteStore.toggle(recipe);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Emoji Placeholder ─────────────────────────────────────────────────────────

class _EmojiPlaceholder extends StatelessWidget {
  final String emoji;
  const _EmojiPlaceholder({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
    );
  }
}

// ── Food Card ───────────────────────────────────────────────────────────────

class _FoodCard extends StatelessWidget {
  final FoodModel food;
  const _FoodCard({required this.food});

  void _openQuickView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodQuickViewSheet(
        food: food,
        onDirectSave: (adjusted, mealName, date) async {
          const mealKeyMap = {
            'Bữa sáng': 'breakfast',
            'Bữa trưa': 'lunch',
            'Bữa tối': 'dinner',
            'Bữa phụ': 'snack',
          };
          final mealKey = mealKeyMap[mealName] ?? 'snack';
          final mealId = 'meal_${DateTime.now().millisecondsSinceEpoch}_${adjusted.foodId}';
          final entry = MealEntry(
            mealId: mealId,
            mealType: mealKey,
            name: adjusted.name,
            calories: adjusted.calories,
            protein: adjusted.protein,
            fat: adjusted.fat,
            carbs: adjusted.carbs,
          );
          try {
            // Use NutritionBloc if available so dashboard auto-refreshes
            try {
              final bloc = context.read<NutritionBloc>();
              bloc.add(NutritionMealAdded(entry, date: date));
            } catch (_) {
              // Bloc not in widget tree — save directly via repository
              await NutritionRepository().addMealEntries([entry], date: date);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _kCardBg,
                  content: Text(
                    'Added "${adjusted.name}" to $mealName successfully!',
                    style: GoogleFonts.inter(color: _kLime),
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error saving food from collection: $e');
          }
        },
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Title row with close button
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 48), // Balance the close button
                  Expanded(
                    child: Text(
                      'Tùy chỉnh',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.close, color: Colors.white54, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            // Edit option
            ListTile(
              leading: Icon(PhosphorIcons.pencilSimple(), color: Colors.white, size: 22),
              title: Text(
                'Chỉnh sửa dữ liệu',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _navigateToEdit(context);
              },
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06), indent: 56),
            // Delete option
            ListTile(
              leading: Icon(PhosphorIcons.trash(), color: Colors.redAccent, size: 22),
              title: Text(
                'Xóa khỏi bộ sưu tập',
                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFoodStep1Screen(
          isMeal: food.isMeal,
          existingFood: food,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận xóa',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${food.name}" khỏi bộ sưu tập?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteFood(context);
            },
            child: Text('Xóa', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFood(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('trainee_food')
          .doc(food.foodId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _kCardBg,
            content: Text(
              'Đã xóa "${food.name}" khỏi bộ sưu tập.',
              style: GoogleFonts.inter(color: _kLime),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting food: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Lỗi khi xóa: $e', style: GoogleFonts.inter(color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openQuickView(context),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? Image.network(food.imageUrl!, fit: BoxFit.cover)
                      : const _EmojiPlaceholder(emoji: '🍽️'),
                  // 3-dot menu button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showOptionsSheet(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(PhosphorIcons.dotsThreeVertical(), color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.calories.toStringAsFixed(0)} kcal • 1 ${food.servingType}',
                    style: GoogleFonts.inter(
                      color: _kLime,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
