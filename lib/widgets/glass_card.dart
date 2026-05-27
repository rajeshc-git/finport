import 'dart:ui';
import 'package:flutter/material.dart';

/// An ultra-premium, glassmorphic card container utilizing iOS-style background blurs,
/// fine-tuned inner gradients, and precise border strokes to deliver a premium dashboard layout.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final Color borderColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.05,
    this.color = Colors.white,
    this.borderColor = const Color(0x11FFFFFF), // Subtle translucent border
    this.borderRadius = const BorderRadius.all(Radius.circular(24.0)),
    this.padding = const EdgeInsets.all(20.0),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic styling based on current theme brightness
    final activeColor = isDark ? color : Colors.white;
    final activeOpacity = isDark ? opacity : 0.75; // More opaque white in light mode for separation
    final activeBorderColor = isDark 
        ? borderColor 
        : const Color(0x13000000); // Super subtle dark border for light mode
    
    final activeShadowColor = isDark 
        ? Colors.black.withAlpha(50) 
        : Colors.black.withAlpha(20);

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: activeShadowColor,
              blurRadius: 30,
              spreadRadius: -10,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(activeOpacity),
              borderRadius: borderRadius,
              border: Border.all(
                color: activeBorderColor,
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  activeColor.withOpacity((activeOpacity * 1.5).clamp(0.0, 1.0)),
                  activeColor.withOpacity((activeOpacity * 0.4).clamp(0.0, 1.0)),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}
}
