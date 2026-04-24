import 'package:uuid/uuid.dart';

enum AccountType { savings, current, wallet }

class BankAccount {
  final String id;
  final String name;
  final double balance;
  final AccountType type;

  BankAccount({
    String? id,
    required this.name,
    required this.balance,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type.index,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id']?.toString() ?? const Uuid().v4(),
      name: map['name']?.toString() ?? 'Unnamed Account',
      balance: (map['balance'] ?? 0).toDouble(),
      type: AccountType.values[(map['type'] ?? 0).toInt()],
    );
  }

  BankAccount copyWith({
    String? name,
    double? balance,
    AccountType? type,
  }) {
    return BankAccount(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
    );
  }
}
