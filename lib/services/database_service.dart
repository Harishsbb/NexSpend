import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/bank_account.dart';
import '../models/expense.dart';
import '../models/budget.dart';

class DatabaseService {
  final String _baseUrl = 'https://finance-flow-server-jjob.onrender.com/api';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  Future<String?> get _token async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _token;
    final uid = _uid;
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (uid != null) {
      headers['x-user-id'] = uid;
    }
    return headers;
  }

  // --- Budgets ---

  Stream<List<Budget>> getBudgets() {
    return Stream.fromFuture(_fetchBudgets());
  }

  Future<List<Budget>> _fetchBudgets() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/budgets'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Budget.fromMap(json, '')).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
      return [];
    }
  }

  Future<void> setBudget(Budget budget) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$_baseUrl/budgets'),
        headers: headers,
        body: json.encode(budget.toMap()),
      );
    } catch (e) {
      debugPrint('Error setting budget: $e');
    }
  }

  // --- Bank Accounts ---

  Stream<List<BankAccount>> getAccounts() {
    return Stream.fromFuture(_fetchAccounts());
  }

  Future<List<BankAccount>> _fetchAccounts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/accounts'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BankAccount.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      return [];
    }
  }

  Future<void> addAccount(BankAccount account) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$_baseUrl/accounts'),
        headers: headers,
        body: json.encode(account.toMap()),
      );
    } catch (e) {
      debugPrint('Error adding account: $e');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      final headers = await _getHeaders();
      await http.delete(
        Uri.parse('$_baseUrl/accounts/$accountId'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
    }
  }

  Future<void> updateAccount(BankAccount account) async {
    // In our backend, saving an account uses findOneAndUpdate (upsert), so we can just call addAccount
    await addAccount(account);
  }

  // --- Expenses ---

  Stream<List<Expense>> getExpenses() {
    return Stream.fromFuture(_fetchExpenses());
  }

  Future<List<Expense>> _fetchExpenses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/expenses'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Expense.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
      return [];
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$_baseUrl/expenses'),
        headers: headers,
        body: json.encode(expense.toMap()),
      );
    } catch (e) {
      debugPrint('Error adding expense: $e');
    }
  }

  Future<void> deleteExpense(Expense expense) async {
    try {
      final headers = await _getHeaders();
      await http.delete(
        Uri.parse('$_baseUrl/expenses/${expense.id}'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }
}

