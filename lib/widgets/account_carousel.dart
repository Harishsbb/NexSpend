import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bank_account.dart';
import '../theme/app_colors.dart';

class AccountCarousel extends StatefulWidget {
  final List<BankAccount> accounts;
  final void Function(BankAccount) onDelete;

  const AccountCarousel({
    super.key,
    required this.accounts,
    required this.onDelete,
  });

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  late final PageController _controller;
  double _page = 0;

  static const _gradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    [Color(0xFF10B981), Color(0xFF0EA5E9)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.82);
    _controller.addListener(() {
      final p = _controller.page;
      if (p != null) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/empty_accounts.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No accounts yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.accounts.length,
            itemBuilder: (context, index) => _buildItem(index),
          ),
        ),
        if (widget.accounts.length > 1) ...[
          const SizedBox(height: 14),
          _buildDots(),
        ],
      ],
    );
  }

  Widget _buildItem(int index) {
    final delta = index - _page;
    final angle = (delta * 0.35).clamp(-0.6, 0.6);
    final scale = (1.0 - delta.abs() * 0.06).clamp(0.88, 1.0);
    final shadowBlur = (24 - delta.abs() * 6).clamp(8.0, 24.0);
    final shadowOffset = (10 + delta.abs() * 4).clamp(10.0, 18.0);
    final colors = _gradients[index % _gradients.length];
    final account = widget.accounts[index];
    final format = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Transform.scale(
        scale: scale,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective depth
            ..rotateY(-angle),
          child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.45),
                blurRadius: shadowBlur,
                offset: Offset(0, shadowOffset),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(_iconFor(account.type), color: Colors.white, size: 30),
                    GestureDetector(
                      onTap: () => widget.onDelete(account),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white60, size: 20),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  account.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  format.format(account.balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildDots() {
    final current = _page.round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.accounts.length, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  IconData _iconFor(AccountType type) => switch (type) {
        AccountType.savings => Icons.account_balance_wallet_outlined,
        AccountType.current => Icons.business_center_outlined,
        AccountType.wallet => Icons.account_balance_outlined,
      };
}
