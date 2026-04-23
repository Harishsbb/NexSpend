import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_account.dart';
import '../providers/account_provider.dart';
import '../theme/app_colors.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _selectedType = AccountType.savings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bank Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _buildTextField('Account Name', Icons.account_balance_outlined, _nameController, hint: 'e.g. HDFC Savings'),
              const SizedBox(height: 24),
              _buildTextField('Initial Balance', Icons.account_balance_wallet_outlined, _balanceController, hint: '0', isNumber: true),
              const SizedBox(height: 32),
              const Text('Account Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip(AccountType.savings, 'Savings'),
                  const SizedBox(width: 8),
                  _buildTypeChip(AccountType.current, 'Current'),
                  const SizedBox(width: 8),
                  _buildTypeChip(AccountType.wallet, 'Wallet'),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _saveAccount,
                child: const Text('Add Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(AccountType type, String label) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedType = type);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {String? hint, bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter $label';
            if (isNumber && double.tryParse(value) == null) return 'Enter a valid number';
            return null;
          },
        ),
      ],
    );
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final account = BankAccount(
        name: _nameController.text.trim(),
        balance: double.parse(_balanceController.text),
        type: _selectedType,
      );
      ref.read(accountProvider.notifier).addAccount(account);
      Navigator.pop(context);
    }
  }
}
