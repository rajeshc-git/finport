import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finport/models/expense.dart';
import 'package:finport/widgets/glass_card.dart';
import 'package:finport/widgets/custom_charts.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends StatefulWidget {
  final List<Expense> expenses;

  const InsightsScreen({super.key, required this.expenses});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late DateTime _selectedMonth;
  late List<DateTime> _recentMonths;

  @override
  void initState() {
    super.initState();
    _recentMonths = _generateRecentMonths();
    _selectedMonth = _recentMonths.first; // Default to current month
  }

  List<DateTime> _generateRecentMonths() {
    final now = DateTime.now();
    // FIXED: Dynamically generate the last 24 months (2 years) instead of just 6 months
    return List.generate(24, (i) {
      return DateTime(now.year, now.month - i, 1);
    });
  }

  // Filter expenses based on the selected month (excluding transfers for accurate spending waves)
  List<Expense> _getFilteredExpenses() {
    final String targetYearMonth = DateFormat('yyyy-MM').format(_selectedMonth);
    return widget.expenses.where((e) {
      return DateFormat('yyyy-MM').format(e.date) == targetYearMonth && e.categoryInfo.isExpense;
    }).toList();
  }

  // Generate spending trend array (Y-values) for each day of the selected month
  List<double> _generateDailySpends(List<Expense> filteredExpenses) {
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final List<double> dailySpends = List.filled(lastDay, 0.0);

    for (var expense in filteredExpenses) {
      final day = expense.date.day;
      if (day >= 1 && day <= lastDay) {
        dailySpends[day - 1] += expense.amount;
      }
    }
    
    if (dailySpends.every((val) => val == 0.0)) {
      return List.filled(7, 0.0);
    }
    
    return dailySpends;
  }

  // Generate Map of Category -> Total Amount for Donut Chart
  Map<String, double> _generateCategoryData(List<Expense> filteredExpenses) {
    final Map<String, double> data = {};
    for (var cat in ExpenseCategory.list) {
      data[cat.name] = 0.0;
    }

    for (var expense in filteredExpenses) {
      data[expense.category] = (data[expense.category] ?? 0.0) + expense.amount;
    }
    
    data.removeWhere((key, value) => value <= 0.0);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _getFilteredExpenses();
    final dailySpends = _generateDailySpends(filteredExpenses);
    final categoryData = _generateCategoryData(filteredExpenses);
    final totalSpent = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Adaptive Theme Palette configurations
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subColor = isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF8E8E93);
    
    final elementBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
    final elementBorder = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Navigation Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: elementBg,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: elementBorder),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 16),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'INSIGHTS & TRENDS',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 42), // Align header title correctly
                ],
              ),
            ),

            // Horizontal Month Slider
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _recentMonths.length,
                itemBuilder: (context, index) {
                  final monthDate = _recentMonths[index];
                  final isSelected = DateFormat('yyyy-MM').format(_selectedMonth) ==
                      DateFormat('yyyy-MM').format(monthDate);
                  
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMonth = monthDate;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C5DD3)
                            : elementBg,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6C5DD3)
                              : elementBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          DateFormat('MMM yyyy').format(monthDate),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Main scrollable graphs content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bezier Spending Wave
                    Text(
                      'DAILY SPENDING TREND',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent Wave',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Peak day: ₹${NumberFormat('#,##,###').format(dailySpends.reduce((a, b) => a > b ? a : b))}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: subColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PremiumBezierChart(
                            dailySpends: dailySpends,
                            height: 140,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Donut Chart Segment Distribution
                    Text(
                      'CATEGORY SPEND SHARE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Column(
                        children: [
                          PremiumDonutChart(
                            categoryData: categoryData,
                            height: 160,
                          ),
                          
                          if (categoryData.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12.0,
                              runSpacing: 8.0,
                              alignment: WrapAlignment.center,
                              children: categoryData.keys.map((catName) {
                                final cat = ExpenseCategory.fromName(catName);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: cat.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${cat.emoji} ${cat.name}',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: textColor.withOpacity(0.7),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Leaderboard progress list
                    Text(
                      'DETAILED CATEGORY SUMMARY',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    filteredExpenses.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Text(
                              'No spends in this month.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: subColor,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categoryData.length,
                            itemBuilder: (context, index) {
                              final sortedEntries = categoryData.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value));

                              final entry = sortedEntries[index];
                              final cat = ExpenseCategory.fromName(entry.key);
                              final value = entry.value;
                              final fraction = totalSpent > 0 ? (value / totalSpent) : 0.0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                                              const SizedBox(width: 10),
                                              Text(
                                                cat.name,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₹${NumberFormat('#,##,###.00').format(value)}',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                ),
                                              ),
                                              Text(
                                                '${(fraction * 100).toStringAsFixed(1)}% share',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 10,
                                                  color: subColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: elementBg,
                                              borderRadius: BorderRadius.circular(10.0),
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 600),
                                            curve: Curves.easeOut,
                                            height: 6,
                                            width: MediaQuery.of(context).size.width *
                                                0.72 *
                                                fraction,
                                            decoration: BoxDecoration(
                                              color: cat.color,
                                              borderRadius: BorderRadius.circular(10.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: cat.color.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
