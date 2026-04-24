import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime dateTime;
  final String accountId;
  final String? note;
  final bool isIncome;

  Expense({
    String? id,
    required this.amount,
    required this.category,
    required this.dateTime,
    required this.accountId,
    this.note,
    this.isIncome = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
      'accountId': accountId,
      'note': note,
      'isIncome': isIncome,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toString() ?? const Uuid().v4(),
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category']?.toString() ?? 'Other',
      dateTime: map['dateTime'] != null ? DateTime.parse(map['dateTime']) : DateTime.now(),
      accountId: map['accountId']?.toString() ?? '',
      note: map['note']?.toString(),
      isIncome: map['isIncome'] ?? false,
    );
  }
}
