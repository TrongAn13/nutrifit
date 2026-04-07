import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/trainee/workout/data/models/exercise_model.dart';
import 'exercise_detail_screen.dart';
import 'exercise_favorite_store.dart';

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

class MuscleGroupScreen extends StatefulWidget {
  final String groupName;
  final bool showAllExercises;
  final bool favoritesOnly;
  final String? screenTitle;

  const MuscleGroupScreen({
    super.key,
    required this.groupName,
    this.showAllExercises = false,
    this.favoritesOnly = false,
    this.screenTitle,
  });

  @override
  State<MuscleGroupScreen> createState() => _MuscleGroupScreenState();
}

class _MuscleGroupScreenState extends State<MuscleGroupScreen> {
  late Future<List<ExerciseModel>> _exercisesFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  List<ExerciseModel> _allExercises = [];
  String? _selectedEquipment;
  String? _selectedLevel;
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _favoritesOnly = widget.favoritesOnly;
    _exercisesFuture = _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ExerciseModel>> _fetchExercises() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('exercises').get();

    final all = snapshot.docs.map((d) {
      final data = d.data();
      data['exerciseId'] = d.id;
      return ExerciseModel.fromJson(data);
    }).toList();

    if (widget.showAllExercises) {
      _allExercises = all;
      return _allExercises;
    }

    final gnLow = widget.groupName.toLowerCase();
    _allExercises = all.where((e) {
      if (e.category.isNotEmpty && e.category.toLowerCase() == gnLow) {
        return true;
      }
      return e.primaryMuscle.toLowerCase() == gnLow ||
          e.bodyPart.toLowerCase() == gnLow;
    }).toList();

    return _allExercises;
  }

  List<String> get _equipmentOptions {
    return _allExercises
        .map((e) => e.equipment.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _levelOptions {
    return _allExercises
        .map((e) => e.level.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<ExerciseModel> get _filteredExercises {
    var list = _allExercises;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((ex) {
        return ex.name.toLowerCase().contains(q) ||
            ex.equipment.toLowerCase().contains(q);
      }).toList();
    }

    if (_selectedEquipment != null) {
      list = list
          .where((ex) => ex.equipment.toLowerCase() == _selectedEquipment)
          .toList();
    }

    if (_selectedLevel != null) {
      list =
          list.where((ex) => ex.level.toLowerCase() == _selectedLevel).toList();
    }

    if (_favoritesOnly) {
      list = list
          .where((ex) => ExerciseFavoriteStore.isFavorite(ex.exerciseId))
          .toList();
    }

    return list;
  }

  Future<void> _openFilterSheet() async {
    String? tempEquipment = _selectedEquipment;
    String? tempLevel = _selectedLevel;

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
                    'Bo loc bai tap',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterSection(
                    title: 'Dung cu',
                    options: _equipmentOptions,
                    selected: tempEquipment,
                    onSelected: (value) {
                      setSheetState(() {
                        tempEquipment = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFilterSection(
                    title: 'Do kho',
                    options: _levelOptions,
                    selected: tempLevel,
                    onSelected: (value) {
                      setSheetState(() {
                        tempLevel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedEquipment = null;
                              _selectedLevel = null;
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
                              _selectedEquipment = tempEquipment;
                              _selectedLevel = tempLevel;
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

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...options.map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Discovery',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ExerciseModel>>(
              future: _exercisesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Co loi xay ra',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ValueListenableBuilder<Set<String>>(
                  valueListenable: ExerciseFavoriteStore.favorites,
                  builder: (context, favorites, child) {
                    final displayList = _filteredExercises;

                    if (displayList.isEmpty) {
                      return Center(
                        child: Text(
                          'Khong tim thay bai tap nao',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: displayList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ex = displayList[index];
                        return _ExerciseCard(
                          exercise: ex,
                          groupName: widget.groupName,
                          onToggleFavorite: () {
                            ExerciseFavoriteStore.toggle(ex.exerciseId);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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
        widget.screenTitle ??
            (widget.showAllExercises ? 'Exercises' : widget.groupName),
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (_favoritesOnly) {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MuscleGroupScreen(
                  groupName: 'Favorite Exercises',
                  showAllExercises: true,
                  favoritesOnly: true,
                  screenTitle: 'Favorite Exercises',
                ),
              ),
            );
          },
          icon: Icon(
            _favoritesOnly ? Icons.star : Icons.star_border,
            color: _favoritesOnly ? const Color(0xFFF6B100) : Colors.white,
            size: 22,
          ),
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
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.groupName,
    required this.onToggleFavorite,
  });

  final ExerciseModel exercise;
  final String groupName;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final subtitle = [exercise.primaryMuscle, exercise.equipment]
        .where((s) => s.isNotEmpty)
        .join(' • ');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(
              exercise: exercise,
              groupName: groupName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kSearchBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withAlpha(8),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.withAlpha(25),
              ),
              clipBehavior: Clip.antiAlias,
              child: exercise.imageUrl.isNotEmpty
                  ? Image.asset(
                      exercise.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.blue,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.blue,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty ? 'Chua co thong tin' : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Color(0xFFF4CB43),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<Set<String>>(
              valueListenable: ExerciseFavoriteStore.favorites,
              builder: (context, favorites, _) {
                final isFavorite = favorites.contains(exercise.exerciseId);
                return IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color:
                        isFavorite ? const Color(0xFFF6B100) : Colors.grey.shade500,
                    size: 22,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
