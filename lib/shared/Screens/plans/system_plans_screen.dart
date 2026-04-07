import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/trainee/workout/data/models/workout_plan_model.dart';
import '../../../features/trainee/workout/data/repositories/workout_repository.dart';
import 'favorite_system_plans_screen.dart';
import 'system_plan_detail_screen.dart';
import 'widgets/plan_filter_bottom_sheet.dart' as plan_filter;

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF060708);
const Color _kCardColor = Color(0xFF1B1D22);
const Color _kBackBtnBg = Color(0xFF1B1D22);
const Color _kSearchBg = Color(0xFF1B1D22);

/// Fallback colors for cards without imageUrl.
const List<Color> _kCardColors = [
  Color(0xFF2A2D35),
  Color(0xFF1E2428),
  Color(0xFF2D2A22),
  Color(0xFF2A1E28),
  Color(0xFF1E2D2A),
  Color(0xFF282A2D),
];

/// System plans listing screen for coaches.
///
/// Fetches workout plans with [isTemplate] = true from Firestore
/// and displays them in a 2-column grid.
class SystemPlansScreen extends StatefulWidget {
  const SystemPlansScreen({super.key});

  @override
  State<SystemPlansScreen> createState() => _SystemPlansScreenState();
}

class _SystemPlansScreenState extends State<SystemPlansScreen> {
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  late Future<List<WorkoutPlanModel>> _plansFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<WorkoutPlanModel> _allPlans = [];
  String? _selectedCategory;
  String? _selectedEquipment;
  String? _selectedLevel;
  int? _selectedDaysPerWeek;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _plansFuture = _fetchPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch all system template plans from Firestore.
  Future<List<WorkoutPlanModel>> _fetchPlans() async {
    try {
      _allPlans = await _workoutRepository.getSystemTemplates();

      return _allPlans;
    } catch (e) {
      debugPrint('Error fetching system plans: $e');
      return [];
    }
  }

  /// Filter plans by search query.
  List<WorkoutPlanModel> get _filteredPlans {
    var plans = _allPlans;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      plans = plans.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.level.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    }

    if (_selectedCategory != null) {
      plans = plans.where((p) => p.category == _selectedCategory).toList();
    }
    if (_selectedLevel != null) {
      plans = plans.where((p) => p.level == _selectedLevel).toList();
    }
    if (_selectedDaysPerWeek != null) {
      plans = plans
          .where((p) => p.sessionsPerWeek == _selectedDaysPerWeek)
          .toList();
    }
    if (_selectedGender != null) {
      final selectedGender = _selectedGender!.toLowerCase();
      plans = plans.where((p) {
        final gender = p.genderTarget.toLowerCase();
        if (gender == selectedGender) {
          return true;
        }
        return gender == 'all';
      }).toList();
    }

    return plans;
  }

  List<String> get _categoryFilterOptions =>
      ['Hypertrophy', 'Strength', 'Fat Loss'];

  List<String> get _levelFilterOptions =>
      ['Beginner', 'Intermediate', 'Advance'];

  List<String> get _equipmentFilterOptions => ['Home', 'Gym'];

  List<int> get _daysFilterOptions => [2, 3, 4, 5, 6];

  List<String> get _genderFilterOptions => ['male', 'female'];

  Future<void> _openFilterBottomSheet(BuildContext context) async {
    final result = await plan_filter.showFilterBottomSheet(
      context,
      initialValue: plan_filter.PlanFilterResult(
        category: _selectedCategory,
        equipment: _selectedEquipment,
        level: _selectedLevel,
        daysPerWeek: _selectedDaysPerWeek,
        gender: _selectedGender,
      ),
      categoryOptions: _categoryFilterOptions,
      equipmentOptions: _equipmentFilterOptions,
      levelOptions: _levelFilterOptions,
      dayOptions: _daysFilterOptions,
      genderOptions: _genderFilterOptions,
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedCategory = result.category;
      _selectedEquipment = result.equipment;
      _selectedLevel = result.level;
      _selectedDaysPerWeek = result.daysPerWeek;
      _selectedGender = result.gender;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Bar ──
            _buildSearchBar(),
            const SizedBox(height: 10),

            // ── Grid ──
            Expanded(
              child: FutureBuilder<List<WorkoutPlanModel>>(
                future: _plansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load plans',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  }

                  final plans = _filteredPlans;
                  if (plans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No plans found'
                                : 'No system plans yet',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 6,
                      mainAxisExtent: 290,
                    ),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final cardColor =
                          _kCardColors[index % _kCardColors.length];
                      return _PlanCard(plan: plan, fallbackColor: cardColor);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AppBar
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(
        'Daily Plans',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FavoriteSystemPlansScreen(),
              ),
            );
          },
          icon: const Icon(Icons.star_border, color: Colors.white, size: 22),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => _openFilterBottomSheet(context),
            icon: const Icon(Icons.filter_alt_outlined,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Search Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return SearchBar(
      controller: _searchController,
      backgroundColor: WidgetStateProperty.all(_kSearchBg),
      elevation: WidgetStateProperty.all(0),
      hintText: 'Search for plans',
      hintStyle: WidgetStateProperty.all(
        GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        GoogleFonts.inter(fontSize: 14, color: Colors.white),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16),
      ),
      leading: Icon(
        Icons.search,
        color: Colors.white.withValues(alpha: 0.4),
        size: 20,
      ),
      trailing: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, size: 20, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
      ],
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.fallbackColor});

  final WorkoutPlanModel plan;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final uniqueEquipments = plan.routines
        .expand((routine) => routine.exercises)
        .map((entry) => entry.exerciseName.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlanDetailScreen(plan: plan),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: fallbackColor,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: plan.imageUrl.isNotEmpty
                ? Image.network(
                    plan.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 50,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 50,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
          ),
          const SizedBox(height: 4),

          // Plan Title
          Text(
            plan.name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Meta chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DarkMetaChip(text: '${plan.totalWeeks} weeks'),
                const SizedBox(width: 4),
                _DarkMetaChip(text: '${plan.sessionsPerWeek} workouts/week'),
                const SizedBox(width: 4),
                _DarkMetaChip(text: '$uniqueEquipments equipment'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold-on-olive chip matching the dashboard design.
class _DarkMetaChip extends StatelessWidget {
  const _DarkMetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFFF4CB43),
          fontSize: 9,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
