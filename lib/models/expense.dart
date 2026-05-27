import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final String emoji;
  final Color color;
  final bool isExpense; // Distinguishes expenses from self-transfers/investments if needed

  const ExpenseCategory({
    required this.name,
    required this.emoji,
    required this.color,
    this.isExpense = true,
  });

  // Predefined core Apple-inspired curated financial categories
  static const List<ExpenseCategory> list = [
    ExpenseCategory(name: 'Groceries', emoji: '🛒', color: Color(0xFFFFCC00)),     // iOS System Yellow
    ExpenseCategory(name: 'Bike', emoji: '🚲', color: Color(0xFF5AC8FA)),          // iOS System Cyan
    ExpenseCategory(name: 'Shopping', emoji: '🛍️', color: Color(0xFFFF9F0A)),      // iOS Sunset Orange
    ExpenseCategory(name: 'Money Transfer', emoji: '💸', color: Color(0xFFFF375F)), // iOS Crimson Red
    ExpenseCategory(
      name: 'Self Transfer', 
      emoji: '🔄', 
      color: Color(0xFFBF5AF2), 
      isExpense: false, // Smart feature: marked as non-expense!
    ),
    ExpenseCategory(name: 'Investment', emoji: '📈', color: Color(0xFF30D158)),    // iOS Emerald Green
    ExpenseCategory(name: 'Other', emoji: '🏷️', color: Color(0xFF8E8E93)),         // Premium Slate Grey
  ];

  static ExpenseCategory fromName(String name) {
    // Look up in predefined list case-insensitively
    final exactMatch = list.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => const ExpenseCategory(name: '', emoji: '', color: Colors.transparent), // Placeholder
    );
    
    if (exactMatch.name.isNotEmpty) {
      return exactMatch;
    }

    // Dynamic resolution for custom user-typed categories
    return ExpenseCategory(
      name: name,
      emoji: '🏷️', // Default elegant tag emoji for custom classifications
      color: const Color(0xFF90A4AE), // Classy slate-silver
      isExpense: true, // Custom categories default to expenses
    );
  }
}

class Expense {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String? ?? 'Other',
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String? ?? 'Other',
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
    );
  }

  ExpenseCategory get categoryInfo => ExpenseCategory.fromName(category);
}
