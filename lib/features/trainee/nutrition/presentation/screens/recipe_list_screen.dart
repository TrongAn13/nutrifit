import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/recipe_model.dart';
import '../../logic/recipe_cubit.dart';
import 'recipe_detail_screen.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kSurface = Color(0xFF12141A);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0x14FFFFFF);
const Color _kTextSecondary = Color(0xFF8A8F9D);

// ── Tab definitions per groupType ─────────────────────────────────────────────

class _TabItem {
  final String emoji;
  final String label;
  final String value;
  const _TabItem({required this.emoji, required this.label, required this.value});
}

const _energyTabs = [
  _TabItem(emoji: '🍉', label: '0–50 kcal',   value: '0-50'),
  _TabItem(emoji: '🍌', label: '50–100 kcal',  value: '50-100'),
  _TabItem(emoji: '🍞', label: '100–200 kcal', value: '100-200'),
  _TabItem(emoji: '🍩', label: '200–300 kcal', value: '200-300'),
  _TabItem(emoji: '🥘', label: '300–400 kcal', value: '300-400'),
  _TabItem(emoji: '🍱', label: '400–500 kcal', value: '400-500'),
];

const _cookingTabs = [
  _TabItem(emoji: '🌯', label: 'Trộn, Cuốn',       value: 'tossed'),
  _TabItem(emoji: '♨️', label: 'Luộc và hấp',      value: 'boiled'),
  _TabItem(emoji: '🍜', label: 'Món bún, phở',     value: 'noodle_soup'),
  _TabItem(emoji: '🍳', label: 'Xào, Sốt, Rang',   value: 'stir_fried'),
  _TabItem(emoji: '🔥', label: 'Nướng, quay, rán', value: 'grilled'),
  _TabItem(emoji: '🫕', label: 'Hầm, Om, Kho',     value: 'braised'),
];

const _dietTabs = [
  _TabItem(emoji: '📱', label: 'Low Calorie',  value: 'low_calorie'),
  _TabItem(emoji: '🥗', label: 'Eat Clean',    value: 'eat_clean'),
  _TabItem(emoji: '🥩', label: 'High Protein', value: 'high_protein'),
  _TabItem(emoji: '🌱', label: 'Vegan',        value: 'vegan'),
  _TabItem(emoji: '🧈', label: 'Keto',         value: 'keto'),
  _TabItem(emoji: '🩺', label: 'Diabetic',     value: 'diabetic'),
];

const _ingredientTabs = [
  _TabItem(emoji: '🥩', label: 'Thịt',          value: 'meat'),
  _TabItem(emoji: '🥦', label: 'Rau, củ',       value: 'vegetables'),
  _TabItem(emoji: '🌾', label: 'Ngũ cốc',       value: 'grains'),
  _TabItem(emoji: '🦑', label: 'Thủy, hải sản', value: 'seafood'),
  _TabItem(emoji: '🥛', label: 'Sữa',           value: 'dairy'),
  _TabItem(emoji: '🥚', label: 'Trứng',         value: 'eggs'),
];

const _mealTimeTabs = [
  _TabItem(emoji: '🍳', label: 'Bữa sáng', value: 'breakfast'),
  _TabItem(emoji: '🍱', label: 'Bữa trưa', value: 'lunch'),
  _TabItem(emoji: '🌙', label: 'Bữa tối',  value: 'dinner'),
  _TabItem(emoji: '🫐', label: 'Bữa phụ',  value: 'snack'),
];

List<_TabItem> _tabsForGroup(String groupType) {
  switch (groupType) {
    case 'energy':     return _energyTabs;
    case 'cooking':    return _cookingTabs;
    case 'diet':       return _dietTabs;
    case 'ingredient': return _ingredientTabs;
    case 'mealtime':   return _mealTimeTabs;
    default:           return _energyTabs;
  }
}

// ── Section grouping (always by cookingMethod) ────────────────────────────────

const _cookingMethodLabels = <String, (String, String)>{
  'tossed':      ('🌯', 'Trộn, Cuốn'),
  'boiled':      ('♨️', 'Luộc và hấp'),
  'noodle_soup': ('🍜', 'Món bún, phở'),
  'stir_fried':  ('🍳', 'Xào, Sốt, Rang'),
  'grilled':     ('🔥', 'Nướng, quay, rán'),
  'braised':     ('🫕', 'Hầm, Om, Kho'),
};

// ── Entry point ───────────────────────────────────────────────────────────────

/// Recipe list screen.
///
/// [sectionTitle]       – shown in the header (e.g. "CHẾ ĐỘ ĂN KIÊNG").
/// [groupType]          – determines which tabs to show: 'energy' | 'cooking' | 'diet' | 'ingredient' | 'mealtime'.
/// [initialFilterValue] – pre-selects the tab that matches this value when entering from Browse.
/// [initialFilterLabel] – human-readable label for the pre-selected tab.
class RecipeListScreen extends StatelessWidget {
  final String sectionTitle;
  final String groupType;
  final String initialFilterValue;
  final String initialFilterLabel;

  const RecipeListScreen({
    super.key,
    required this.sectionTitle,
    this.groupType = 'energy',
    this.initialFilterValue = '',
    this.initialFilterLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecipeCubit()..loadAll(
        initialGroupType: groupType,
        initialValue: initialFilterValue,
        initialLabel: initialFilterLabel,
      ),
      child: _RecipeListView(
        sectionTitle: sectionTitle,
        groupType: groupType,
        initialFilterValue: initialFilterValue,
        initialFilterLabel: initialFilterLabel,
      ),
    );
  }
}

// ── Main view ─────────────────────────────────────────────────────────────────

class _RecipeListView extends StatefulWidget {
  final String sectionTitle;
  final String groupType;
  final String initialFilterValue;
  final String initialFilterLabel;

  const _RecipeListView({
    required this.sectionTitle,
    required this.groupType,
    required this.initialFilterValue,
    required this.initialFilterLabel,
  });

  @override
  State<_RecipeListView> createState() => _RecipeListViewState();
}

class _RecipeListViewState extends State<_RecipeListView> {
  late int _selectedTabIndex;
  late List<_TabItem> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = _tabsForGroup(widget.groupType);

    // Find index of the initially requested filter value
    final idx = _tabs.indexWhere((t) => t.value == widget.initialFilterValue);
    _selectedTabIndex = idx >= 0 ? idx : 0;
  }

  void _applyTab(int index) {
    final cubit = context.read<RecipeCubit>();
    final tab = _tabs[index];

    if (widget.groupType == 'energy') {
      final parts = tab.value.split('-');
      final min = double.tryParse(parts[0]) ?? 0;
      final max = double.tryParse(parts[1]) ?? 9999;
      cubit.filterByCalories(min: min, max: max, label: tab.label);
    } else {
      final fieldMap = {
        'cooking':    'cookingMethod',
        'diet':       'dietMode',
        'ingredient': 'mainIngredient',
        'mealtime':   'mealTime',
      };
      final field = fieldMap[widget.groupType] ?? 'mealTime';
      cubit.filterByField(field: field, value: tab.value, label: tab.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<RecipeCubit, RecipeState>(
                builder: (context, state) {
                  if (state is RecipeLoading || state is RecipeInitial) {
                    return _buildShimmer();
                  }
                  if (state is RecipeError) {
                    return _buildError(state.message);
                  }
                  final recipes = (state as RecipeLoaded).recipes;
                  if (recipes.isEmpty) return _buildEmpty();
                  return _buildSections(recipes);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.sectionTitle,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _IconBtn(icon: Icons.search, onTap: () {}),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = index == _selectedTabIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTabIndex = index);
              _applyTab(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _kLime.withOpacity(0.12) : _kSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? _kLime : _kBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check_circle, color: _kLime, size: 14),
                    const SizedBox(width: 6),
                  ] else ...[
                    Text(tab.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    tab.label,
                    style: GoogleFonts.inter(
                      color: isSelected ? _kLime : _kTextSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
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

  bool _recipeMatchesCategory(RecipeModel r, String groupType, String value) {
    switch (groupType) {
      case 'energy':
        final parts = value.split('-');
        final min = double.tryParse(parts[0]) ?? 0;
        final max = double.tryParse(parts[1]) ?? 9999;
        return r.calories >= min && r.calories < max;
      case 'cooking':
        return r.cookingMethod == value;
      case 'diet':
        return r.dietMode == value;
      case 'ingredient':
        return r.mainIngredient == value;
      case 'mealtime':
        return r.mealTime == value;
      default:
        return false;
    }
  }

  // ── Sections (grouped dynamically by OTHER groups) ──────────────────────────

  Widget _buildSections(List<RecipeModel> recipes) {
    final List<Widget> sectionWidgets = [];
    final allGroups = ['energy', 'cooking', 'diet', 'ingredient', 'mealtime'];

    for (final group in allGroups) {
      if (group == widget.groupType) continue; // Skip the currently filtered group

      final tabs = _tabsForGroup(group);
      for (final tab in tabs) {
        final matchingRecipes = recipes
            .where((r) => _recipeMatchesCategory(r, group, tab.value))
            .toList();

        if (matchingRecipes.isNotEmpty) {
          sectionWidgets.add(_buildSection(
            emoji: tab.emoji,
            label: tab.label,
            recipes: matchingRecipes,
          ));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: sectionWidgets,
    );
  }

  Widget _buildSection({
    required String emoji,
    required String label,
    required List<RecipeModel> recipes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                'Xem thêm',
                style: GoogleFonts.inter(
                  color: _kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: _kTextSecondary,
                ),
              ),
            ],
          ),
        ),
        // Horizontal cards
        SizedBox(
          height: 215,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _RecipeCard(recipe: recipes[i]),
          ),
        ),
      ],
    );
  }

  // ── Empty / Shimmer / Error ───────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy công thức',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử chọn bộ lọc khác',
            style: GoogleFonts.inter(color: _kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 3,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title placeholder
          Container(
            width: 140,
            height: 18,
            margin: const EdgeInsets.only(bottom: 12, top: 20),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(
            height: 215,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => Container(
                width: 160,
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text('Có lỗi xảy ra',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(message,
              style: GoogleFonts.inter(color: _kTextSecondary, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.read<RecipeCubit>().loadAll(),
            child: Text('Thử lại', style: GoogleFonts.inter(color: _kLime)),
          ),
        ],
      ),
    );
  }
}

// ── Recipe Card ───────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: recipe.imageUrl != null
                  ? Image.network(
                      recipe.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emojiPlaceholder(),
                    )
                  : _emojiPlaceholder(),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.calories.toInt()} Kcal',
                    style: GoogleFonts.inter(
                      color: _kLime,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _emojiPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: _kSurface,
      child: Center(
        child: Text(_mealEmoji(recipe.mealTime), style: const TextStyle(fontSize: 44)),
      ),
    );
  }

  String _mealEmoji(String mealTime) {
    switch (mealTime) {
      case 'breakfast': return '🍳';
      case 'lunch':     return '🍱';
      case 'dinner':    return '🌙';
      case 'snack':     return '🫐';
      default:          return '🥗';
    }
  }
}

// ── Icon Button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}