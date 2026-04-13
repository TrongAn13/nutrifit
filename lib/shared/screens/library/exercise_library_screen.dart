import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'favorite_exercise_screen.dart';
import 'muscle_group_screen.dart';

const Color _kBg = Color(0xFF060708);
const Color _kSearchBg = Color(0xFF1B1D22);
const Color _kBackBtnBg = Color(0xFF1B1D22);
const List<Color> _kCardColors = [
  Color(0xFF2A2D35),
  Color(0xFF1E2428),
  Color(0xFF2D2A22),
  Color(0xFF2A1E28),
  Color(0xFF1E2D2A),
  Color(0xFF282A2D),
];

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRegion;

  static const List<_MuscleGroupData> _groups = [
    _MuscleGroupData(name: 'CHEST', imageUrl: 'assets/images/chest.webp', region: 'Upper'),
    _MuscleGroupData(name: 'BACK', imageUrl: 'assets/images/back.jfif', region: 'Upper'),
    _MuscleGroupData(name: 'SHOULDERS', imageUrl: 'assets/images/shoulder.jfif', region: 'Upper'),
    _MuscleGroupData(name: 'LEGS', imageUrl: 'assets/images/leg.jfif', region: 'Lower'),
    _MuscleGroupData(name: 'ARMS', imageUrl: 'assets/images/arm.jfif', region: 'Upper'),
    _MuscleGroupData(name: 'ABS', imageUrl: 'assets/images/abs.jpg', region: 'Core'),
    _MuscleGroupData(name: 'CARDIO', imageUrl: 'assets/images/cardio.jfif', region: 'Cardio'),
    _MuscleGroupData(name: 'STRETCHING', imageUrl: 'assets/images/stretching.jfif', region: 'Mobility'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _regions {
    final values = _groups.map((e) => e.region).toSet().toList();
    values.sort();
    return values;
  }

  List<_MuscleGroupData> get _filteredGroups {
    var list = _groups;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((g) => g.name.toLowerCase().contains(q)).toList();
    }

    if (_selectedRegion != null) {
      list = list.where((g) => g.region == _selectedRegion).toList();
    }

    return list;
  }

  Future<void> _openFilterSheet() async {
    String? tempRegion = _selectedRegion;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E8EB),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bo loc nhom co',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._regions.map(
                        (region) => ChoiceChip(
                          label: Text(region),
                          selected: tempRegion == region,
                          onSelected: (_) {
                            setSheetState(() {
                              tempRegion = region;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedRegion = null;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Mac dinh'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedRegion = tempRegion;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Ap dung'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Text(
              'Discovery',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 13),
            _buildGrid(context),
          ],
        ),
      ),
    );
  }

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
        'Exercises',
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
                builder: (_) => const FavoriteExerciseScreen(),
              ),
            );
          },
          icon: const Icon(Icons.star_border, color: Colors.white, size: 22),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(
              Icons.filter_alt_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SearchBar(
      controller: _searchController,
      backgroundColor: WidgetStateProperty.all(_kBackBtnBg),
      elevation: WidgetStateProperty.all(0),
      hintText: 'Search',
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

  Widget _buildGrid(BuildContext context) {
    final groups = _filteredGroups;
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'Khong co nhom co phu hop',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 6,
        mainAxisExtent: 240,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(context, groups[index]);
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, _MuscleGroupData group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MuscleGroupScreen(groupName: group.name),
          ),
        );
      },
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade300,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              group.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade900,
                child: Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54,
                  ],
                  stops: [0.0, 0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: Text(
                group.name,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleGroupData {
  final String name;
  final String imageUrl;
  final String region;

  const _MuscleGroupData({
    required this.name,
    required this.imageUrl,
    required this.region,
  });
}
