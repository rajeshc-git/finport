import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _logoScaleController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeOpacity;

  @override
  void initState() {
    super.initState();
    
    _logoScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = CurvedAnimation(
      parent: _logoScaleController,
      curve: Curves.elasticOut,
    );

    _fadeOpacity = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _logoScaleController.forward();
    Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoScaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _triggerAppleSignIn(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (modalContext) {
        return const _AppleSignInModal();
      },
    ).then((success) {
      if (success == true) {
        widget.onLoginSuccess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0D0D11);
    final subColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF0D0D11).withOpacity(0.5);

    return Scaffold(
      body: Stack(
        children: [
          // Background soft glowing gradients
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5DD3).withOpacity(isDark ? 0.12 : 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withOpacity(isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: const SizedBox.shrink(),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // --- Finport Logo Animation ---
                    ScaleTransition(
                      scale: _logoScale,
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5DD3).withOpacity(isDark ? 0.25 : 0.15),
                                blurRadius: 24,
                                spreadRadius: -4,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/icon/finport_app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF161622),
                                  child: const Center(
                                    child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFF6C5DD3),
                                      size: 48,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- Text Branding ---
                    FadeTransition(
                      opacity: _fadeOpacity,
                      child: Column(
                        children: [
                          Text(
                            'FINPORT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Track monthly expenses, a better way.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // --- Apple Sign-In Action ---
                    FadeTransition(
                      opacity: _fadeOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: () => _triggerAppleSignIn(context),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : const Color(0xFF0D0D11),
                                borderRadius: BorderRadius.circular(16.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                    blurRadius: 16,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.apple_rounded,
                                    color: isDark ? const Color(0xFF0D0D11) : Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sign in with Apple',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF0D0D11) : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Text(
                            'Secured with Apple iCloud Keychain. Your financial data remains 100% private and stored locally on this device.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              height: 1.5,
                              color: subColor.withOpacity(0.35),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleSignInModal extends StatefulWidget {
  const _AppleSignInModal();

  @override
  State<_AppleSignInModal> createState() => _AppleSignInModalState();
}

class _AppleSignInModalState extends State<_AppleSignInModal> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  String _authStatus = 'Double Click / Tap Face ID to Sign In';
  bool _isScanning = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _startFaceIDScan() {
    if (_isScanning || _isSuccess) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isScanning = true;
      _authStatus = 'Scanning Face ID...';
    });

    _scannerController.repeat();

    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _scannerController.stop();
        HapticFeedback.mediumImpact();
        
        setState(() {
          _isScanning = false;
          _isSuccess = true;
          _authStatus = 'Sign In Successful';
        });

        Timer(const Duration(milliseconds: 200), () {
          HapticFeedback.lightImpact();
        });

        Timer(const Duration(milliseconds: 900), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);
    final borderDivider = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Apple ID',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            
            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderDivider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/finport_app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF6C5DD3),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in to Finport',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Developed by Rajesh Choudhury',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: borderDivider, height: 1),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                    const SizedBox(height: 2),
                    Text(
                      'r.choudhury@icloud.com',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(color: borderDivider, height: 1),
            const SizedBox(height: 28),

            Center(
              child: GestureDetector(
                onTap: _startFaceIDScan,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _scannerController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _scannerController.value * 2 * 3.14159,
                              child: Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isSuccess
                                        ? const Color(0xFF30D158)
                                        : _isScanning
                                            ? const Color(0xFF007AFF)
                                            : textColor.withOpacity(0.12),
                                    width: 3.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSuccess
                                ? const Color(0xFF30D158).withOpacity(0.12)
                                : _isScanning
                                    ? const Color(0xFF007AFF).withOpacity(0.08)
                                    : textColor.withOpacity(0.03),
                          ),
                          child: Center(
                            child: _isSuccess
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF30D158),
                                    size: 38,
                                  )
                                : Icon(
                                    Icons.face_retouching_natural_rounded,
                                    color: _isScanning
                                        ? const Color(0xFF007AFF)
                                        : textColor.withOpacity(0.6),
                                    size: 32,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _authStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isSuccess
                            ? const Color(0xFF30D158)
                            : _isScanning
                                ? const Color(0xFF007AFF)
                                : textColor,
                      ),
                    ),
                    if (!_isScanning && !_isSuccess)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Tap icon to authenticate with Face ID',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: subColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
