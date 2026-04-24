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
    Budget(category: 'Food', limit: 5000),
    Budget(category: 'Travel', limit: 3000),
    Budget(category: 'Shopping', limit: 10000),
    Budget(category: 'Bills', limit: 15000),
    Budget(category: 'Health', limit: 5000),
    Budget(category: 'Entertainment', limit: 5000),
    Budget(category: 'Other', limit: 2000),
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
          (fb) => fb.category == b.category,
          orElse: () => b,
        )
    ];
    _updateSpending(ref.read(expenseProvider));
  }

  void _updateSpending(List<Expense> expenses) {
    state = [
      for (final budget in state)
        budget.copyWith(
          currentSpending: expenses
              .where((e) => e.category == budget.category)
              .fold<double>(0.0, (sum, e) => sum + e.amount),
        )
    ];
  }

  Future<void> updateLimit(String category, double limit) async {
    final budget = state.firstWhere((b) => b.category == category).copyWith(limit: limit);
    await ref.read(databaseServiceProvider).setBudget(budget);
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier(ref);
});
