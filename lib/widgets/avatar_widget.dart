import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final String email;
  final double size;

  const AvatarWidget({
    super.key,
    required this.name,
    required this.email,
    this.size = 44,
  });

  String get _initials {
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  List<Color> get _gradient {
    final hash = email.hashCode.abs();
    final hue1 = (hash % 360).toDouble();
    final hue2 = ((hash + 60) % 360).toDouble();
    return [
      HSLColor.fromAHSL(1.0, hue1, 0.7, 0.45).toColor(),
      HSLColor.fromAHSL(1.0, hue2, 0.8, 0.55).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _gradient.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
