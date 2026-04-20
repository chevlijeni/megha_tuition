import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGradient = gradient != null;
    final Color textColor = isGradient ? Colors.white : AppTheme.textPrimary;
    final Color subTextColor = isGradient ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isGradient ? null : AppTheme.surfaceWhite,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: isGradient ? null : Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: isGradient 
             ? (gradient!.colors.first).withOpacity(0.3)
             : AppTheme.primaryBlue.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGradient ? Colors.white.withOpacity(0.2) : iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: isGradient ? Colors.white : iconColor, size: 22),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: subTextColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
