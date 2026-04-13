import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/trainee/workout/data/models/workout_plan_model.dart';
import '../../../features/trainee/workout/data/repositories/workout_repository.dart';
import 'system_plan_detail_screen.dart';
import 'widgets/plan_filter_bottom_sheet.dart' as plan_filter;

const Color _kBg = Color(0xFFFAFAFA);
const Color _kBackBtnBg = Color(0xFFF7F8F8);
const Color _kSearchBg = Color(0xFFF7F8F8);

const List<Color> _kCardColors = [
  Color(0xFFE8EDFF),
  Color(0xFFE8F5E9),
  Color(0xFFFFF3E0),
  Color(0xFFFCE4EC),
  Color(0xFFE0F7FA),
  Color(0xFFF3E5F5),
];

class FavoriteSystemPlansScreen extends StatefulWidget {
  const FavoriteSystemPlansScreen({super.key});

  @override
  State<FavoriteSystemPlansScreen> createState() =>
      _FavoriteSystemPlansScreenState();
}

class _FavoriteSystemPlansScreenState extends State<FavoriteSystemPlansScreen> {
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<WorkoutPlanModel>> _plansFuture;
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

  Future<List<WorkoutPlanModel>> _fetchPlans() async {
    try {
      _allPlans = await _workoutRepository.getFavoriteSystemPlans();
      return _allPlans;
    } catch (e) {
      debugPrint('Error fetching favorite system plans: $e');
      return [];
    }
  }

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
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kBackBtnBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
        title: Text(
          'Favorite Plans',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _openFilterBottomSheet(context),
              icon: const Icon(
                Icons.filter_alt_outlined,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _kSearchBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search for plans...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 12),
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
                        'Không thể tải giáo án yêu thích',
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
                      child: Text(
                        'Chưa có giáo án yêu thích',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 320,
                    ),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final cardColor = _kCardColors[index % _kCardColors.length];
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
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.fallbackColor});

  final WorkoutPlanModel plan;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${plan.totalWeeks} weeks • ${plan.sessionsPerWeek} workouts/week • ${plan.level}';

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
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: fallbackColor,
              borderRadius: BorderRadius.circular(20),
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
                        color: Colors.black.withAlpha(30),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 50,
                      color: Colors.black.withAlpha(30),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
