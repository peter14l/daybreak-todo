import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/services/audio_feedback_service.dart';
import '../../core/state/providers.dart';
import '../../core/theme/theme_provider.dart';

class TaskItemCard extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskItemCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  ConsumerState<TaskItemCard> createState() => _TaskItemCardState();
}

class _TaskItemCardState extends ConsumerState<TaskItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final appTheme = ref.watch(currentThemeProvider);
    final taskService = ref.read(taskServiceProvider);

    final cardBg = task.isCompleted
        ? appTheme.surfaceCompleted
        : (_isHovered ? appTheme.surfaceHover : appTheme.surface);

    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.8),
          borderRadius: appTheme.borderRadius,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: appTheme.borderRadius,
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          AudioFeedbackService.playTaskCompletion();
          taskService.toggleTaskCompletion(task.id, !task.isCompleted);
        } else {
          HapticFeedback.mediumImpact();
          taskService.deleteTask(task.id);
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: appTheme.borderRadius,
            border: Border.all(
              color: _isHovered
                  ? appTheme.accentColor.withValues(alpha: 0.4)
                  : appTheme.borderColor,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: appTheme.borderRadius,
            child: InkWell(
              borderRadius: appTheme.borderRadius,
              onTap: widget.onTap ??
                  () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedTaskIdProvider.notifier).state = task.id;
                  },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Styled tactile checkbox
                    GestureDetector(
                      onTap: () {
                        AudioFeedbackService.playTaskCompletion();
                        taskService.toggleTaskCompletion(
                            task.id, !task.isCompleted);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? appTheme.accentColor
                              : Colors.transparent,
                          borderRadius: appTheme.checkboxBorderRadius,
                          border: Border.all(
                            color: task.isCompleted
                                ? appTheme.accentColor
                                : (_isHovered
                                    ? appTheme.accentColor
                                    : appTheme.checkboxBorderColor),
                            width: 1.5,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 13,
                                color: Color(0xFF121212),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Task title & meta tags
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: appTheme.textMutedColor,
                              color: task.isCompleted
                                  ? appTheme.textMutedColor
                                  : appTheme.textColor,
                              fontSize: 14,
                              fontWeight: task.isImportant
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (task.notes.isNotEmpty ||
                              task.dueDate != null ||
                              task.isMyDay ||
                              (task.recurrenceRule != null &&
                                  task.recurrenceRule!.isNotEmpty)) ...[
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (task.isMyDay)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: appTheme.accentColor
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: appTheme.accentColor
                                            .withValues(alpha: 0.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.wb_sunny_rounded,
                                          size: 11,
                                          color: appTheme.accentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'My Day',
                                          style: TextStyle(
                                            color: appTheme.accentColor,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (task.dueDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: appTheme.borderColor
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 11,
                                          color: appTheme.textMutedColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM d')
                                              .format(task.dueDate!),
                                          style: TextStyle(
                                            color: appTheme.textMutedColor,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (task.recurrenceRule != null &&
                                    task.recurrenceRule!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: appTheme.borderColor
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.repeat,
                                          size: 11,
                                          color: appTheme.textMutedColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.recurrenceRule!,
                                          style: TextStyle(
                                            color: appTheme.textMutedColor,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Importance Star Button
                    IconButton(
                      icon: Icon(
                        task.isImportant ? Icons.star : Icons.star_border,
                        color: task.isImportant
                            ? appTheme.accentColor
                            : appTheme.textMutedColor.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        taskService.toggleImportance(
                            task.id, !task.isImportant);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
