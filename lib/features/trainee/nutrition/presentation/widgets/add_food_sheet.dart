import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/food_model.dart';
import '../../logic/food_bloc.dart';
import '../../logic/food_event.dart';

/// Bottom sheet form for adding a new trainee food to the library.
class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({super.key});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _newCategoryCtrl = TextEditingController();

  String? _selectedCategory;
  bool _createNewCategory = false;

  static const _defaultCategories = [
    'Thịt',
    'Cá & Hải sản',
    'Rau củ',
    'Trái cây',
    'Ngũ cốc',
    'Sữa & Trứng',
    'Đồ uống',
    'Snack',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final category = _createNewCategory
        ? _newCategoryCtrl.text.trim()
        : _selectedCategory ?? _defaultCategories.first;

    final food = FoodModel(
      foodId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid,
      name: _nameCtrl.text.trim(),
      category: category,
      calories: double.tryParse(_calCtrl.text.trim()) ?? 0,
      protein: double.tryParse(_proteinCtrl.text.trim()) ?? 0,
      fat: double.tryParse(_fatCtrl.text.trim()) ?? 0,
      carbs: double.tryParse(_carbsCtrl.text.trim()) ?? 0,
      isSystem: false,
      createdAt: DateTime.now(),
    );

    context.read<FoodBloc>().add(FoodAdded(food));
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm "${food.name}" vào thư viện')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag Handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Thêm món ăn mới',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ── Name ──
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên món ăn',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nhập tên món' : null,
              ),
              const SizedBox(height: 14),

              // ── Category / New Category Toggle ──
              if (!_createNewCategory)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Nhóm thực phẩm',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _defaultCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Chọn nhóm thực phẩm' : null,
                )
              else
                TextFormField(
                  controller: _newCategoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm mới',
                    prefixIcon: Icon(Icons.create_new_folder_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập tên nhóm' : null,
                ),
              const SizedBox(height: 6),

              // Checkbox toggle
              Row(
                children: [
                  Checkbox(
                    value: _createNewCategory,
                    onChanged: (v) =>
                        setState(() => _createNewCategory = v ?? false),
                  ),
                  Text('Tạo nhóm mới', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 10),

              // ── Macros Row ──
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _calCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        suffixText: 'kcal',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fat',
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Carbs',
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm vào thư viện'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
