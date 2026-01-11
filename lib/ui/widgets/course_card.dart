import 'package:flutter/material.dart';

class CourseCardData {
  const CourseCardData({
    required this.title,
    required this.category,
    required this.remaining,
    required this.total,
    required this.nextLessonLabel,
    this.isExpiring = false,
  });

  final String title;
  final String category;
  final double remaining;
  final double total;
  final String nextLessonLabel;
  final bool isExpiring;
}

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final CourseCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (data.total <= 0)
        ? 0.0
        : (1 - (data.remaining / data.total)).clamp(0.0, 1.0);
    final remainingText = _formatLessonCount(data.remaining);
    final totalText = _formatLessonCount(data.total);

    final statusColor =
        data.isExpiring ? theme.colorScheme.error : theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForCategory(data.category),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label: data.category,
                              background: theme.colorScheme.secondaryContainer,
                              foreground:
                                  theme.colorScheme.onSecondaryContainer,
                            ),
                            if (data.isExpiring)
                              _Chip(
                                label: '即将到期',
                                background: theme.colorScheme.errorContainer,
                                foreground: theme.colorScheme.onErrorContainer,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '剩余 $remainingText / $totalText 课时',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.nextLessonLabel,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case '艺术':
      case '绘画':
        return Icons.palette_outlined;
      case '音乐':
      case '钢琴':
        return Icons.piano_outlined;
      case '运动':
      case '足球':
        return Icons.sports_soccer_outlined;
      case '学科':
      case '英语':
        return Icons.menu_book_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  static String _formatLessonCount(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
