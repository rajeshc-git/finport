import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finport/models/expense.dart';
import 'package:intl/intl.dart';

class AddExpenseSheet extends StatefulWidget {
  final Function(Expense) onSave;

  const AddExpenseSheet({super.key, required this.onSave});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String _amountStr = '0';
  String _selectedCategory = 'Groceries'; // Default to first curated item
  DateTime _selectedDate = DateTime.now();
  
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  
  bool _isOtherSelected = false;
  bool _isSaving = false;

  void _onKeyPress(String value) {
    HapticFeedback.lightImpact(); // Apple haptic click simulation
    
    setState(() {
      if (value == '⌫') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (value == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else {
        if (_amountStr.contains('.')) {
          final parts = _amountStr.split('.');
          if (parts.length > 1 && parts[1].length >= 2) {
            return; // Impose standard hundredths decimal limit
          }
        }
        
        if (_amountStr == '0') {
          _amountStr = value;
        } else {
          _amountStr += value;
        }
      }
    });
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C5DD3),
              onPrimary: Colors.white,
              surface: Color(0xFF161622),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0D0D11),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitExpense() {
    final amount = double.tryParse(_amountStr) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter a valid amount.',
            style: TextStyle(fontFamily: 'Outfit', color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Resolve category name (use typed custom category if "Other" was active)
    String finalCategory = _selectedCategory;
    if (_isOtherSelected) {
      final customName = _customCategoryController.text.trim();
      if (customName.isNotEmpty) {
        finalCategory = customName;
      } else {
        finalCategory = 'Other';
      }
    }

    setState(() {
      _isSaving = true;
    });

    final expense = Expense(
      amount: amount,
      category: finalCategory,
      date: _selectedDate,
      note: _noteController.text.trim(),
    );

    widget.onSave(expense);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.of(context).viewInsets.bottom;
    final isSelfTransfer = _selectedCategory == 'Self Transfer';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium dynamic color system for Light & Dark mode compatibility
    final sheetBg = isDark ? const Color(0xFF0D0D11) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0D0D11);
    final subColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF0D0D11).withOpacity(0.5);
    final hintColor = isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF0D0D11).withOpacity(0.3);
    final elementBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFF0D0D11).withOpacity(0.04);
    final elementBorder = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFF0D0D11).withOpacity(0.08);
    final dragIndicatorColor = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFF0D0D11).withOpacity(0.15);

    return Container(
      padding: EdgeInsets.only(bottom: paddingBottom),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Slide indicator
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: dragIndicatorColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),

            // Smart Badge: Translucent glowing alert for Transfer category (isExpense = false)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelfTransfer
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBF5AF2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFBF5AF2).withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔄', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Self Transfer: Logged in history, does not affect spent limits.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFE8D5FF) : const Color(0xFF7F39FB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            
            // Numerical Display Hero
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isSelfTransfer ? 'TRANSFER AMOUNT' : 'SPENT AMOUNT',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: isSelfTransfer
                          ? const Color(0xFFBF5AF2).withOpacity(0.8)
                          : textColor.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹$_amountStr',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Curated category selector scroll row
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: ExpenseCategory.list.length,
                itemBuilder: (context, index) {
                  final cat = ExpenseCategory.list[index];
                  final isSelected = _selectedCategory == cat.name;
                  
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = cat.name;
                        _isOtherSelected = cat.name == 'Other';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withOpacity(isDark ? 0.15 : 0.12)
                            : elementBg,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: isSelected
                              ? cat.color.withOpacity(0.6)
                              : elementBorder,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: cat.color.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? textColor : subColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Custom Category Input TextField (Animated expansion when "Other" is chosen)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isOtherSelected
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        decoration: BoxDecoration(
                          color: elementBg,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: elementBorder),
                        ),
                        child: TextField(
                          controller: _customCategoryController,
                          autofocus: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            icon: const Text('🏷️', style: TextStyle(fontSize: 16)),
                            hintText: 'Enter custom category name...',
                            hintStyle: TextStyle(
                              fontFamily: 'Outfit',
                              color: hintColor,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Inline Date & Note inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: GestureDetector(
                      onTap: () => _selectCustomDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: elementBg,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: elementBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14, color: subColor),
                            Text(
                              DateFormat('dd MMM').format(_selectedDate),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: elementBg,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: elementBorder),
                      ),
                      child: TextField(
                        controller: _noteController,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a note...',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            color: hintColor,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Custom borderless numeric keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  _buildKeyboardRow(context, ['1', '2', '3']),
                  _buildKeyboardRow(context, ['4', '5', '6']),
                  _buildKeyboardRow(context, ['7', '8', '9']),
                  _buildKeyboardRow(context, ['.', '0', '⌫']),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Premium Tactile Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: GestureDetector(
                onTap: _submitExpense,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSaving
                          ? [const Color(0xFF30D158), const Color(0xFF34D399)]
                          : [const Color(0xFF6C5DD3), const Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(18.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5DD3).withOpacity(_isSaving ? 0 : 0.35),
                        blurRadius: 20,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28)
                        : const Text(
                            'Save Transaction',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(BuildContext context, List<String> keys) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyTextColor = isDark ? Colors.white : const Color(0xFF0D0D11);
    final specialKeyTextColor = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF0D0D11).withOpacity(0.55);
    final keyboardSplash = const Color(0xFF6C5DD3).withOpacity(isDark ? 0.15 : 0.1);
    final keyboardHighlight = const Color(0xFF6C5DD3).withOpacity(isDark ? 0.08 : 0.05);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        final isSpecial = key == '.' || key == '⌫';
        return Expanded(
          child: AspectRatio(
            aspectRatio: 2.1,
            child: Container(
              margin: const EdgeInsets.all(4.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onKeyPress(key),
                  borderRadius: BorderRadius.circular(16.0),
                  splashColor: keyboardSplash,
                  highlightColor: keyboardHighlight,
                  child: Center(
                    child: key == '⌫'
                        ? Icon(Icons.backspace_outlined, color: keyTextColor, size: 20)
                        : Text(
                            key,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: isSpecial ? FontWeight.w500 : FontWeight.bold,
                              color: isSpecial ? specialKeyTextColor : keyTextColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
