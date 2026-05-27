import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finport/main.dart';
import 'package:finport/database/database_helper.dart';
import 'package:finport/widgets/glass_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  final double currentBudget;
  final VoidCallback onDataRestored;

  const SettingsScreen({
    super.key,
    required this.currentBudget,
    required this.onDataRestored,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _budget;
  final TextEditingController _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _budget = widget.currentBudget;
    _budgetController.text = _budget.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _showBudgetDialog(Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        title: Text(
          'Set Monthly Budget Limit',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.04) 
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.06) 
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            style: TextStyle(fontFamily: 'Outfit', color: textColor),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xFF6C5DD3),
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              hintText: 'Enter monthly cap',
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                color: textColor.withOpacity(0.3),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor.withOpacity(0.4), fontFamily: 'Outfit')),
          ),
          TextButton(
            onPressed: () {
              final newBudget = double.tryParse(_budgetController.text) ?? 0.0;
              if (newBudget > 0) {
                setState(() {
                  _budget = newBudget;
                });
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Budget updated: ₹${NumberFormat('#,##,###').format(newBudget)}',
                      style: const TextStyle(fontFamily: 'Outfit'),
                    ),
                    backgroundColor: const Color(0xFF6C5DD3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF6C5DD3), 
                fontWeight: FontWeight.bold, 
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BACKUP GENERATOR (EXPORT) ---

  Future<void> _exportBackup() async {
    HapticFeedback.mediumImpact();
    
    try {
      final jsonString = await DatabaseHelper.instance.exportToJson();
      
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/finport_backup.json');
      await backupFile.writeAsString(jsonString);
      
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Finport Expenses Backup',
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Backup Export Failed', e.toString());
      }
    }
  }

  // --- BACKUP RESTORER (IMPORT) ---

  Future<void> _importBackup() async {
    HapticFeedback.heavyImpact();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        title: const Text(
          'Restore Local Database?',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Restoring backup will completely OVERWRITE your current local transaction history. This action is irreversible.',
          style: TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Restore Backup',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        return; 
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final success = await DatabaseHelper.instance.importFromJson(jsonString);

      if (success && mounted) {
        widget.onDataRestored(); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 20),
                SizedBox(width: 8),
                Text(
                  'Database restored successfully!',
                  style: TextStyle(fontFamily: 'Outfit', color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Color(0xFF161622),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Import Failure',
          'The selected backup file is corrupt or invalid. Ensure you choose a valid JSON backup exported from Finport.\n\nError: $e',
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Outfit', color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Outfit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(fontFamily: 'Outfit')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adaptive theme visual palette
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subColor = isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF8E8E93);

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
                      Navigator.pop(context, _budget); 
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 16),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'SETTINGS & BACKUP',
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
                  const SizedBox(width: 42),
                ],
              ),
            ),

            // Scrollable Settings Panel
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- 1. BUDGET CONTROL SECTION ---
                    Text(
                      'BUDGET CONTROL',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showBudgetDialog(textColor),
                      child: GlassCard(
                        // FIXED: Replaced unconstrained Row inside Row with Expanded layout to completely prevent overflow
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5DD3).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF6C5DD3), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Target',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to configure threshold limit',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${NumberFormat('#,##,###').format(_budget)}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- 2. APPEARANCE SWITCHER SECTION ---
                    Text(
                      'THEME MODE PREFERENCE',
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
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          _buildThemeSelector(context),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- 3. STORAGE & MANUAL BACKUP SECTION ---
                    Text(
                      'LOCAL STORAGE & MANUAL CLOUD BACKUP',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Backup Card
                    GestureDetector(
                      onTap: _exportBackup,
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF30D158).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_upload_outlined,
                                  color: Color(0xFF30D158), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manual Cloud Backup',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Export DB JSON to Google Drive or Files',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: textColor.withOpacity(0.2), size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Restore Card
                    GestureDetector(
                      onTap: _importBackup,
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_download_outlined,
                                  color: Colors.amberAccent, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Restore Manual Backup',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pick JSON file to wipe and reload database',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: textColor.withOpacity(0.2), size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- 4. APPLE ACCOUNT SECTION ---
                    Text(
                      'APPLE ACCOUNT',
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                ),
                                child: Icon(Icons.apple_rounded, color: textColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rajesh Choudhury',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'r.choudhury@icloud.com',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Sign Out', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                                    content: const Text('Are you sure you want to sign out of your Apple Account?', style: TextStyle(fontFamily: 'Outfit', fontSize: 14)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: Text('Cancel', style: TextStyle(fontFamily: 'Outfit', color: subColor)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          FinportApp.of(context)?.logout();
                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                        },
                                        child: const Text('Sign Out', style: TextStyle(fontFamily: 'Outfit', color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Sign Out of Apple ID',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- 5. DANGER ZONE ---
                    Text(
                      'DANGER ZONE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent.withOpacity(0.1),
                                ),
                                child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wipe All App Data',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Permanently delete SQLite tables and Secure Enclave backups',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Erase All Data?', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                    content: const Text(
                                      'This will permanently delete all transaction history from your local database AND erase your automatic iOS Secure Keychain backups. This action is 100% irreversible.',
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 14, height: 1.4),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: Text('Cancel', style: TextStyle(fontFamily: 'Outfit', color: subColor)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(dialogContext);
                                          HapticFeedback.heavyImpact();
                                          
                                          // Perform full database and secure keychain wipe
                                          await DatabaseHelper.instance.wipeAllData();
                                          
                                          // Notify parent screen to reload dashboard empty state
                                          widget.onDataRestored();
                                          
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'All data erased successfully.',
                                                  style: TextStyle(fontFamily: 'Outfit', color: Colors.white),
                                                ),
                                                backgroundColor: Colors.redAccent.withOpacity(0.85),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('Erase', style: TextStyle(fontFamily: 'Outfit', color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Erase All Data & Backups',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- 6. ABOUT SECTION ---
                    Text(
                      'ABOUT THE APP',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('📱', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text(
                                'Finport Daily Tracker v1.0.0',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This app is personally developed by Rajesh Choudhury to track his monthly expenses in a better way.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              height: 1.5,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- APPEARANCE SWITCHER GRAPHICS ---

  Widget _buildThemeSelector(BuildContext context) {
    final activeThemeMode = FinportApp.of(context)?.themeMode ?? ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeSegmentButton(context, ThemeMode.system, 'System', activeThemeMode),
          _buildThemeSegmentButton(context, ThemeMode.dark, 'Dark', activeThemeMode),
          _buildThemeSegmentButton(context, ThemeMode.light, 'Light', activeThemeMode),
        ],
      ),
    );
  }

  Widget _buildThemeSegmentButton(
    BuildContext context,
    ThemeMode value,
    String label,
    ThemeMode selectedValue,
  ) {
    final isSelected = value == selectedValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        FinportApp.of(context)?.setThemeMode(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5DD3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
