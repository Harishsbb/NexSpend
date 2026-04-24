import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/account_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? initialExpense;
  const AddExpenseScreen({super.key, this.initialExpense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedCategory = 'Food';
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isIncome = false;

  final List<String> _categories = ['Food', 'Travel', 'Shopping', 'Bills', 'Health', 'Entertainment', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      final e = widget.initialExpense!;
      _amountController.text = e.amount.toString();
      _noteController.text = e.note ?? '';
      _selectedCategory = e.category;
      _selectedAccountId = e.accountId;
      _selectedDate = e.dateTime;
      _isIncome = e.isIncome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialExpense != null 
            ? 'Edit Transaction' 
            : (_isIncome ? 'Add Income' : 'Add Expense')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Expense'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Income'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_isIncome},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() => _isIncome = newSelection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: _isIncome ? Colors.green : Colors.red,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Amount', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 40, 
                  fontWeight: FontWeight.bold,
                  color: _isIncome ? Colors.green : (isDark ? Colors.white : Colors.black),
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: _isIncome ? Colors.green : AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: accounts.any((acc) => acc.id == _selectedAccountId) ? _selectedAccountId : null,
                hint: const Text('Select Bank Account'),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text(acc.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedAccountId = value),
                validator: (value) => value == null ? 'Please select an account' : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: _isIncome ? Colors.green : AppColors.primary),
                      const SizedBox(width: 12),
                      Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'What was this for?',
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome ? Colors.green : AppColors.primary,
                ),
                child: Text(
                  widget.initialExpense != null ? 'Update Transaction' : (_isIncome ? 'Save Income' : 'Save Expense'), 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      
      // If editing, we revert the OLD balance change first
      if (widget.initialExpense != null) {
        final oldE = widget.initialExpense!;
        final accounts = ref.read(accountProvider);
        final oldAccount = accounts.firstWhere((acc) => acc.id == oldE.accountId);
        
        // REVERT old balance
        final revertedBalance = oldE.isIncome 
            ? oldAccount.balance - oldE.amount 
            : oldAccount.balance + oldE.amount;
        
        await ref.read(accountProvider.notifier).addAccount(oldAccount.copyWith(balance: revertedBalance));
      }

      final expense = Expense(
        id: widget.initialExpense?.id, // Keep same ID if editing
        amount: amount,
        category: _selectedCategory,
        dateTime: _selectedDate,
        accountId: _selectedAccountId!,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        isIncome: _isIncome,
      );

      await ref.read(expenseProvider.notifier).addExpense(expense);

      // Apply NEW balance
      final updatedAccounts = ref.read(accountProvider);
      final account = updatedAccounts.firstWhere((acc) => acc.id == _selectedAccountId);
      final newBalance = _isIncome 
          ? account.balance + amount 
          : account.balance - amount;
      
      await ref.read(accountProvider.notifier).addAccount(account.copyWith(balance: newBalance));

      // Check if budget is exceeded (only for expenses)
      if (!_isIncome) {
        final budgets = ref.read(budgetProvider);
        final budgetIndex = budgets.indexWhere((b) => b.category == _selectedCategory);
        if (budgetIndex != -1) {
          final budget = budgets[budgetIndex];
          if (budget.currentSpending + amount > budget.limit) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Alert: You have exceeded your ${budget.category} budget!'),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }
}
