import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/expense_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common/amount_field.dart';
import '../../widgets/common/category_picker.dart';
import '../../widgets/common/date_time_picker_row.dart';

/// Add/Edit Expense form. Pass an existing [expense] to edit it in place;
/// omit it to create a new one. Handles its own validation and persists
/// via [expenseRepositoryProvider] -- no business logic lives in the
/// screen beyond assembling the ExpenseModel from form state.
class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  bool get isEditing => expense != null;

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _notesController;

  late DateTime _dateTime;
  String? _category;
  String _paymentMethod = AppConstants.paymentMethods.first;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amountController =
        TextEditingController(text: e != null ? e.amount.toStringAsFixed(2) : '');
    _customCategoryController = TextEditingController(text: e?.customCategory ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _dateTime = e?.dateTime ?? DateTime.now();
    _category = e?.category;
    _paymentMethod = e?.paymentMethod ?? AppConstants.paymentMethods.first;
    _imagePath = e?.imagePath;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isOthersSelected => _category == 'Others';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  Future<void> _save() async {
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final amount = double.parse(_amountController.text.trim());
    final dateOnly = DateTime(_dateTime.year, _dateTime.month, _dateTime.day);

    final repo = ref.read(expenseRepositoryProvider);

    try {
      if (widget.isEditing) {
        final updated = widget.expense!
          ..date = dateOnly
          ..dateTime = _dateTime
          ..category = _category!
          ..customCategory = _isOthersSelected ? _customCategoryController.text.trim() : null
          ..amount = amount
          ..paymentMethod = _paymentMethod
          ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim()
          ..imagePath = _imagePath;
        await repo.updateExpense(updated);
      } else {
        final expense = ExpenseModel()
          ..date = dateOnly
          ..dateTime = _dateTime
          ..category = _category!
          ..customCategory = _isOthersSelected ? _customCategoryController.text.trim() : null
          ..amount = amount
          ..paymentMethod = _paymentMethod
          ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim()
          ..imagePath = _imagePath;
        await repo.addExpense(expense);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!widget.isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
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
      await ref.read(expenseActionsProvider.notifier).delete(widget.expense!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
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
            Center(child: AmountField(controller: _amountController, accentColor: AppColors.expense)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            DateTimePickerRow(
              value: _dateTime,
              onChanged: (v) => setState(() => _dateTime = v),
            ),
            const SizedBox(height: 24),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            CategoryPicker(
              items: AppConstants.expenseCategories,
              selected: _category,
              accentColor: AppColors.expense,
              onSelected: (v) => setState(() => _category = v),
            ),
            if (_isOthersSelected) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(labelText: 'Custom category name'),
                validator: (v) => Validators.customCategory(v, isRequired: true),
              ),
            ],
            const SizedBox(height: 24),
            Text('Payment Method', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            CategoryPicker(
              items: AppConstants.paymentMethods,
              selected: _paymentMethod,
              accentColor: AppColors.expense,
              onSelected: (v) => setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
              validator: Validators.notes,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_imagePath == null ? 'Attach Photo (optional)' : 'Photo attached ✓'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isEditing ? 'Update Expense' : 'Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
