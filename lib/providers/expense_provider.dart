import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import 'account_provider.dart';

final expenseStreamProvider = StreamProvider<List<Expense>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final dbService = ref.read(databaseServiceProvider);
      return dbService.getExpenses();
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.value([]),
  );
});

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final Ref ref;
  ExpenseNotifier(this.ref) : super([]);

  void setExpenses(List<Expense> expenses) => state = expenses;

  Future<void> addExpense(Expense expense) async {
    await ref.read(databaseServiceProvider).addExpense(expense);
  }

  Future<void> deleteExpense(Expense expense) async {
    await ref.read(databaseServiceProvider).deleteExpense(expense);
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  final notifier = ExpenseNotifier(ref);
  ref.listen(expenseStreamProvider, (prev, next) {
    next.whenData((expenses) => notifier.setExpenses(expenses));
  });
  return notifier;
});
