import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// "Best Photo" badge displayed on the recommended photo in a group.
class BestPhotoBadge extends StatelessWidget {
  final bool compact;
  const BestPhotoBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    );

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          '⭐ Best',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Best Photo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut);
  }
}
