import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/theme_provider.dart';

class QuickAddBar extends ConsumerStatefulWidget {
  final FocusNode? focusNode;

  const QuickAddBar({super.key, this.focusNode});

  @override
  ConsumerState<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends ConsumerState<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
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
    final appTheme = ref.watch(currentThemeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: appTheme.quickAddBackground,
          borderRadius: appTheme.quickAddBorderRadius,
          border: Border.all(
            color: _isFocused
                ? appTheme.accentColor.withValues(alpha: 0.7)
                : appTheme.borderColor,
            width: _isFocused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.add_task,
                color:
                    _isFocused ? appTheme.accentColor : appTheme.textMutedColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: appTheme.textColor,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a task... (Press Enter)',
                    hintStyle: TextStyle(
                      color: appTheme.textMutedColor.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                onPressed: _submit,
                color: appTheme.accentColor,
                splashRadius: 18,
                tooltip: 'Add task',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
