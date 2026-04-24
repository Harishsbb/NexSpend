import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/bank_account.dart';
import '../providers/account_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/account_card.dart';
import '../widgets/transaction_tile.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'add_account_screen.dart';
import 'all_accounts_screen.dart';
import 'all_transactions_screen.dart';
import 'all_budgets_screen.dart';

import 'profile_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final accounts = ref.watch(accountProvider);
    final expenses = ref.watch(expenseProvider);
    final budgets = ref.watch(budgetProvider);
    final totalBalance = ref.watch(accountProvider.notifier).totalBalance;
    
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return userAsync.when(
      data: (user) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Welcome back, ${user?.displayName ?? 'User'}!',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(totalBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Your Accounts', 
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllAccountsScreen()),
                      ), 
                      onAdd: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddAccountScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return AccountCard(
                          account: account,
                          index: index,
                          onTap: () {},
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Account'),
                                content: Text('Are you sure you want to delete "${account.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.read(accountProvider.notifier).deleteAccount(account.id);
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                    'Recent Transactions', 
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllTransactionsScreen()),
                    ),
                  ),
                    const SizedBox(height: 16),
                    if (expenses.isEmpty)
                      _buildEmptyState()
                    else
                      ...expenses.take(5).map((e) {
                        final account = accounts.firstWhere(
                          (acc) => acc.id == e.accountId,
                          orElse: () => accounts.isNotEmpty ? accounts[0] : BankAccount(name: 'Unknown', balance: 0, type: AccountType.wallet),
                        );
                        return TransactionTile(
                          expense: e, 
                          accountName: account.name,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddExpenseScreen(initialExpense: e),
                            ),
                          ),
                          onDelete: () => ref.read(expenseProvider.notifier).deleteExpense(e),
                        );
                      }),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                    'Budgets', 
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllBudgetsScreen()),
                    ),
                  ),
                    const SizedBox(height: 16),
                    ...budgets.map((b) => _buildBudgetCard(context, b, ref)),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No transactions yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }  Widget _buildBudgetCard(BuildContext context, dynamic budget, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = budget.progress;
    final color = budget.isExceeded 
        ? AppColors.error 
        : budget.isNearingLimit 
            ? AppColors.warning 
            : AppColors.success;

    return GestureDetector(
      onTap: () => _showEditBudgetDialog(context, budget, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(budget.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${NumberFormat.compact().format(budget.currentSpending)} / ${NumberFormat.compact().format(budget.limit)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            if (budget.isNearingLimit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    budget.isExceeded ? 'Limit exceeded!' : 'Approaching limit',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
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
