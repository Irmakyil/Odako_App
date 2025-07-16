import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TaskTile extends StatelessWidget {
  final String title;
  final String? time;
  final bool isCompleted;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? type;

  const TaskTile({
    super.key,
    required this.title,
    this.time,
    required this.isCompleted,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.type,
  });

  Color _getTypeColor() {
    switch (type) {
      case 'morning':
        return AppTheme.softYellow;
      case 'focus':
        return AppTheme.primaryBlue;
      case 'break':
        return AppTheme.calmGreen;
      case 'activity':
        return AppTheme.gentleOrange;
      default:
        return AppTheme.mediumGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding,
        vertical: AppTheme.smallPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: AppTheme.cardShadow,
                  border: Border.all(
            color: _getTypeColor().withValues(alpha: 0.3),
            width: 1,
          ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.padding,
          vertical: AppTheme.smallPadding,
        ),
        leading: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? _getTypeColor() : Colors.transparent,
              border: Border.all(
                color: isCompleted ? _getTypeColor() : AppTheme.darkGray,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isCompleted ? AppTheme.darkGray : AppTheme.textDark,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: time != null
            ? Text(
                time!,
                style: AppTheme.bodySmall.copyWith(
                  color: _getTypeColor(),
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.darkGray,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
