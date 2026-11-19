import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';

class QuickAddBar extends ConsumerStatefulWidget {
  final FocusNode? focusNode;

  const QuickAddBar({super.key, this.focusNode});

  @override
  ConsumerState<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends ConsumerState<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final activeView = ref.read(activeViewIdProvider);
    final taskService = ref.read(taskServiceProvider);

    final isMyDay = activeView == 'my-day';
    final isImportant = activeView == 'important';
    final listId = (activeView != 'my-day' &&
            activeView != 'important' &&
            activeView != 'planned' &&
            activeView != 'all')
        ? activeView
        : 'default-tasks-list';

    taskService.createTask(
      listId: listId,
      title: text,
      isMyDay: isMyDay,
      isImportant: isImportant,
    );

    HapticFeedback.lightImpact();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(28),
        color: colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.add_task, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Add a task... (Press Enter)',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                onPressed: _submit,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
