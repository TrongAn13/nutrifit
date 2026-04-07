import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanFilterResult {
  final String? category;
  final String? equipment;
  final String? level;
  final int? daysPerWeek;
  final String? gender;

  const PlanFilterResult({
    this.category,
    this.equipment,
    this.level,
    this.daysPerWeek,
    this.gender,
  });

  PlanFilterResult copyWith({
    String? category,
    String? equipment,
    String? level,
    int? daysPerWeek,
    String? gender,
    bool clearCategory = false,
    bool clearEquipment = false,
    bool clearLevel = false,
    bool clearDaysPerWeek = false,
    bool clearGender = false,
  }) {
    return PlanFilterResult(
      category: clearCategory ? null : (category ?? this.category),
      equipment: clearEquipment ? null : (equipment ?? this.equipment),
      level: clearLevel ? null : (level ?? this.level),
      daysPerWeek:
          clearDaysPerWeek ? null : (daysPerWeek ?? this.daysPerWeek),
      gender: clearGender ? null : (gender ?? this.gender),
    );
  }
}

Future<PlanFilterResult?> showFilterBottomSheet(
  BuildContext context, {
  required PlanFilterResult initialValue,
  required List<String> categoryOptions,
  required List<String> equipmentOptions,
  required List<String> levelOptions,
  required List<int> dayOptions,
  required List<String> genderOptions,
}) {
  final sortedCategory = [...categoryOptions]..sort();
  final sortedEquipment = [...equipmentOptions]..sort();
  final sortedLevel = [...levelOptions]..sort();
  final sortedDays = [...dayOptions]..sort();
  final sortedGender = [...genderOptions]..sort();

  final colorScheme = Theme.of(context).colorScheme;
  final accentColor = Color.lerp(colorScheme.primary, Colors.white, 0.08) ??
      colorScheme.primary;

  PlanFilterResult tempValue = initialValue;

  return showModalBottomSheet<PlanFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final sheetHeight = MediaQuery.of(context).size.height * 0.5;

          return SafeArea(
            top: false,
            child: SizedBox(
              height: sheetHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E8EB),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FilterSection<String>(
                              title: 'Category',
                              options: sortedCategory,
                              selectedValue: tempValue.category,
                              chipTextBuilder: (value) => value,
                              accentColor: accentColor,
                              onChanged: (value) {
                                setSheetState(() {
                                  tempValue =
                                      tempValue.copyWith(category: value);
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _FilterSection<String>(
                              title: 'Equipment',
                              options: sortedEquipment,
                              selectedValue: tempValue.equipment,
                              chipTextBuilder: (value) => value,
                              accentColor: accentColor,
                              onChanged: (value) {
                                setSheetState(() {
                                  tempValue =
                                      tempValue.copyWith(equipment: value);
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _FilterSection<String>(
                              title: 'Difficulty Level',
                              options: sortedLevel,
                              selectedValue: tempValue.level,
                              chipTextBuilder: (value) => value,
                              accentColor: accentColor,
                              onChanged: (value) {
                                setSheetState(() {
                                  tempValue = tempValue.copyWith(level: value);
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _FilterSection<int>(
                              title: 'Days Per Week',
                              options: sortedDays,
                              selectedValue: tempValue.daysPerWeek,
                              chipTextBuilder: (value) => '$value days',
                              accentColor: accentColor,
                              onChanged: (value) {
                                setSheetState(() {
                                  tempValue =
                                      tempValue.copyWith(daysPerWeek: value);
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _FilterSection<String>(
                              title: 'Gender',
                              options: sortedGender,
                              selectedValue: tempValue.gender,
                              chipTextBuilder: (value) => value,
                              accentColor: accentColor,
                              onChanged: (value) {
                                setSheetState(() {
                                  tempValue = tempValue.copyWith(gender: value);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  tempValue = const PlanFilterResult();
                                });
                              },
                              icon: Icon(
                                Icons.refresh,
                                color: accentColor,
                              ),
                              label: Text(
                                'Default',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                side: BorderSide(color: accentColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, tempValue),
                              icon: const Icon(Icons.filter_alt_outlined),
                              label: Text(
                                'Apply',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _FilterSection<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T? selectedValue;
  final String Function(T value) chipTextBuilder;
  final ValueChanged<T?> onChanged;
  final Color accentColor;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.chipTextBuilder,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        chipTextBuilder(option),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: selectedValue == option
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selectedValue == option
                              ? Colors.white
                              : const Color(0xFF7B6F72),
                        ),
                      ),
                      selected: selectedValue == option,
                      onSelected: (_) => onChanged(option),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      showCheckmark: false,
                      side: BorderSide.none,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      backgroundColor: const Color(0xFFF7F8F8),
                      selectedColor: accentColor,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
