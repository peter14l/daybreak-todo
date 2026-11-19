import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/services/audio_feedback_service.dart';
import '../../core/state/providers.dart';
import '../../core/theme/theme_provider.dart';

class TaskDetailPanel extends ConsumerStatefulWidget {
  final String taskId;
  final VoidCallback onClose;

  const TaskDetailPanel({
    super.key,
    required this.taskId,
    required this.onClose,
  });

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  final TextEditingController _newStepController = TextEditingController();
  final FocusNode _newStepFocusNode = FocusNode();

  String? _loadedTaskId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _newStepController.dispose();
    _newStepFocusNode.dispose();
    super.dispose();
  }

  void _syncTask(Task task) {
    if (_loadedTaskId != task.id) {
      _loadedTaskId = task.id;
      _titleController.text = task.title;
      _notesController.text = task.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final taskAsync = ref.watch(singleTaskStreamProvider(widget.taskId));
    final subtasksAsync = ref.watch(taskSubtasksStreamProvider(widget.taskId));
    final listsAsync = ref.watch(allListsStreamProvider);
    final taskService = ref.read(taskServiceProvider);

    return taskAsync.when(
      data: (task) {
        if (task == null) {
          return Center(
            child: Text(
              'Task not found',
              style: TextStyle(color: theme.textMutedColor),
            ),
          );
        }
        _syncTask(task);

        return Container(
          color: theme.surface,
          child: Column(
            children: [
              // Panel Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.sidebarBackground,
                  border: Border(
                    bottom: BorderSide(color: theme.borderColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Completion checkbox
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
                              ? theme.accentColor
                              : Colors.transparent,
                          borderRadius: theme.checkboxBorderRadius,
                          border: Border.all(
                            color: task.isCompleted
                                ? theme.accentColor
                                : theme.textMutedColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check,
                                size: 14, color: Color(0xFF121212))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Important toggle star
                    IconButton(
                      icon: Icon(
                        task.isImportant ? Icons.star : Icons.star_border,
                        color: task.isImportant
                            ? Colors.amber
                            : theme.textMutedColor,
                        size: 20,
                      ),
                      onPressed: () {
                        taskService.toggleImportance(
                            task.id, !task.isImportant);
                      },
                    ),

                    const Spacer(),

                    // Close button
                    IconButton(
                      icon: Icon(Icons.close,
                          color: theme.textMutedColor, size: 18),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Scrollable body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    // Title editor
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Task Title',
                        hintStyle: TextStyle(color: theme.textMutedColor),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        taskService.updateTaskDetails(
                          taskId: task.id,
                          title: val.trim(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Section 1: Add to My Day
                    _buildActionTile(
                      theme: theme,
                      icon: Icons.wb_sunny_rounded,
                      iconColor: task.isMyDay
                          ? theme.accentColor
                          : theme.textMutedColor,
                      title: task.isMyDay ? 'Added to My Day' : 'Add to My Day',
                      subtitle:
                          task.isMyDay ? 'Active in today\'s focus list' : null,
                      onTap: () {
                        taskService.toggleMyDay(task.id, !task.isMyDay);
                      },
                      trailing: task.isMyDay
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: theme.textMutedColor,
                              onPressed: () =>
                                  taskService.toggleMyDay(task.id, false),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Subtasks / Steps
                    _buildSubtasksSection(
                      theme: theme,
                      task: task,
                      subtasksAsync: subtasksAsync,
                      taskService: taskService,
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Due Date & Reminder
                    _buildDueDateTile(
                      theme: theme,
                      task: task,
                      taskService: taskService,
                    ),
                    const SizedBox(height: 10),

                    // Section 4: Recurrence
                    _buildRecurrenceTile(
                      theme: theme,
                      task: task,
                      taskService: taskService,
                    ),
                    const SizedBox(height: 10),

                    // Section 5: List assignment
                    listsAsync.when(
                      data: (lists) => _buildListAssignmentTile(
                        theme: theme,
                        task: task,
                        lists: lists,
                        taskService: taskService,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),

                    // Section 6: Notes
                    Text(
                      'Notes',
                      style: TextStyle(
                        color: theme.textMutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackground,
                        borderRadius: theme.borderRadius,
                        border: Border.all(color: theme.borderColor, width: 1),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 5,
                        style: TextStyle(
                            color: theme.textColor,
                            fontSize: 13.5,
                            height: 1.4),
                        decoration: InputDecoration(
                          hintText: 'Add notes or links...',
                          hintStyle: TextStyle(
                              color: theme.textMutedColor, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          taskService.updateTaskDetails(
                            taskId: task.id,
                            notes: val,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 7: Created info & Delete
                    Row(
                      children: [
                        Text(
                          'Created ${DateFormat.MMMd().format(task.createdAt)}',
                          style: TextStyle(
                            color: theme.textMutedColor,
                            fontSize: 11.5,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.redAccent),
                          label: const Text('Delete Task',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 12)),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: theme.surface,
                                title: Text('Delete Task?',
                                    style: TextStyle(color: theme.textColor)),
                                content: Text(
                                  'Are you sure you want to permanently delete "${task.title}"?',
                                  style: TextStyle(color: theme.textMutedColor),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.redAccent),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await taskService.deleteTask(task.id);
                              widget.onClose();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: theme.accentColor),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: theme.textMutedColor)),
      ),
    );
  }

  Widget _buildActionTile({
    required DaybreakTheme theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: theme.borderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surfaceHover,
          borderRadius: theme.borderRadius,
          border: Border.all(color: theme.borderColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.textMutedColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSubtasksSection({
    required DaybreakTheme theme,
    required Task task,
    required AsyncValue<List<Subtask>> subtasksAsync,
    required dynamic taskService,
  }) {
    return subtasksAsync.when(
      data: (subtasks) {
        final completed = subtasks.where((s) => s.isCompleted).length;
        final total = subtasks.length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surfaceHover,
            borderRadius: theme.borderRadius,
            border: Border.all(color: theme.borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist_rounded,
                      color: theme.accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Checklist Steps',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (total > 0)
                    Text(
                      '$completed/$total completed',
                      style: TextStyle(
                        color: theme.textMutedColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    backgroundColor: theme.borderColor,
                    valueColor: AlwaysStoppedAnimation(theme.accentColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 10),
                ...subtasks.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            AudioFeedbackService.playTaskCompletion();
                            taskService.toggleSubtask(s.id, !s.isCompleted);
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: s.isCompleted
                                  ? theme.accentColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: s.isCompleted
                                    ? theme.accentColor
                                    : theme.textMutedColor
                                        .withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: s.isCompleted
                                ? const Icon(Icons.check,
                                    size: 11, color: Color(0xFF121212))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.title,
                            style: TextStyle(
                              color: s.isCompleted
                                  ? theme.textMutedColor
                                  : theme.textColor,
                              fontSize: 13,
                              decoration: s.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 14, color: theme.textMutedColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => taskService.deleteSubtask(s.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Add Step input
              Row(
                children: [
                  Icon(Icons.add, size: 16, color: theme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _newStepController,
                      focusNode: _newStepFocusNode,
                      style: TextStyle(color: theme.textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add a step...',
                        hintStyle: TextStyle(
                            color: theme.textMutedColor, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          taskService.createSubtask(task.id, val);
                          _newStepController.clear();
                          _newStepFocusNode.requestFocus();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDueDateTile({
    required DaybreakTheme theme,
    required Task task,
    required dynamic taskService,
  }) {
    final hasDueDate = task.dueDate != null;
    final formattedDate = hasDueDate
        ? DateFormat('EEE, MMM d, yyyy').format(task.dueDate!)
        : 'Set due date';

    return _buildActionTile(
      theme: theme,
      icon: Icons.calendar_today_rounded,
      iconColor: hasDueDate ? theme.accentColor : theme.textMutedColor,
      title: formattedDate,
      subtitle: hasDueDate ? 'Task due deadline' : null,
      onTap: () async {
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: task.dueDate ?? now,
          firstDate: now.subtract(const Duration(days: 365)),
          lastDate: now.add(const Duration(days: 3650)),
        );
        if (selected != null) {
          taskService.updateTaskDetails(
            taskId: task.id,
            dueDate: drift.Value(selected),
          );
        }
      },
      trailing: hasDueDate
          ? IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: theme.textMutedColor,
              onPressed: () {
                taskService.updateTaskDetails(
                  taskId: task.id,
                  dueDate: const drift.Value(null),
                );
              },
            )
          : null,
    );
  }

  Widget _buildRecurrenceTile({
    required DaybreakTheme theme,
    required Task task,
    required dynamic taskService,
  }) {
    final hasRule =
        task.recurrenceRule != null && task.recurrenceRule!.isNotEmpty;
    final ruleText = hasRule ? task.recurrenceRule!.toUpperCase() : 'Repeat';

    return _buildActionTile(
      theme: theme,
      icon: Icons.repeat_rounded,
      iconColor: hasRule ? theme.accentColor : theme.textMutedColor,
      title: ruleText,
      subtitle: hasRule ? 'Automatically spawns next occurrence' : null,
      onTap: () async {
        final options = ['never', 'daily', 'weekdays', 'weekly', 'monthly'];
        final selected = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            backgroundColor: theme.surface,
            title: Text('Repeat Interval',
                style: TextStyle(color: theme.textColor)),
            children: options
                .map(
                  (opt) => SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        opt == 'never' ? 'Never' : opt.toUpperCase(),
                        style: TextStyle(
                          color: opt == task.recurrenceRule
                              ? theme.accentColor
                              : theme.textColor,
                          fontWeight: opt == task.recurrenceRule
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );

        if (selected != null) {
          taskService.updateTaskDetails(
            taskId: task.id,
            recurrenceRule: drift.Value(selected == 'never' ? null : selected),
          );
        }
      },
    );
  }

  Widget _buildListAssignmentTile({
    required DaybreakTheme theme,
    required Task task,
    required List<TaskList> lists,
    required dynamic taskService,
  }) {
    final currentList = lists.firstWhere(
      (l) => l.id == task.listId,
      orElse: () => lists.isNotEmpty
          ? lists.first
          : const TaskList(
              id: 'tasks',
              name: 'Tasks',
              createdAt: null as dynamic,
              updatedAt: null as dynamic,
              isDeleted: false,
              syncStatus: 'synced',
            ),
    );

    return _buildActionTile(
      theme: theme,
      icon: Icons.folder_outlined,
      iconColor: theme.textMutedColor,
      title: 'List: ${currentList.name}',
      onTap: () async {
        final selectedListId = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            backgroundColor: theme.surface,
            title:
                Text('Move to List', style: TextStyle(color: theme.textColor)),
            children: lists
                .map(
                  (l) => SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(l.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        l.name,
                        style: TextStyle(
                          color: l.id == task.listId
                              ? theme.accentColor
                              : theme.textColor,
                          fontWeight: l.id == task.listId
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );

        if (selectedListId != null) {
          taskService.updateTaskDetails(
            taskId: task.id,
            listId: selectedListId,
          );
        }
      },
    );
  }
}
