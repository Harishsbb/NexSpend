import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import 'account_provider.dart';

final expenseStreamProvider = StreamProvider<List<Expense>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getExpenses();
});

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final Ref ref;
  ExpenseNotifier(this.ref) : super([]);

  void setExpenses(List<Expense> expenses) => state = expenses;

  Future<void> addExpense(Expense expense) async {
    await ref.read(databaseServiceProvider).addExpense(expense);
  }

  void deleteExpense(Expense expense) {
    // Implement delete in database_service.dart if needed
    state = state.where((e) => e.id != expense.id).toList();
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  final notifier = ExpenseNotifier(ref);
  ref.listen(expenseStreamProvider, (prev, next) {
    next.whenData((expenses) => notifier.setExpenses(expenses));
  });
  return notifier;
});
