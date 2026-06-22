import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bank_account.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../utils/file_saver.dart';

class DatabaseService {
  final String _baseUrl = 'https://finance-flow-server-jjob.onrender.com/api';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  
  String get _expensesKey => 'cached_expenses_${_uid ?? 'guest'}';
  String get _accountsKey => 'cached_accounts_${_uid ?? 'guest'}';
  String get _budgetsKey => 'cached_budgets_${_uid ?? 'guest'}';

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

  Stream<List<Budget>> getBudgets() async* {
    // 1. Emit cached budgets immediately if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_budgetsKey);
      if (cachedJson != null) {
        final List<dynamic> data = json.decode(cachedJson);
        yield data.map((json) => Budget.fromMap(json, '')).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached budgets: $e');
    }

    // 2. Fetch fresh budgets from network
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/budgets'), headers: headers);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_budgetsKey, response.body);

        final List<dynamic> data = json.decode(response.body);
        yield data.map((json) => Budget.fromMap(json, '')).toList();
      }
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
    }
  }

  Future<void> setBudget(Budget budget) async {
    try {
      // 1. Write to cache first
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(_budgetsKey);
        List<dynamic> list = [];
        if (cachedJson != null) {
          list = json.decode(cachedJson);
        }
        list.removeWhere((item) => item['category'] == budget.category && item['isIncome'] == budget.isIncome);
        list.add(budget.toMap());
        await prefs.setString(_budgetsKey, json.encode(list));
      } catch (e) {
        debugPrint('Error updating cached budgets: $e');
      }

      // 2. Send to network
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

  Stream<List<BankAccount>> getAccounts() async* {
    // 1. Emit cached accounts immediately if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_accountsKey);
      if (cachedJson != null) {
        final List<dynamic> data = json.decode(cachedJson);
        yield data.map((json) => BankAccount.fromMap(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached accounts: $e');
    }

    // 2. Fetch fresh accounts from network
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/accounts'), headers: headers);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accountsKey, response.body);

        final List<dynamic> data = json.decode(response.body);
        yield data.map((json) => BankAccount.fromMap(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
    }
  }

  Future<void> addAccount(BankAccount account) async {
    try {
      // 1. Write to cache first
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(_accountsKey);
        List<dynamic> list = [];
        if (cachedJson != null) {
          list = json.decode(cachedJson);
        }
        list.removeWhere((item) => item['id'] == account.id);
        list.add(account.toMap());
        await prefs.setString(_accountsKey, json.encode(list));
      } catch (e) {
        debugPrint('Error updating cached accounts: $e');
      }

      // 2. Send to network
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
      // 1. Write to cache first
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(_accountsKey);
        if (cachedJson != null) {
          List<dynamic> list = json.decode(cachedJson);
          list.removeWhere((item) => item['id'] == accountId);
          await prefs.setString(_accountsKey, json.encode(list));
        }
      } catch (e) {
        debugPrint('Error updating cached accounts: $e');
      }

      // 2. Send to network
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
    await addAccount(account);
  }

  // --- Expenses ---

  Stream<List<Expense>> getExpenses() async* {
    // 1. Emit cached expenses immediately if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_expensesKey);
      if (cachedJson != null) {
        final List<dynamic> data = json.decode(cachedJson);
        yield data.map((json) => Expense.fromMap(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached expenses: $e');
    }

    // 2. Fetch fresh expenses from network
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/expenses'), headers: headers);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_expensesKey, response.body);

        final List<dynamic> data = json.decode(response.body);
        yield data.map((json) => Expense.fromMap(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      // 1. Write to cache first
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(_expensesKey);
        List<dynamic> list = [];
        if (cachedJson != null) {
          list = json.decode(cachedJson);
        }
        list.removeWhere((item) => item['id'] == expense.id);
        list.add(expense.toMap());
        await prefs.setString(_expensesKey, json.encode(list));
      } catch (e) {
        debugPrint('Error updating cached expenses: $e');
      }

      // 2. Send to network
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
      // 1. Write to cache first
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(_expensesKey);
        if (cachedJson != null) {
          List<dynamic> list = json.decode(cachedJson);
          list.removeWhere((item) => item['id'] == expense.id);
          await prefs.setString(_expensesKey, json.encode(list));
        }
      } catch (e) {
        debugPrint('Error updating cached expenses: $e');
      }

      // 2. Send to network
      final headers = await _getHeaders();
      await http.delete(
        Uri.parse('$_baseUrl/expenses/${expense.id}'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }

  Future<void> exportExpensesPdf({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (accountId != null && accountId != 'All') {
        queryParams['accountId'] = accountId;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$_baseUrl/expenses/export').replace(queryParameters: queryParams);
      debugPrint('Exporting PDF from URL: $uri');
      
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await saveFile(bytes, 'transactions_report.pdf');
      } else {
        debugPrint('Failed to export PDF: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error exporting expenses PDF: $e');
    }
  }
}
