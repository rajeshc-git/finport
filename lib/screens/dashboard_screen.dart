import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finport/models/expense.dart';
import 'package:finport/database/database_helper.dart';
import 'package:finport/widgets/glass_card.dart';
import 'package:finport/widgets/add_expense_sheet.dart';
import 'package:finport/screens/insights_screen.dart';
import 'package:finport/screens/settings_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Expense> _allExpenses = [];
  bool _isLoading = true;
  bool _isGridView = false; // Layout toggle state: False = List, True = Grid
  double _monthlyBudget = 50000.0; // Default budget in INR

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    
    setState(() {
      _allExpenses = expenses;
      _isLoading = false;
    });
  }

  void _updateBudget(double newBudget) {
    setState(() {
      _monthlyBudget = newBudget;
    });
  }

  double get _totalSpentThisMonth {
    final now = DateTime.now();
    final currentYearMonth = DateFormat('yyyy-MM').format(now);
    
    return _allExpenses
        .where((e) => DateFormat('yyyy-MM').format(e.date) == currentYearMonth && e.categoryInfo.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  void _saveExpense(Expense expense) async {
    await DatabaseHelper.instance.insertExpense(expense);
    _refreshData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF30D158), size: 20),
              const SizedBox(width: 8),
              Text(
                'Expense added: ₹${NumberFormat('#,##,###.##').format(expense.amount)}',
                style: const TextStyle(fontFamily: 'Outfit', color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF161622),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _refreshData();
  }

  void _openAddExpenseSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(onSave: _saveExpense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _totalSpentThisMonth;
    final percentSpent = _monthlyBudget > 0 ? (totalSpent / _monthlyBudget) : 0.0;
    final currentYearMonthName = DateFormat('MMMM yyyy').format(DateTime.now());

    // Adaptive Theme Palette configurations
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subColor = isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF8E8E93);
    
    final elementBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
    final elementBorder = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);
    final trackColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5DD3)))
            : RefreshIndicator(
                color: const Color(0xFF6C5DD3),
                backgroundColor: Theme.of(context).colorScheme.surface,
                onRefresh: _refreshData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Header Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FINPORT',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: [Color(0xFF6C5DD3), Color(0xFF00F2FE)],
                                      ).createShader(const Rect.fromLTWH(0, 0, 150, 20)),
                                  ),
                                ),
                                Text(
                                  currentYearMonthName,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Insights Navigation
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InsightsScreen(expenses: _allExpenses),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: elementBg,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(color: elementBorder),
                                    ),
                                    child: Icon(Icons.bar_chart_rounded, color: textColor, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Settings Navigation
                                GestureDetector(
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    final updatedBudget = await Navigator.push<double>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SettingsScreen(
                                          currentBudget: _monthlyBudget,
                                          onDataRestored: _refreshData,
                                        ),
                                      ),
                                    );
                                    if (updatedBudget != null) {
                                      _updateBudget(updatedBudget);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: elementBg,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(color: elementBorder),
                                    ),
                                    child: Icon(Icons.settings_outlined, color: textColor, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Budget Progress circular ring card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: GlassCard(
                          child: Row(
                            children: [
                              // Circular ring
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 9,
                                      valueColor: AlwaysStoppedAnimation<Color>(trackColor),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: CircularProgressIndicator(
                                      value: percentSpent.clamp(0.0, 1.0),
                                      strokeWidth: 9,
                                      strokeCap: StrokeCap.round,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        percentSpent > 1.0
                                            ? const Color(0xFFFF5A79)
                                            : const Color(0xFF6C5DD3),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'SPENT',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: subColor,
                                          fontSize: 8,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${(percentSpent * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: textColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              // Statistical texts
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Spent this Month',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: subColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${NumberFormat('#,##,###').format(totalSpent)}',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: textColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: elementBg,
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Text(
                                        'Limit: ₹${NumberFormat('#,##,###').format(_monthlyBudget)}',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: textColor.withOpacity(0.7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Transaction List & Layout Toggle Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT Expenses'.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: subColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(2.0),
                              decoration: BoxDecoration(
                                color: elementBg,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: elementBorder),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_isGridView) {
                                        HapticFeedback.selectionClick();
                                        setState(() => _isGridView = false);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: !_isGridView
                                            ? const Color(0xFF6C5DD3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Icon(
                                        Icons.format_list_bulleted_rounded,
                                        color: !_isGridView ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (!_isGridView) {
                                        HapticFeedback.selectionClick();
                                        setState(() => _isGridView = true);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _isGridView
                                            ? const Color(0xFF6C5DD3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Icon(
                                        Icons.grid_view_rounded,
                                        color: _isGridView ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Main Expenses feed
                    _allExpenses.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '📦',
                                    style: TextStyle(
                                        fontSize: 48, color: textColor.withOpacity(0.2)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No expenses logged yet.',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      color: subColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the + button below to log spent.',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12,
                                      color: subColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                            sliver: _isGridView ? _buildGridView(textColor, subColor, isDark) : _buildListView(textColor, subColor),
                          ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseSheet,
        backgroundColor: const Color(0xFF6C5DD3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5DD3), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5DD3).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- RENDERS TRANSITIONS VIEWS ---

  Widget _buildListView(Color textColor, Color subColor) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = _allExpenses[index];
          final cat = expense.categoryInfo;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Dismissible(
              key: Key('expense_${expense.id}'),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _deleteExpense(expense.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Expense deleted.',
                      style: TextStyle(fontFamily: 'Outfit'),
                    ),
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              ),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: cat.color.withOpacity(0.2), width: 1.2),
                      ),
                      child: Center(
                        child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            expense.note.isEmpty
                                ? DateFormat('dd MMMM, hh:mm a').format(expense.date)
                                : expense.note,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: subColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${cat.isExpense ? "-₹" : "₹"}${NumberFormat('#,##,###.00').format(expense.amount)}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cat.isExpense 
                            ? textColor.withOpacity(0.95)
                            : const Color(0xFFBF5AF2), // Glowing purple for transfers
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: _allExpenses.length,
      ),
    );
  }

  Widget _buildGridView(Color textColor, Color subColor, bool isDark) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = _allExpenses[index];
          final cat = expense.categoryInfo;

          return GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text(
                    'Delete Transaction',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 18),
                  ),
                  content: Text(
                    'Are you sure you want to remove this transaction of ₹${expense.amount}?',
                    style: const TextStyle(fontFamily: 'Outfit'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: textColor.withOpacity(0.4))),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteExpense(expense.id!);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
            child: GlassCard(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM').format(expense.date),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          color: subColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${cat.isExpense ? "-₹" : "₹"}${NumberFormat('#,##,###').format(expense.amount)}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: cat.isExpense ? textColor : const Color(0xFFBF5AF2), // Purple for self transfers
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expense.note.isEmpty ? 'Spent' : expense.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          color: subColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: _allExpenses.length,
      ),
    );
  }
}
