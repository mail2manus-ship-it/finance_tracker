import 'package:flutter/material.dart';

/// Horizontal-wrap chip picker used for both expense categories and income
/// sources. When [items] contains the currently-selected "escape hatch"
/// value (e.g. 'Others' / 'Other'), the caller is responsible for showing
/// a follow-up text field -- this widget only handles the chip selection.
class CategoryPicker extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  const CategoryPicker({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selected;
        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onSelected(item),
          selectedColor: accentColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? accentColor : null,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? accentColor : Theme.of(context).dividerColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }).toList(),
    );
  }
}
