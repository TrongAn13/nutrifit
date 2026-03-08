import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/exercise_model.dart';
import '../../logic/exercise_library_bloc.dart';
import '../../logic/exercise_library_event.dart';
import '../../logic/exercise_library_state.dart';
import 'exercise_detail_screen.dart';

/// Split-view exercise search screen with 3 tabs:
/// Recent, Popular (category sidebar), and Favorites.
///
/// When [isSelectionMode] is true, tapping an exercise adds it to a
/// multi-select list. Pressing Back returns the full [List<ExerciseModel>].
class ExerciseLibraryScreen extends StatefulWidget {
  final bool isSelectionMode;

  const ExerciseLibraryScreen({super.key, this.isSelectionMode = false});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Accumulated exercises when in selection mode.
  final List<ExerciseModel> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Adds an exercise to the multi-select list.
  void _onExerciseSelected(ExerciseModel exercise) {
    setState(() => _selectedExercises.add(exercise));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm "${exercise.name}" (${_selectedExercises.length} bài)',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = DateFormat('dd/MM').format(DateTime.now());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Return the accumulated list (empty list if none selected)
          Navigator.of(context).pop(
            widget.isSelectionMode ? _selectedExercises : null,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(
              widget.isSelectionMode ? _selectedExercises : null,
            ),
          ),
          title: widget.isSelectionMode
              ? Text(
                  'Chọn bài tập (${_selectedExercises.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hôm nay • $today',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
          centerTitle: true,
          actions: [
            if (widget.isSelectionMode && _selectedExercises.isNotEmpty)
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_selectedExercises),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text('Xong (${_selectedExercises.length})'),
              ),
            if (widget.isSelectionMode) const SizedBox(width: 12),
          ],
        ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm hoạt động...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
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
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // ── Tab Bar ──
          TabBar(
            controller: _tabController,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Gần đây'),
              Tab(text: 'Phổ biến'),
              Tab(text: 'Yêu thích'),
            ],
          ),

          // ── Tab Views ──
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

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Recent
                    _RecentTab(
                      searchQuery: _searchQuery,
                      isSelectionMode: widget.isSelectionMode,
                      onExerciseSelected: _onExerciseSelected,
                    ),

                    // Tab 2: Popular (split-view)
                    _PopularTab(
                      exercises: allExercises,
                      searchQuery: _searchQuery,
                      isSelectionMode: widget.isSelectionMode,
                      onExerciseSelected: _onExerciseSelected,
                    ),

                    // Tab 3: Favorites
                    const _FavoritesTab(),
                  ],
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

// ═══════════════════════════════════════════════════════════════════════════════
// Recent Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentTab extends StatelessWidget {
  final String searchQuery;
  final bool isSelectionMode;
  final ValueChanged<ExerciseModel> onExerciseSelected;

  const _RecentTab({
    required this.searchQuery,
    required this.isSelectionMode,
    required this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Placeholder empty state — real implementation would load from local storage
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa thêm bài tập nào gần đây.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Favorites Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline_rounded,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tính năng đang phát triển.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Popular Tab — Split-view with category sidebar
// ═══════════════════════════════════════════════════════════════════════════════

/// Categories and their visual config.
enum _Category {
  cardio('Cardio', Icons.directions_run_rounded, Colors.orange),
  gym('Gym', Icons.fitness_center_rounded, Colors.blue),
  sports('Thể thao', Icons.sports_soccer_rounded, Colors.green);

  final String label;
  final IconData icon;
  final Color color;

  const _Category(this.label, this.icon, this.color);
}

class _PopularTab extends StatefulWidget {
  final List<ExerciseModel> exercises;
  final String searchQuery;
  final bool isSelectionMode;
  final ValueChanged<ExerciseModel> onExerciseSelected;

  const _PopularTab({
    required this.exercises,
    required this.searchQuery,
    required this.isSelectionMode,
    required this.onExerciseSelected,
  });

  @override
  State<_PopularTab> createState() => _PopularTabState();
}

class _PopularTabState extends State<_PopularTab> {
  _Category _selectedCategory = _Category.gym;

  /// Filters exercises based on the selected category and search query.
  List<ExerciseModel> get _filteredExercises {
    final query = widget.searchQuery.toLowerCase();

    return widget.exercises.where((e) {
      // Category filter
      switch (_selectedCategory) {
        case _Category.cardio:
          if (e.bodyPart.toLowerCase() != 'cardio' &&
              e.equipment.toLowerCase() != 'cardio' &&
              !e.name.toLowerCase().contains('cardio')) {
            return false;
          }
        case _Category.gym:
          // Gym exercises: exclude cardio and sports entries
          final nameLower = e.name.toLowerCase();
          final bodyLower = e.bodyPart.toLowerCase();
          if (bodyLower == 'cardio' || nameLower.contains('cardio')) {
            return false;
          }
        case _Category.sports:
          final nameLower = e.name.toLowerCase();
          if (!nameLower.contains('sport') &&
              !nameLower.contains('thể thao') &&
              e.bodyPart.toLowerCase() != 'thể thao') {
            // For now, show nothing for sports — no matching data
            return false;
          }
      }

      // Search filter
      if (query.isNotEmpty) {
        if (!e.name.toLowerCase().contains(query) &&
            !e.primaryMuscle.toLowerCase().contains(query) &&
            !e.equipment.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredExercises;

    return Row(
      children: [
        // ── Left: Category Sidebar ──
        SizedBox(
          width: 100,
          child: Column(
            children: _Category.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.grey.shade200 : null,
                    border: Border(
                      left: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        cat.icon,
                        size: 24,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.black
                              : Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Vertical divider ──
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Colors.grey.shade200,
        ),

        // ── Right: Exercise List ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy bài tập.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    return _ExerciseItem(
                      exercise: exercise,
                      category: _selectedCategory,
                      isSelectionMode: widget.isSelectionMode,
                      onExerciseSelected: widget.onExerciseSelected,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Exercise Item
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseItem extends StatelessWidget {
  final ExerciseModel exercise;
  final _Category category;
  final bool isSelectionMode;
  final ValueChanged<ExerciseModel> onExerciseSelected;

  const _ExerciseItem({
    required this.exercise,
    required this.category,
    required this.isSelectionMode,
    required this.onExerciseSelected,
  });

  String get _subtitle {
    switch (category) {
      case _Category.cardio:
      case _Category.sports:
        return '~200 Calo • 30 phút';
      case _Category.gym:
        final parts = <String>[];
        if (exercise.primaryMuscle.isNotEmpty) {
          parts.add(exercise.primaryMuscle);
        }
        if (exercise.equipment.isNotEmpty) {
          parts.add(exercise.equipment);
        }
        return parts.isNotEmpty ? parts.join(' • ') : 'Chưa có thông tin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isSelectionMode
          ? () => onExerciseSelected(exercise)
          : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExerciseDetailScreen(exercise: exercise),
                ),
              ),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Leading: Icon placeholder
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Center: Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Trailing: Add button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onPressed: () => onExerciseSelected(exercise),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
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
