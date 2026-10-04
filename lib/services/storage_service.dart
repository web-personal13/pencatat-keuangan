import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../core/categories.dart';

class StorageService extends ChangeNotifier {
  static const String _keyBudget = 'monthlyBudget';
  static const String _keyExpensesLegacy = 'expenses';
  static const String _keyTransactions = 'transactions_v2';
  static const String _keyUserName = 'userName';
  static const String _keyInstallDate = 'installDate';
  static const String _keyCustomBarcodes = 'custom_barcodes';

  double _monthlyBudget = 0.0;
  String _userName = '';
  DateTime _installDate = DateTime.now();
  List<Transaction> _transactions = [];
  Map<String, Map<String, String>> _customBarcodes = {};

  double get monthlyBudget => _monthlyBudget;
  String get userName => _userName;
  DateTime get installDate => _installDate;
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  Map<String, Map<String, String>> get customBarcodes => _customBarcodes;

  bool get hasUserConfiguredName => _userName.trim().isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _monthlyBudget = prefs.getDouble(_keyBudget) ?? 0.0;
    _userName = prefs.getString(_keyUserName) ?? '';

    // Check v2 transactions first
    final String? v2Json = prefs.getString(_keyTransactions);
    if (v2Json != null && v2Json.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(v2Json);
        _transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error parsing v2 transactions: $e');
        _transactions = [];
      }
    } else {
      // Fallback & migrate legacy expenses
      final String? legacyJson = prefs.getString(_keyExpensesLegacy);
      if (legacyJson != null && legacyJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(legacyJson);
          _transactions = decoded.map((e) {
            final t = Transaction.fromJson(e);
            t.category = migrateCategory(t.category);
            return t;
          }).toList();
          // Save migrated to v2
          await _persistTransactions();
        } catch (e) {
          debugPrint('Error migrating legacy expenses: $e');
        }
      }
    }

    final String? savedInstallDate = prefs.getString(_keyInstallDate);
    if (savedInstallDate != null) {
      _installDate = DateTime.tryParse(savedInstallDate) ?? DateTime.now();
    } else {
      DateTime earliest = DateTime.now();
      for (var t in _transactions) {
        if (t.date.isBefore(earliest)) {
          earliest = t.date;
        }
      }
      _installDate = DateTime(earliest.year, earliest.month, 1);
      await prefs.setString(_keyInstallDate, _installDate.toIso8601String());
    }

    final String? customBarcodesJson = prefs.getString(_keyCustomBarcodes);
    if (customBarcodesJson != null && customBarcodesJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(customBarcodesJson);
        _customBarcodes = decoded.map((k, v) =>
            MapEntry(k, Map<String, String>.from(v as Map)));
      } catch (e) {
        debugPrint('Error parsing custom barcodes: $e');
      }
    }

    notifyListeners();
  }

  Future<void> saveCustomBarcode(String barcode, String name, String category) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty || name.trim().isEmpty) return;
    _customBarcodes[cleanCode] = {
      'name': name.trim(),
      'cat': category.trim(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomBarcodes, jsonEncode(_customBarcodes));
    notifyListeners();
  }

  Map<String, String>? getCustomBarcode(String barcode) {
    return _customBarcodes[barcode.trim()];
  }

  /// Menghasilkan daftar bulan dari bulan instalasi hingga bulan saat ini (berjalan),
  /// diurutkan dari yang terbaru (bulan ini) ke terlama.
  /// Otomatis bertambah saat bulan kalender berganti di masa depan.
  List<DateTime> getAvailableMonths() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    DateTime start = DateTime(_installDate.year, _installDate.month);

    for (var t in _transactions) {
      final tMonth = DateTime(t.date.year, t.date.month);
      if (tMonth.isBefore(start)) {
        start = tMonth;
      }
    }

    final List<DateTime> months = [];
    var cursor = currentMonth;
    while (!cursor.isBefore(start)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month - 1);
    }
    return months;
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, _userName);
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBudget, _monthlyBudget);
    notifyListeners();
  }

  Future<void> addTransaction(Transaction tx) async {
    _transactions.insert(0, tx);
    await _persistTransactions();
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction updated) async {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _transactions[index] = updated;
      await _persistTransactions();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _persistTransactions();
    notifyListeners();
  }

  Future<int> deleteTransactionsForMonth(int year, int month) async {
    final countBefore = _transactions.length;
    _transactions.removeWhere((t) => t.date.year == year && t.date.month == month);
    final deletedCount = countBefore - _transactions.length;
    await _persistTransactions();
    notifyListeners();
    return deletedCount;
  }

  Future<void> updateProfile({required String name, required double budget}) async {
    _userName = name.trim();
    _monthlyBudget = budget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, _userName);
    await prefs.setDouble(_keyBudget, _monthlyBudget);
    notifyListeners();
  }

  Future<void> _persistTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_keyTransactions, encoded);
    // Also update legacy key for safety
    await prefs.setString(_keyExpensesLegacy, encoded);
  }

  // Financial calculations
  double totalIncome({DateTime? forMonth}) {
    return _transactions
        .where((t) => t.isIncome && (forMonth == null || (t.date.year == forMonth.year && t.date.month == forMonth.month)))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double totalExpense({DateTime? forMonth}) {
    return _transactions
        .where((t) => t.isExpense && (forMonth == null || (t.date.year == forMonth.year && t.date.month == forMonth.month)))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double netBalance({DateTime? forMonth}) {
    return totalIncome(forMonth: forMonth) - totalExpense(forMonth: forMonth);
  }

  double remainingBudget({DateTime? forMonth}) {
    return _monthlyBudget - totalExpense(forMonth: forMonth);
  }
}

