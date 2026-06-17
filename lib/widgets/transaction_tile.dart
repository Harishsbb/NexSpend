import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final Expense expense;
  final String accountName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.expense,
    required this.accountName,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete != null ? () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction? Your bank balance will be reverted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onDelete!();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                _getCategoryImagePath(expense.category),
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  accountName,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${expense.isIncome ? '+' : '-'} ${currencyFormat.format(expense.amount)}',
                style: TextStyle(
                  color: expense.isIncome ? Colors.green : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat('MMM dd, hh:mm a').format(expense.dateTime),
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'travel': return Icons.directions_car;
      case 'shopping': return Icons.shopping_bag;
      case 'bills': return Icons.receipt_long;
      case 'health': return Icons.medical_services;
      case 'entertainment': return Icons.movie;
      case 'salary': return Icons.monetization_on;
      case 'freelance': return Icons.laptop_mac;
      case 'investments': return Icons.show_chart;
      default: return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'travel': return Colors.blue;
      case 'shopping': return Colors.pink;
      case 'bills': return Colors.purple;
      case 'health': return Colors.redAccent;
      case 'entertainment': return Colors.deepOrange;
      case 'salary': return Colors.green;
      case 'freelance': return Colors.teal;
      case 'investments': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  String _getCategoryImagePath(String category) {
    switch (category.toLowerCase()) {
      case 'food': return 'assets/category_food.png';
      case 'travel': return 'assets/category_travel.png';
      case 'shopping': return 'assets/category_shopping.png';
      case 'bills': return 'assets/category_bills.png';
      default: return 'assets/category_default.png';
    }
  }
}
