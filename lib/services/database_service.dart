import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bank_account.dart';
import '../models/expense.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/budget.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- Budgets ---

  Stream<List<Budget>> getBudgets() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> setBudget(Budget budget) async {
    final uid = _uid;
    if (uid == null) return;
    final query = await _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .where('category', isEqualTo: budget.category)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(budget.toMap());
    } else {
      await _db
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .add(budget.toMap());
    }
  }

  // --- Bank Accounts ---

  Stream<List<BankAccount>> getAccounts() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BankAccount.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addAccount(BankAccount account) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(account.id)
        .set(account.toMap());
  }

  Future<void> deleteAccount(String accountId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  Future<void> updateAccount(BankAccount account) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(account.id)
        .update(account.toMap());
  }

  // --- Expenses ---

  Stream<List<Expense>> getExpenses() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> addExpense(Expense expense) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toMap());
  }

  Future<void> deleteExpense(Expense expense) async {
    final uid = _uid;
    if (uid == null) return;
    
    // Delete the transaction
    await _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expense.id)
        .delete();

    // REVERT the balance on the account
    final accountRef = _db
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(expense.accountId);

    await _db.runTransaction((transaction) async {
      final accountSnapshot = await transaction.get(accountRef);
      if (accountSnapshot.exists) {
        final currentBalance = (accountSnapshot.data()?['balance'] ?? 0.0).toDouble();
        // If it was income, subtract it back. If it was expense, add it back.
        final revertedBalance = expense.isIncome 
            ? currentBalance - expense.amount 
            : currentBalance + expense.amount;
        
        transaction.update(accountRef, {'balance': revertedBalance});
      }
    });
  }
}
