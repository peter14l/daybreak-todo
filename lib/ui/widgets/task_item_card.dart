import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/state/providers.dart';

class TaskItemCard extends ConsumerWidget {
  final Task task;

  const TaskItemCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskService = ref.read(taskServiceProvider);

    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          taskService.toggleTaskCompletion(task.id, !task.isCompleted);
        } else {
          taskService.deleteTask(task.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: task.isCompleted
                ? colorScheme.outlineVariant.withAlpha(60)
                : colorScheme.outlineVariant.withAlpha(120),
          ),
        ),
        color: task.isCompleted
            ? colorScheme.surfaceContainerLowest
            : colorScheme.surfaceContainerLow,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            taskService.toggleTaskCompletion(task.id, !task.isCompleted);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Completion Checkbox
                Checkbox(
                  value: task.isCompleted,
                  shape: const CircleBorder(),
                  activeColor: colorScheme.primary,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    taskService.toggleTaskCompletion(task.id, val ?? false);
                  },
                ),
                const SizedBox(width: 8),

                // Title and badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? colorScheme.onSurfaceVariant.withAlpha(140)
                              : colorScheme.onSurface,
                          fontWeight: task.isImportant
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (task.notes.isNotEmpty ||
                          task.dueDate != null ||
                          task.isMyDay) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (task.isMyDay)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wb_sunny_outlined,
                                      size: 12, color: Colors.orange.shade700),
                                  const SizedBox(width: 3),
                                  Text(
                                    'My Day',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            if (task.dueDate != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 12, color: colorScheme.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('MMM d').format(task.dueDate!),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            if (task.recurrenceRule != null &&
                                task.recurrenceRule!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat,
                                      size: 12, color: colorScheme.secondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.recurrenceRule!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Importance star
                IconButton(
                  icon: Icon(
                    task.isImportant ? Icons.star : Icons.star_border,
                    color: task.isImportant
                        ? Colors.amber.shade700
                        : colorScheme.outline,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    taskService.toggleImportance(task.id, !task.isImportant);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
