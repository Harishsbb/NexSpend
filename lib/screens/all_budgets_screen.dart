import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class AllBudgetsScreen extends ConsumerWidget {
  const AllBudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Budgets'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: budgets.length,
        itemBuilder: (context, index) {
          final budget = budgets[index];
          final progress = budget.progress;
          final color = budget.isExceeded 
              ? AppColors.error 
              : budget.isNearingLimit 
                  ? AppColors.warning 
                  : AppColors.success;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(budget.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditBudgetDialog(context, budget, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${NumberFormat.simpleCurrency(name: 'INR').format(budget.currentSpending)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Limit: ${NumberFormat.simpleCurrency(name: 'INR').format(budget.limit)}',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, dynamic budget, WidgetRef ref) {
    final controller = TextEditingController(text: budget.limit.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${budget.category} Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Limit',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(controller.text);
              if (limit != null) {
                ref.read(budgetProvider.notifier).updateLimit(budget.category, limit);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
