import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/exercise_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/workout_plan_model.dart';
import '../../logic/plan_detail_cubit.dart';

const Map<int, String> _dayLabelsMap = {
	1: 'Thứ 2',
	2: 'Thứ 3',
	3: 'Thứ 4',
	4: 'Thứ 5',
	5: 'Thứ 6',
	6: 'Thứ 7',
	7: 'Chủ nhật',
};

class EditPlanScreen extends StatefulWidget {
	const EditPlanScreen({super.key});

	@override
	State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen>
		with SingleTickerProviderStateMixin {
	final _nameController = TextEditingController();
	final _descController = TextEditingController();

	late final TabController _tabController;

	bool _initialized = false;
	int _totalWeeks = 4;
	List<int> _trainingDays = [1, 3, 5];
	String _bannerUrl = '';

	@override
	void initState() {
		super.initState();
		_tabController = TabController(length: 2, vsync: this);
	}

	@override
	void dispose() {
		_nameController.dispose();
		_descController.dispose();
		_tabController.dispose();
		super.dispose();
	}

	void _syncFromState(PlanDetailState state) {
		if (_initialized) return;
		final plan = state.plan;
		_nameController.text = plan.name;
		_descController.text = plan.description;
		_totalWeeks = plan.totalWeeks;
		_trainingDays = List<int>.from(plan.trainingDays)..sort();
		_bannerUrl = plan.imageUrl;
		_initialized = true;
	}

	void _toggleDay(int day) {
		setState(() {
			if (_trainingDays.contains(day)) {
				if (_trainingDays.length > 1) {
					_trainingDays = List<int>.from(_trainingDays)..remove(day);
				}
			} else {
				_trainingDays = List<int>.from(_trainingDays)..add(day);
			}
			_trainingDays.sort();
		});
	}

	Future<void> _showBannerDialog() async {
		final controller = TextEditingController(text: _bannerUrl);
		await showDialog<void>(
			context: context,
			builder: (dialogCtx) {
				return AlertDialog(
					title: const Text('Cập nhật ảnh banner'),
					content: TextField(
						controller: controller,
						autofocus: true,
						decoration: const InputDecoration(
							labelText: 'Link ảnh',
							hintText: 'https://example.com/banner.jpg',
						),
					),
					actions: [
						if (_bannerUrl.isNotEmpty)
							TextButton(
								onPressed: () {
									setState(() => _bannerUrl = '');
									Navigator.pop(dialogCtx);
								},
								child: const Text('Xóa ảnh'),
							),
						TextButton(
							onPressed: () => Navigator.pop(dialogCtx),
							child: const Text('Hủy'),
						),
						FilledButton(
							onPressed: () {
								setState(() => _bannerUrl = controller.text.trim());
								Navigator.pop(dialogCtx);
							},
							child: const Text('Lưu'),
						),
					],
				);
			},
		);
	}

	Widget _buildPlanBannerPreview(String imagePath) {
		if (imagePath.isEmpty) {
			return Image.asset(
				'assets/images/default_plan.jpg',
				fit: BoxFit.cover,
			);
		}

		if (imagePath.startsWith('assets/')) {
			return Image.asset(
				imagePath,
				fit: BoxFit.cover,
			);
		}

		return Image.asset(
			imagePath,
			fit: BoxFit.cover,
			errorBuilder: (context, error, stackTrace) {
				return Image.asset(
					'assets/images/default_plan.jpg',
					fit: BoxFit.cover,
				);
			},
		);
	}

	Future<void> _savePlan() async {
		final name = _nameController.text.trim();
		if (name.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Vui lòng nhập tên giáo án')),
			);
			_tabController.animateTo(0);
			return;
		}

		context.read<PlanDetailCubit>().updatePlanBasics(
			name: name,
			description: _descController.text.trim(),
			totalWeeks: _totalWeeks,
			trainingDays: _trainingDays,
			imageUrl: _bannerUrl,
		);
		await context.read<PlanDetailCubit>().savePlan();
	}

	Future<void> _addExercisesToCurrentRoutine() async {
		final result = await context.push<List<ExerciseModel>>(
			'/exercise-library?mode=selection',
		);
		if (result == null || result.isEmpty || !mounted) return;

		final cubit = context.read<PlanDetailCubit>();
		for (final selected in result) {
			cubit.addExercise(
				ExerciseEntry(
					exerciseName: selected.name,
					primaryMuscle: selected.primaryMuscle,
					sets: 3,
					reps: 10,
					restTime: 60,
				),
			);
		}

		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Đã thêm ${result.length} bài tập')),
		);
	}

	void _showRenameDialog(BuildContext context, RoutineModel? routine) {
		if (routine == null) return;
		final controller = TextEditingController(text: routine.name);

		showDialog<void>(
			context: context,
			builder: (dialogCtx) => AlertDialog(
				title: const Text('Đổi tên buổi tập'),
				content: TextField(
					controller: controller,
					autofocus: true,
					decoration: const InputDecoration(
						labelText: 'Tên mới',
						hintText: 'VD: Ngực - Tay sau',
					),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(dialogCtx),
						child: const Text('Hủy'),
					),
					FilledButton(
						onPressed: () {
							final name = controller.text.trim();
							if (name.isNotEmpty) {
								context.read<PlanDetailCubit>().renameCurrentRoutine(name);
							}
							Navigator.pop(dialogCtx);
						},
						child: const Text('Lưu'),
					),
				],
			),
		);
	}

	void _showCopyDialog(
		BuildContext context,
		int totalRoutines,
		int currentIdx,
	) {
		final controller = TextEditingController();

		showDialog<void>(
			context: context,
			builder: (dialogCtx) => AlertDialog(
				title: const Text('Copy qua ngày'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							'Sao chép toàn bộ bài tập của buổi hiện tại sang buổi khác.',
							style: GoogleFonts.inter(
								fontSize: 14,
								color: Theme.of(dialogCtx)
										.colorScheme
										.onSurface
										.withValues(alpha: 0.6),
							),
						),
						const SizedBox(height: 16),
						TextField(
							controller: controller,
							keyboardType: TextInputType.text,
							autofocus: true,
							decoration: InputDecoration(
								labelText: 'Các buổi số',
								hintText: 'VD: 3, 4, 5',
								helperText:
									'Nhập số từ 1 đến $totalRoutines, cách nhau bởi dấu phẩy',
							),
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(dialogCtx),
						child: const Text('Hủy'),
					),
					FilledButton(
						onPressed: () {
							final text = controller.text.trim();
							if (text.isEmpty) return;

							final targets = text
								.split(',')
								.map((e) => int.tryParse(e.trim()))
								.where((e) => e != null && e >= 1 && e <= totalRoutines)
								.map((e) => e!)
								.toSet()
								.toList();

							if (targets.isNotEmpty) {
								for (final target in targets) {
									if (target - 1 != currentIdx) {
										context
											.read<PlanDetailCubit>()
											.copyToRoutine(target - 1);
									}
								}
								Navigator.pop(dialogCtx);
								ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(
										content: Text(
											'Đã sao chép sang các Buổi: ${targets.join(', ')}',
										),
									),
								);
							}
						},
						child: const Text('Sao chép'),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<PlanDetailCubit, PlanDetailState>(
			listener: (context, state) {
				if (state.savedSuccessfully) {
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(content: Text('Đã lưu giáo án thành công!')),
					);
					context.pop(true);
				}
				if (state.errorMessage != null) {
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text(state.errorMessage!)),
					);
				}
			},
			builder: (context, state) {
				_syncFromState(state);

				return Scaffold(
					backgroundColor: Colors.white,
					appBar: AppBar(
						backgroundColor: Colors.white,
						elevation: 0,
						scrolledUnderElevation: 0,
						centerTitle: true,
						leading: IconButton(
							onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
						),
						title: Text(
							'Edit plan',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
						),
						bottom: PreferredSize(
							preferredSize: const Size.fromHeight(52),
							child: Container(
								margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
								decoration: BoxDecoration(
									color: const Color(0xFFF4F5F5),
									borderRadius: BorderRadius.circular(14),
								),
								child: TabBar(
									controller: _tabController,
									dividerColor: Colors.transparent,
									indicatorSize: TabBarIndicatorSize.tab,
									indicator: BoxDecoration(
										color: const Color(0xFF92A3FD),
										borderRadius: BorderRadius.circular(12),
									),
									labelStyle: GoogleFonts.inter(
										fontSize: 13,
										fontWeight: FontWeight.w700,
									),
									unselectedLabelStyle: GoogleFonts.inter(
										fontSize: 13,
										fontWeight: FontWeight.w600,
									),
									labelColor: Colors.white,
									unselectedLabelColor: Colors.black54,
									tabs: const [
										Tab(text: 'Thông tin'),
										Tab(text: 'Bài tập'),
									],
								),
							),
						),
					),
					bottomNavigationBar: SafeArea(
						child: Padding(
							padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
							child: FilledButton(
								onPressed: state.isSaving ? null : _savePlan,
								style: FilledButton.styleFrom(
									backgroundColor: const Color(0xFF92A3FD),
									foregroundColor: Colors.white,
									minimumSize: const Size.fromHeight(56),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(28),
									),
									elevation: 0,
								),
								child: state.isSaving
										? const SizedBox(
												width: 22,
												height: 22,
												child: CircularProgressIndicator(
													strokeWidth: 2.5,
													color: Colors.white,
												),
											)
										: Text(
												'Lưu',
												style: GoogleFonts.inter(
													fontSize: 18,
													fontWeight: FontWeight.w700,
												),
											),
							),
						),
					),
					body: TabBarView(
						controller: _tabController,
						children: [
							_buildInfoTab(),
							_buildExerciseTab(state),
						],
					),
				);
			},
		);
	}

	Widget _buildInfoTab() {
		const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

		return SingleChildScrollView(
			padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Plan Picture',
						style: GoogleFonts.inter(
							fontSize: 16,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(height: 10),
					GestureDetector(
						onTap: _showBannerDialog,
						child: Container(
							height: 170,
							width: double.infinity,
							decoration: BoxDecoration(
								color: const Color(0xFFF6F7FB),
								borderRadius: BorderRadius.circular(16),
							),
							clipBehavior: Clip.antiAlias,
							child: _buildPlanBannerPreview(_bannerUrl),
						),
					),
					const SizedBox(height: 10),
          Text(
            'Plan Name',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
					TextFormField(
						controller: _nameController,
						style: GoogleFonts.inter(fontSize: 14),
						decoration: InputDecoration(
							hintText: 'Tên giáo án',
							hintStyle: GoogleFonts.inter(
								color: Colors.grey.shade500,
								fontSize: 14,
							),
							prefixIcon: Icon(
								Icons.fitness_center_rounded,
								color: Colors.grey.shade400,
								size: 20,
							),
							filled: true,
							fillColor: const Color(0xFFF7F8F8),
							contentPadding: const EdgeInsets.symmetric(
								horizontal: 20,
								vertical: 18,
							),
							border: OutlineInputBorder(
								borderRadius: BorderRadius.circular(16),
								borderSide: BorderSide.none,
							),
						),
					),
					const SizedBox(height: 14),
          Text(
            'Description',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
					TextFormField(
						controller: _descController,
						style: GoogleFonts.inter(fontSize: 14),
						maxLines: 4,
						decoration: InputDecoration(
							hintText: 'Mô tả',
							hintStyle: GoogleFonts.inter(
								color: Colors.grey.shade500,
								fontSize: 14,
							),
							filled: true,
							fillColor: const Color(0xFFF7F8F8),
							contentPadding: const EdgeInsets.symmetric(
								horizontal: 20,
								vertical: 16,
							),
							border: OutlineInputBorder(
								borderRadius: BorderRadius.circular(16),
								borderSide: BorderSide.none,
							),
						),
					),
					const SizedBox(height: 10),
          Text(
            'Duration',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
						decoration: BoxDecoration(
							color: const Color(0xFFF7F8F8),
							borderRadius: BorderRadius.circular(16),
						),
						child: Row(
							children: [
								Expanded(
									child: Text(
										'Số tuần: $_totalWeeks',
										style: GoogleFonts.inter(
											fontSize: 14,
											color: Colors.grey.shade700,
										),
									),
								),
								IconButton(
									onPressed: _totalWeeks > 1
											? () => setState(() => _totalWeeks--)
											: null,
									icon: const Icon(Icons.remove_rounded),
								),
								IconButton(
									onPressed: _totalWeeks < 52
											? () => setState(() => _totalWeeks++)
											: null,
									icon: const Icon(Icons.add_rounded),
								),
							],
						),
					),
					const SizedBox(height: 16),
          Text(
            'Days of a week',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
						decoration: BoxDecoration(
							color: const Color(0xFFF7F8F8),
							borderRadius: BorderRadius.circular(16),
						),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: List.generate(7, (i) {
								final dayValue = i + 1;
								final isSelected = _trainingDays.contains(dayValue);
								return GestureDetector(
									onTap: () => _toggleDay(dayValue),
									child: AnimatedContainer(
										duration: const Duration(milliseconds: 180),
										width: 38,
										height: 38,
										alignment: Alignment.center,
										decoration: BoxDecoration(
											shape: BoxShape.circle,
											color: isSelected
													? const Color(0xFF92A3FD)
													: Colors.white,
										),
										child: Text(
											dayLabels[i],
											style: GoogleFonts.inter(
												color: isSelected ? Colors.white : Colors.grey.shade600,
												fontWeight: FontWeight.w700,
												fontSize: 12,
											),
										),
									),
								);
							}),
						),
					),
				],
			),
		);
	}

	Widget _buildExerciseTab(PlanDetailState state) {
		final plan = state.plan;
		final routine = state.currentRoutine;

		return ListView(
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
			children: [
				_ActiveRoutineCard(
					routine: routine,
					onRename: () => _showRenameDialog(context, routine),
					onCopy: () => _showCopyDialog(
						context,
						plan.routines.length,
						state.currentRoutineIndex,
					),
				),
				const SizedBox(height: 12),
				Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Expanded(
							flex: 2,
							child: _NotesSection(),
						),
						const SizedBox(width: 12),
						Expanded(
							flex: 1,
							child: _AddExerciseButton(
								onPressed: _addExercisesToCurrentRoutine,
							),
						),
					],
				),
				const SizedBox(height: 12),
				_ExerciseList(
					exercises: routine?.exercises ?? [],
					onRemove: (i) => context.read<PlanDetailCubit>().removeExercise(i),
					onAddTap: _addExercisesToCurrentRoutine,
				),
				const SizedBox(height: 16),
				_PlanStructure(
					plan: plan,
					currentIndex: state.currentRoutineIndex,
					onRoutineSelected: (i) =>
						context.read<PlanDetailCubit>().selectRoutine(i),
				),
				const SizedBox(height: 24),
			],
		);
	}
}

class _ActiveRoutineCard extends StatelessWidget {
	final RoutineModel? routine;
	final VoidCallback onRename;
	final VoidCallback onCopy;

	const _ActiveRoutineCard({
		required this.routine,
		required this.onRename,
		required this.onCopy,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.04),
						blurRadius: 8,
						offset: const Offset(0, 2),
					),
				],
			),
			child: Row(
				children: [
					Expanded(
						child: Row(
							children: [
								Container(
									width: 40,
									height: 40,
									decoration: BoxDecoration(
										color: const Color(0xFFFDECE8),
										borderRadius: BorderRadius.circular(10),
									),
									child: const Icon(
										Icons.calendar_today_rounded,
										color: Color(0xFF92A3FD),
										size: 18,
									),
								),
								const SizedBox(width: 10),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												routine?.name ?? 'Buổi tập',
												style: GoogleFonts.inter(
													fontSize: 14,
													fontWeight: FontWeight.bold,
													color: const Color(0xFF1A1C29),
												),
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
											),
											const SizedBox(height: 2),
											Text(
												'${routine?.exercises.length ?? 0} động tác',
												style: GoogleFonts.inter(
													fontSize: 13,
													color: Colors.grey.shade600,
												),
											),
										],
									),
								),
							],
						),
					),
					Column(
						crossAxisAlignment: CrossAxisAlignment.end,
						mainAxisSize: MainAxisSize.min,
						children: [
							_CompactActionButton(
								icon: Icons.edit_outlined,
								label: 'Đổi tên',
								onTap: onRename,
							),
							const SizedBox(height: 4),
							_CompactActionButton(
								icon: Icons.copy_rounded,
								label: 'Copy',
								onTap: onCopy,
							),
						],
					),
				],
			),
		);
	}
}

class _CompactActionButton extends StatelessWidget {
	final IconData icon;
	final String label;
	final VoidCallback onTap;

	const _CompactActionButton({
		required this.icon,
		required this.label,
		required this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(6),
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(icon, size: 14, color: Colors.grey.shade700),
						const SizedBox(width: 4),
						Text(
							label,
							style: GoogleFonts.inter(
								fontSize: 12,
								color: Colors.grey.shade700,
								fontWeight: FontWeight.w500,
							),
						),
					],
				),
			),
		);
	}
}

class _NotesSection extends StatelessWidget {
	const _NotesSection();

	@override
	Widget build(BuildContext context) {
		return TextField(
			maxLines: 2,
			style: GoogleFonts.inter(fontSize: 13),
			decoration: InputDecoration(
				hintText: 'Ghi chú',
				hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
				filled: true,
				fillColor: Colors.grey.shade50,
				contentPadding: const EdgeInsets.symmetric(
					horizontal: 12,
					vertical: 10,
				),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(10),
					borderSide: BorderSide(color: Colors.grey.shade200),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(10),
					borderSide: BorderSide(color: Colors.grey.shade200),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(10),
					borderSide: const BorderSide(color: Color(0xFFF03613)),
				),
			),
		);
	}
}

class _AddExerciseButton extends StatelessWidget {
	final VoidCallback onPressed;

	const _AddExerciseButton({required this.onPressed});

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			height: 60,
			child: FilledButton(
				onPressed: onPressed,
				style: FilledButton.styleFrom(
					backgroundColor: const Color(0xFF92A3FD),
					foregroundColor: Colors.white,
					padding: const EdgeInsets.symmetric(horizontal: 4),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(10),
					),
				),
				child: const Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Icon(Icons.add_rounded, size: 20),
						SizedBox(height: 2),
						Text(
							'Thêm bài',
							style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
							maxLines: 1,
							overflow: TextOverflow.ellipsis,
						),
					],
				),
			),
		);
	}
}

class _ExerciseList extends StatelessWidget {
	final List<ExerciseEntry> exercises;
	final ValueChanged<int> onRemove;
	final VoidCallback onAddTap;

	const _ExerciseList({
		required this.exercises,
		required this.onRemove,
		required this.onAddTap,
	});

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final colorScheme = theme.colorScheme;

		if (exercises.isEmpty) {
			return Card(
				child: Padding(
					padding: const EdgeInsets.all(32),
					child: Column(
						children: [
							const SizedBox(height: 12),
							Text(
								'Chưa có bài tập',
								style: GoogleFonts.inter(
									fontSize: 14,
									fontWeight: FontWeight.w600,
									color: colorScheme.onSurface.withValues(alpha: 0.5),
								),
							),
							const SizedBox(height: 4),
							GestureDetector(
								onTap: onAddTap,
								child: Text(
									'Mở thư viện chọn bài tập',
									style: GoogleFonts.inter(
										fontSize: 14,
										color: const Color(0xFF92A3FD),
										fontWeight: FontWeight.w600,
										decoration: TextDecoration.underline,
										decorationColor: const Color(0xFF92A3FD),
									),
								),
							),
						],
					),
				),
			);
		}

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					'Danh sách bài tập',
					style: GoogleFonts.inter(
						fontSize: 14,
						fontWeight: FontWeight.w600,
					),
				),
				const SizedBox(height: 8),
				...exercises.asMap().entries.map((entry) {
					final i = entry.key;
					final ex = entry.value;
					return Card(
						margin: const EdgeInsets.only(bottom: 8),
						child: ListTile(
							leading: CircleAvatar(
								radius: 18,
								backgroundColor: colorScheme.primaryContainer.withValues(
									alpha: 0.5,
								),
								child: Text(
									'${i + 1}',
									style: GoogleFonts.inter(
										fontSize: 14,
										fontWeight: FontWeight.bold,
										color: colorScheme.primary,
									),
								),
							),
							title: Text(
								ex.exerciseName,
								style: GoogleFonts.inter(
									fontSize: 16,
									fontWeight: FontWeight.w500,
								),
							),
							subtitle: Text(
								'${ex.sets} hiệp × ${ex.reps} lần · Nghỉ ${ex.restTime}s',
								style: GoogleFonts.inter(
									fontSize: 12,
									color: colorScheme.onSurface.withValues(alpha: 0.5),
								),
							),
							trailing: IconButton(
								onPressed: () => onRemove(i),
								icon: Icon(
									Icons.close_rounded,
									size: 18,
									color: colorScheme.onSurface.withValues(alpha: 0.4),
								),
								tooltip: 'Xóa bài tập',
							),
						),
					);
				}),
			],
		);
	}
}

class _PlanStructure extends StatefulWidget {
	final WorkoutPlanModel plan;
	final int currentIndex;
	final ValueChanged<int> onRoutineSelected;

	const _PlanStructure({
		required this.plan,
		required this.currentIndex,
		required this.onRoutineSelected,
	});

	@override
	State<_PlanStructure> createState() => _PlanStructureState();
}

class _PlanStructureState extends State<_PlanStructure> {
	late final PageController _pageController;
	late int _currentWeek;

	static const List<String> _dayNames = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

	@override
	void initState() {
		super.initState();
		final routinesPerWeek = widget.plan.trainingDays.isNotEmpty ? widget.plan.trainingDays.length : 1;
		final initialWeekIndex = widget.currentIndex ~/ routinesPerWeek;
		_currentWeek = initialWeekIndex + 1;
		_pageController = PageController(initialPage: initialWeekIndex);
	}

	@override
	void didUpdateWidget(covariant _PlanStructure oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (widget.currentIndex != oldWidget.currentIndex) {
			final routinesPerWeek = widget.plan.trainingDays.isNotEmpty ? widget.plan.trainingDays.length : 1;
			final newWeekIndex = widget.currentIndex ~/ routinesPerWeek;
			if (newWeekIndex + 1 != _currentWeek) {
				setState(() => _currentWeek = newWeekIndex + 1);
				_pageController.animateToPage(
					newWeekIndex,
					duration: const Duration(milliseconds: 300),
					curve: Curves.easeInOut,
				);
			}
		}
	}

	@override
	void dispose() {
		_pageController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final routines = widget.plan.routines;
		final totalWeeks = widget.plan.totalWeeks;
		final routinesPerWeek = widget.plan.trainingDays.isNotEmpty ? widget.plan.trainingDays.length : 1;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						Text(
							'Cấu trúc giáo án',
							style: GoogleFonts.inter(
								fontSize: 18,
								fontWeight: FontWeight.w800,
								color: Colors.black,
							),
						),
						Container(
							padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
							decoration: BoxDecoration(
								color: const Color(0xFFF7F8F8),
								borderRadius: BorderRadius.circular(20),
							),
							child: Row(
								children: [
									GestureDetector(
										onTap: () {
											if (_currentWeek > 1) {
												_pageController.previousPage(
													duration: const Duration(milliseconds: 300),
													curve: Curves.easeInOut,
												);
											}
										},
										child: Icon(
											Icons.chevron_left,
											color: _currentWeek > 1 ? const Color(0xFF92A3FD) : Colors.grey.shade300,
											size: 20,
										),
									),
									const SizedBox(width: 8),
									Text(
										'Week $_currentWeek / $totalWeeks',
										style: GoogleFonts.inter(
											fontSize: 13,
											fontWeight: FontWeight.w600,
											color: Colors.grey.shade700,
										),
									),
									const SizedBox(width: 8),
									GestureDetector(
										onTap: () {
											if (_currentWeek < totalWeeks) {
												_pageController.nextPage(
													duration: const Duration(milliseconds: 300),
													curve: Curves.easeInOut,
												);
											}
										},
										child: Icon(
											Icons.chevron_right,
											color: _currentWeek < totalWeeks ? const Color(0xFF92A3FD) : Colors.grey.shade300,
											size: 20,
										),
									),
								],
							),
						),
					],
				),
				const SizedBox(height: 16),
				SizedBox(
					height: 600,
					child: PageView.builder(
						controller: _pageController,
						itemCount: totalWeeks,
						onPageChanged: (index) {
							setState(() {
								_currentWeek = index + 1;
							});
						},
						itemBuilder: (context, index) {
							final weekNumber = index + 1;
							final weekStart = index * routinesPerWeek;

							return Container(
								margin: const EdgeInsets.only(bottom: 20, left: 0, right: 0),
								padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
								decoration: BoxDecoration(
									color: Colors.white,
									borderRadius: BorderRadius.circular(24),
									boxShadow: [
										BoxShadow(
											color: Colors.black.withValues(alpha: 0.04),
											blurRadius: 15,
											spreadRadius: 1,
											offset: const Offset(0, 4),
										),
									],
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Row(
											children: [
												Transform.rotate(
													angle: pi / 4,
													child: Container(
														width: 32,
														height: 32,
														decoration: BoxDecoration(
															color: const Color(0xFF92A3FD),
															borderRadius: BorderRadius.circular(10),
														),
														child: Transform.rotate(
															angle: -pi / 4,
															child: Center(
																child: Text(
																	'$weekNumber',
																	style: GoogleFonts.inter(
																		fontSize: 14,
																		fontWeight: FontWeight.w800,
																		color: Colors.white,
																	),
																),
															),
														),
													),
												),
												const SizedBox(width: 14),
												Text(
													'Week $weekNumber',
													style: GoogleFonts.inter(
														fontSize: 16,
														fontWeight: FontWeight.w800,
														color: Colors.black,
													),
												),
												const Spacer(),
												Row(
													children: List.generate(7, (dotIndex) {
														final isWorkout = widget.plan.trainingDays.contains(dotIndex + 1);
														return Container(
															margin: const EdgeInsets.only(left: 6),
															width: 6,
															height: 6,
															decoration: BoxDecoration(
																shape: BoxShape.circle,
																color: isWorkout ? const Color(0xFF92A3FD) : Colors.grey.shade300,
															),
														);
													}),
												),
											],
										),
										const SizedBox(height: 24),
										Column(
											children: List.generate(7, (dayIndex) {
												final int realDayIndex = dayIndex + 1;
												final bool hasWorkout = widget.plan.trainingDays.contains(realDayIndex);

												if (!hasWorkout) {
													return const SizedBox.shrink();
												} else {
													final dayPositionInWeek = widget.plan.trainingDays.indexOf(realDayIndex);
													final globalRoutineIndex = weekStart + dayPositionInWeek;
													final isSelected = widget.currentIndex == globalRoutineIndex;

													final routineName = (globalRoutineIndex < routines.length)
															? routines[globalRoutineIndex].name
															: 'Bài tập';

													return Padding(
														padding: const EdgeInsets.only(bottom: 12),
														child: Row(
															crossAxisAlignment: CrossAxisAlignment.center,
															children: [
																SizedBox(
																	width: 30,
																	child: Text(
																		_dayNames[dayIndex],
																		style: GoogleFonts.inter(
																			fontSize: 13,
																			fontWeight: FontWeight.w600,
																			color: Colors.grey.shade600,
																		),
																		textAlign: TextAlign.left,
																	),
																),
																const SizedBox(width: 4),
																Expanded(
																	child: InkWell(
																		onTap: () => widget.onRoutineSelected(globalRoutineIndex),
																		borderRadius: BorderRadius.circular(12),
																		child: _buildWorkoutCard(routineName, isSelected),
																	),
																),
															],
														),
													);
												}
											}),
										),
									],
								),
							);
						},
					),
				),
			],
		);
	}

	Widget _buildWorkoutCard(String title, bool isSelected) {
		return AnimatedContainer(
			duration: const Duration(milliseconds: 200),
			padding: const EdgeInsets.all(8),
			decoration: BoxDecoration(
				color: isSelected ? Colors.deepOrange.withValues(alpha: 0.08) : Colors.white,
				borderRadius: BorderRadius.circular(12),
				border: isSelected ? Border.all(color: Colors.deepOrange.shade300, width: 1.5) : null,
				boxShadow: isSelected
						? []
						: [
								BoxShadow(
									color: Colors.black.withValues(alpha: 0.06),
									blurRadius: 10,
									offset: const Offset(0, 3),
									spreadRadius: 0,
								),
							],
			),
			child: Row(
				children: [
					Container(
						width: 48,
						height: 48,
						decoration: BoxDecoration(
							color: isSelected
									? Colors.deepOrange.withValues(alpha: 0.15)
									: Colors.grey.shade100,
							borderRadius: BorderRadius.circular(8),
							image: const DecorationImage(
								image: NetworkImage(
									'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=200&h=200&fit=crop',
								),
								fit: BoxFit.cover,
								opacity: 0.8,
							),
						),
						child: Center(
							child: Icon(
								Icons.fitness_center_rounded,
								size: 20,
								color: isSelected ? Colors.deepOrange : Colors.white70,
							),
						),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Text(
							title,
							style: GoogleFonts.inter(
								fontSize: 14,
								fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
								color: isSelected ? Colors.deepOrange.shade800 : Colors.black87,
							),
							maxLines: 2,
							overflow: TextOverflow.ellipsis,
						),
					),
					if (isSelected) ...[
						const SizedBox(width: 8),
						const Icon(Icons.check_circle_rounded, color: Colors.deepOrange, size: 20),
						const SizedBox(width: 8),
					],
				],
			),
		);
	}
}
