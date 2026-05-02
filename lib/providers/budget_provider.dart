import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import 'expense_provider.dart';
import '../services/auth_service.dart';
import 'account_provider.dart';

final budgetStreamProvider = StreamProvider<List<Budget>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final dbService = ref.read(databaseServiceProvider);
      return dbService.getBudgets();
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.value([]),
  );
});

class BudgetNotifier extends StateNotifier<List<Budget>> {
  final Ref ref;
  BudgetNotifier(this.ref) : super([
    // Expense Budgets
    Budget(category: 'Food', limit: 5000, isIncome: false),
    Budget(category: 'Travel', limit: 3000, isIncome: false),
    Budget(category: 'Shopping', limit: 10000, isIncome: false),
    Budget(category: 'Bills', limit: 15000, isIncome: false),
    Budget(category: 'Health', limit: 5000, isIncome: false),
    Budget(category: 'Entertainment', limit: 5000, isIncome: false),
    Budget(category: 'Other', limit: 2000, isIncome: false),
    // Income Budgets (Targets)
    Budget(category: 'Salary', limit: 50000, isIncome: true),
    Budget(category: 'Freelance', limit: 10000, isIncome: true),
    Budget(category: 'Investments', limit: 5000, isIncome: true),
  ]) {
    // Listen to firestore budgets
    ref.listen(budgetStreamProvider, (prev, next) {
      next.whenData((firestoreBudgets) {
        if (firestoreBudgets.isNotEmpty) {
          _syncWithFirestore(firestoreBudgets);
        }
      });
    });

    // Listen to expenses
    ref.listen(expenseProvider, (previous, next) {
      _updateSpending(next);
    });
  }

  void _syncWithFirestore(List<Budget> firestoreBudgets) {
    state = [
      for (final b in state)
        firestoreBudgets.firstWhere(
          (fb) => fb.category == b.category && fb.isIncome == b.isIncome,
          orElse: () => b,
        )
    ];
    _updateSpending(ref.read(expenseProvider));
  }

  void _updateSpending(List<Expense> expenses) {
    state = [
      for (final budget in state)
        budget.copyWith(
          currentAmount: expenses
              .where((e) => e.category == budget.category && e.isIncome == budget.isIncome)
              .fold<double>(0.0, (sum, e) => sum + e.amount),
        )
    ];
  }

  Future<void> updateLimit(String category, double limit, bool isIncome) async {
    final budget = state.firstWhere((b) => b.category == category && b.isIncome == isIncome).copyWith(limit: limit);
    await ref.read(databaseServiceProvider).setBudget(budget);
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier(ref);
});
