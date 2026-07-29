import 'package:flutter/material.dart';

/// Rivox color palette — a modern dark theme with electric blue accents.
///
/// Design philosophy:
/// - Deep navy backgrounds for immersive map viewing
/// - Electric blue/cyan accents for interactive elements and routes
/// - Warm orange for user avatar and important markers
/// - Subtle grays for secondary content
abstract final class AppColors {
  // ─── Primary Palette ───
  static const Color primary = Color(0xFF1E90FF);        // Electric blue
  static const Color primaryLight = Color(0xFF63B3FF);
  static const Color primaryDark = Color(0xFF0A6DDB);

  // ─── Accent / Secondary ───
  static const Color accent = Color(0xFF00E5FF);          // Cyan
  static const Color accentLight = Color(0xFF6EFFFF);
  static const Color accentDark = Color(0xFF00B2CC);

  // ─── Background Surfaces (Dark Theme) ───
  static const Color background = Color(0xFF0A0E1A);      // Deep navy
  static const Color surface = Color(0xFF111827);          // Card background
  static const Color surfaceVariant = Color(0xFF1A2332);   // Elevated surface
  static const Color surfaceHigh = Color(0xFF232D3F);      // Highest elevation
  static const Color surfaceBright = Color(0xFF2A3548);    // Bright surface

  // ─── Map-specific Colors ───
  static const Color mapBackground = Color(0xFF080C16);    // Map canvas bg
  static const Color mapGrid = Color(0xFF1A2332);          // Grid lines
  static const Color mapWall = Color(0xFF4A5568);          // Wall outlines
  static const Color mapRoom = Color(0xFF1A2332);          // Room fill
  static const Color mapRoomLabel = Color(0xFF94A3B8);     // Room text
  static const Color routePath = Color(0xFF00E5FF);        // Navigation route
  static const Color routePathGlow = Color(0x4000E5FF);    // Route glow
  static const Color avatarColor = Color(0xFFFF6B35);      // User avatar
  static const Color avatarGlow = Color(0x40FF6B35);       // Avatar pulse glow
  static const Color destinationMarker = Color(0xFFFF3366); // Destination pin

  // ─── Navigation Node Types ───
  static const Color nodeRoom = Color(0xFF4A9EFF);
  static const Color nodeCorridor = Color(0xFF6B7280);
  static const Color nodeStairs = Color(0xFFFFB347);
  static const Color nodeElevator = Color(0xFF9B59B6);
  static const Color nodeEntrance = Color(0xFF2ECC71);
  static const Color nodeRestroom = Color(0xFF3498DB);
  static const Color nodeCafeteria = Color(0xFFE74C3C);

  // ─── Text ───
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Status ───
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Borders & Dividers ───
  static const Color border = Color(0xFF1F2937);
  static const Color borderLight = Color(0xFF374151);
  static const Color divider = Color(0xFF1F2937);

  // ─── Glassmorphism ───
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // ─── Shadows ───
  static const Color shadow = Color(0x40000000);
  static const Color shadowLight = Color(0x20000000);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceVariant, surface],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF0F172A), Color(0xFF0A0E1A)],
  );

  static const RadialGradient avatarRadialGlow = RadialGradient(
    colors: [avatarColor, Color(0x00FF6B35)],
    radius: 0.8,
  );
}
