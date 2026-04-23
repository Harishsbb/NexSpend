import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime dateTime;
  final String accountId;
  final String? note;

  Expense({
    String? id,
    required this.amount,
    required this.category,
    required this.dateTime,
    required this.accountId,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
      'accountId': accountId,
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      dateTime: DateTime.parse(map['dateTime']),
      accountId: map['accountId'],
      note: map['note'],
    );
  }
}
