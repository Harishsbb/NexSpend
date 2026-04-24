import 'package:flutter/material.dart';
import '../models/bank_account.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class AccountCard extends StatelessWidget {
  final BankAccount account;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    required this.index,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    // Dynamic colors based on index
    final List<Color> cardColors = [
      AppColors.primary,
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
    ];
    final color = cardColors[index % cardColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _getIcon(account.type),
                  color: Colors.white,
                  size: 28,
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              account.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(account.balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.account_balance_wallet_outlined;
      case AccountType.current:
        return Icons.business_center_outlined;
      case AccountType.wallet:
        return Icons.account_balance_outlined;
    }
  }
}
