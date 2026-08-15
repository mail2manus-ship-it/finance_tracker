import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/transaction_filter.dart';

/// Bottom sheet exposing the date-range preset, transaction type, and
/// category filters. Returns the updated [TransactionFilter] via Navigator
/// pop; the caller writes it into [transactionFilterProvider].
class FilterSheet extends StatefulWidget {
  final TransactionFilter initial;
  const FilterSheet({super.key, required this.initial});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late TransactionFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  static const _presetLabels = {
    DateFilterPreset.all: 'All',
    DateFilterPreset.today: 'Today',
    DateFilterPreset.yesterday: 'Yesterday',
    DateFilterPreset.thisWeek: 'This Week',
    DateFilterPreset.thisMonth: 'This Month',
    DateFilterPreset.thisYear: 'This Year',
  };

  @override
  Widget build(BuildContext context) {
    final allCategories = {
      ...AppConstants.expenseCategories,
      ...AppConstants.incomeSources,
    }.toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TransactionTypeFilter.values.map((t) {
                return ChoiceChip(
                  label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                  selected: _filter.type == t,
                  onSelected: (_) => setState(() => _filter = _filter.copyWith(type: t)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetLabels.entries.map((e) {
                return ChoiceChip(
                  label: Text(e.value),
                  selected: _filter.datePreset == e.key,
                  onSelected: (_) => setState(
                    () => _filter = _filter.copyWith(datePreset: e.key),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Any'),
                  selected: _filter.category == null,
                  onSelected: (_) => setState(
                    () => _filter = _filter.copyWith(clearCategory: true),
                  ),
                ),
                ...allCategories.map((c) => ChoiceChip(
                      label: Text(c),
                      selected: _filter.category == c,
                      onSelected: (_) => setState(
                        () => _filter = _filter.copyWith(category: c),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _filter = const TransactionFilter()),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _filter),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
