import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/perspective_scroll_item.dart';
import '../theme/app_colors.dart';
import '../models/bank_account.dart';
import 'add_expense_screen.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  String _selectedType = 'All'; // 'All', 'Expense', 'Income'
  String _selectedAccountId = 'All'; // 'All' or specific account ID

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final accounts = ref.watch(accountProvider);

    final filteredExpenses = expenses.where((e) {
      final matchesType = _selectedType == 'All' || 
          (_selectedType == 'Income' && e.isIncome) ||
          (_selectedType == 'Expense' && !e.isIncome);
      final matchesAccount = _selectedAccountId == 'All' || e.accountId == _selectedAccountId;
      return matchesType && matchesAccount;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Column(
        children: [
          _buildFilterSection(accounts),
          Expanded(
            child: filteredExpenses.isEmpty
                ? _buildEmptyState(message: expenses.isEmpty ? 'No transactions yet' : 'No matching transactions found')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = filteredExpenses[index];
                      final account = accounts.firstWhere(
                        (acc) => acc.id == e.accountId,
                        orElse: () => accounts.isNotEmpty ? accounts[0] : BankAccount(name: 'Unknown', balance: 0, type: AccountType.wallet),
                      );
                      return PerspectiveScrollItem(
                        child: TransactionTile(
                          expense: e, 
                          accountName: account.name,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddExpenseScreen(initialExpense: e),
                            ),
                          ),
                          onDelete: () => ref.read(expenseProvider.notifier).deleteExpense(e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(List<BankAccount> accounts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', _selectedType == 'All', () {
            setState(() => _selectedType = 'All');
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Income', _selectedType == 'Income', () {
            setState(() => _selectedType = 'Income');
          }, activeColor: Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('Expense', _selectedType == 'Expense', () {
            setState(() => _selectedType = 'Expense');
          }, activeColor: Colors.red),
          
          if (accounts.length > 1) ...[
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 24,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(width: 16),
            _buildFilterChip('All Accounts', _selectedAccountId == 'All', () {
              setState(() => _selectedAccountId = 'All');
            }),
            ...accounts.map((acc) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildFilterChip(acc.name, _selectedAccountId == acc.id, () {
                  setState(() => _selectedAccountId = acc.id);
                }),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = activeColor ?? AppColors.primary;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: themeColor,
      backgroundColor: isDark ? AppColors.cardDark : Colors.grey.shade100,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState({String message = 'No transactions yet'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
