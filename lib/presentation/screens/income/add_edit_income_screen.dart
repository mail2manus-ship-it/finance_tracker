import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/income_model.dart';
import '../../providers/income_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common/amount_field.dart';
import '../../widgets/common/category_picker.dart';
import '../../widgets/common/date_time_picker_row.dart';

class AddEditIncomeScreen extends ConsumerStatefulWidget {
  final IncomeModel? income;

  const AddEditIncomeScreen({super.key, this.income});

  bool get isEditing => income != null;

  @override
  ConsumerState<AddEditIncomeScreen> createState() => _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends ConsumerState<AddEditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late DateTime _dateTime;
  String? _source;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.income;
    _amountController =
        TextEditingController(text: i != null ? i.amount.toStringAsFixed(2) : '');
    _notesController = TextEditingController(text: i?.notes ?? '');
    _dateTime = i?.dateTime ?? DateTime.now();
    _source = i?.source;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final amount = double.parse(_amountController.text.trim());
    final dateOnly = DateTime(_dateTime.year, _dateTime.month, _dateTime.day);
    final repo = ref.read(incomeRepositoryProvider);

    try {
      if (widget.isEditing) {
        final updated = widget.income!
          ..date = dateOnly
          ..dateTime = _dateTime
          ..source = _source!
          ..amount = amount
          ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
        await repo.updateIncome(updated);
      } else {
        final income = IncomeModel()
          ..date = dateOnly
          ..dateTime = _dateTime
          ..source = _source!
          ..amount = amount
          ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
        await repo.addIncome(income);
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!widget.isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete income?'),
        content: const Text('You can undo this from the Transactions list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(incomeActionsProvider.notifier).delete(widget.income!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Income' : 'Add Income'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(child: AmountField(controller: _amountController, accentColor: AppColors.income)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            DateTimePickerRow(
              value: _dateTime,
              onChanged: (v) => setState(() => _dateTime = v),
            ),
            const SizedBox(height: 24),
            Text('Source', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            CategoryPicker(
              items: AppConstants.incomeSources,
              selected: _source,
              accentColor: AppColors.income,
              onSelected: (v) => setState(() => _source = v),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
              validator: Validators.notes,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.income),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isEditing ? 'Update Income' : 'Save Income'),
            ),
          ],
        ),
      ),
    );
  }
}
