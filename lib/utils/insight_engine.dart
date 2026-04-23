import '../models/expense.dart';
import '../models/bank_account.dart';
import 'package:collection/collection.dart';

class InsightEngine {
  static List<String> generateInsights(List<Expense> expenses, List<BankAccount> accounts) {
    List<String> insights = [];

    if (expenses.isEmpty) return ["Start adding expenses to see insights!"];

    // 1. Highest spending category
    final categoryTotals = groupBy(expenses, (Expense e) => e.category)
        .map((cat, exps) => MapEntry(cat, exps.fold(0.0, (sum, e) => sum + e.amount)));
    
    final highestCategory = categoryTotals.entries.sorted((a, b) => b.value.compareTo(a.value)).first;
    insights.add("You spent the most on ${highestCategory.key} (₹${highestCategory.value.toStringAsFixed(0)}).");

    // 2. Highest spending account
    final accountTotals = groupBy(expenses, (Expense e) => e.accountId)
        .map((accId, exps) => MapEntry(accId, exps.fold(0.0, (sum, e) => sum + e.amount)));
    
    if (accountTotals.isNotEmpty) {
      final highestAccountId = accountTotals.entries.sorted((a, b) => b.value.compareTo(a.value)).first.key;
      final highestAccount = accounts.firstWhere((a) => a.id == highestAccountId, orElse: () => accounts[0]);
      insights.add("Your highest spending account is ${highestAccount.name}.");
    }

    // 3. Saving Tips
    if (categoryTotals.containsKey('Food') && categoryTotals['Food']! > 10000) {
      insights.add("Try reducing dining out to save around 15% this month.");
    }
    
    insights.add("Tip: Setting a budget for 'Shopping' can help you save more.");

    return insights;
  }
}
