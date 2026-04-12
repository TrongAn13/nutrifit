import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/Screens/library/exercise_detail_screen.dart';
import '../../../../../shared/widgets/static_gif_thumbnail.dart';
import '../../data/models/exercise_model.dart';
import '../../logic/exercise_library_bloc.dart';
import '../../logic/exercise_library_event.dart';
import '../../logic/exercise_library_state.dart';

const Color _kBg = Color(0xFF060708);
const Color _kSearchBg = Color(0xFF1B1D22);
const Color _kBackBtnBg = Colors.white10;
const Color _kAccent = Color(0xFFD7FF1F);
const Color _kCardBg = Color(0xFF1B1D22);

/// Exercise selection screen with discovery list, selected preview bar,
/// and bottom action button.
class SelectExerciseScreen extends StatefulWidget {
  const SelectExerciseScreen({super.key});

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<ExerciseModel> _selectedExercises = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExerciseSelection(ExerciseModel exercise) {
    final selectedIndex = _selectedExercises.indexWhere(
      (e) => e.exerciseId == exercise.exerciseId,
    );
    setState(() {
      if (selectedIndex >= 0) {
        _selectedExercises.removeAt(selectedIndex);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  List<ExerciseModel> _filterExercises(List<ExerciseModel> exercises) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return exercises;
    }

    return exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(query) ||
          exercise.primaryMuscle.toLowerCase().contains(query) ||
          exercise.equipment.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_selectedExercises);
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_selectedExercises),
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
          title: Text(
            'Select Exercises',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.star_border,
                color: Colors.white,
                size: 22,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.filter_alt_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _kSearchBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white54,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
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
            const SizedBox(height: 12),
            if (_selectedExercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 72,
                  child: ListView.builder(
                    clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    itemCount: _selectedExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _selectedExercises[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white10,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: exercise.gifUrl.isNotEmpty
                                  ? StaticGifThumbnail(url: exercise.gifUrl, size: 56)
                                  : exercise.imageUrl.isNotEmpty
                                      ? (exercise.imageUrl.startsWith('assets/')
                                          ? Image.asset(
                                              exercise.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.fitness_center_rounded,
                                                size: 24,
                                                color: _kAccent,
                                              ),
                                            )
                                          : Image.network(
                                              exercise.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.fitness_center_rounded,
                                                size: 24,
                                                color: _kAccent,
                                              ),
                                            ))
                                      : const Icon(
                                          Icons.fitness_center_rounded,
                                          size: 24,
                                          color: _kAccent,
                                        ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _toggleExerciseSelection(exercise),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.redAccent,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_selectedExercises.isNotEmpty) const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<ExerciseLibraryBloc, ExerciseLibraryState>(
                builder: (context, state) {
                  if (state is ExerciseLibraryLoading ||
                      state is ExerciseLibraryInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ExerciseLibraryError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<ExerciseLibraryBloc>()
                          .add(const ExerciseLibraryLoadRequested()),
                    );
                  }

                  final allExercises =
                      (state as ExerciseLibraryLoaded).exercises;
                  final displayList = _filterExercises(allExercises);

                  if (displayList.isEmpty) {
                    return Center(
                      child: Text(
                        'Không tìm thấy bài tập nào',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: displayList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exercise = displayList[index];
                      final isSelected = _selectedExercises.any(
                        (e) => e.exerciseId == exercise.exerciseId,
                      );
                      return _ExerciseSelectCard(
                        exercise: exercise,
                        isSelected: isSelected,
                        onTap: () => _toggleExerciseSelection(exercise),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedExercises.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_selectedExercises),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          _kAccent.withAlpha(80),
                      disabledForegroundColor: Colors.black38,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Add ${_selectedExercises.length} Exercises',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSelectCard extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExerciseSelectCard({
    required this.exercise,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [exercise.primaryMuscle, exercise.equipment]
        .where((s) => s.isNotEmpty)
        .join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
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
                color: Colors.white10,
              ),
              clipBehavior: Clip.antiAlias,
              child: exercise.gifUrl.isNotEmpty
                  ? StaticGifThumbnail(url: exercise.gifUrl, size: 60)
                  : exercise.imageUrl.isNotEmpty
                      ? (exercise.imageUrl.startsWith('assets/')
                          ? Image.asset(
                              exercise.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fitness_center_rounded,
                                color: _kAccent,
                                size: 28,
                              ),
                            )
                          : Image.network(
                              exercise.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fitness_center_rounded,
                                color: _kAccent,
                                size: 28,
                              ),
                            ))
                      : const Icon(
                          Icons.fitness_center_rounded,
                          color: _kAccent,
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
                    subtitle.isEmpty ? 'Chưa có thông tin' : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailScreen(
                      exercise: exercise,
                      groupName: exercise.primaryMuscle.isNotEmpty
                          ? exercise.primaryMuscle
                          : 'Exercise',
                    ),
                  ),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    'i',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Error View
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.black),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

