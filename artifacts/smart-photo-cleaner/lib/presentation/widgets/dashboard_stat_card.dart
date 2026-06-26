import 'package:flutter/material.dart';

/// Tappable stat card for the dashboard category grid.
class DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      count;
  final Color    iconColor;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: count > 0 ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Spacer(),
                  if (count > 0)
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant, size: 18),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count > 0 ? '$count' : '—',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: count > 0 ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    label,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
