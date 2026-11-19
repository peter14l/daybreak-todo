import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/natural_language_parser.dart';
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
  ParsedTaskInput? _currentParsed;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _handleTextChange() {
    final text = _controller.text;
    if (text.isEmpty) {
      if (_currentParsed != null) setState(() => _currentParsed = null);
      return;
    }
    final parsed = NaturalLanguageParser.parse(text);
    if (parsed.dueDate != null ||
        parsed.isImportant ||
        parsed.tags.isNotEmpty) {
      setState(() => _currentParsed = parsed);
    } else {
      if (_currentParsed != null) setState(() => _currentParsed = null);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

    final parsed = NaturalLanguageParser.parse(rawText);
    final activeView = ref.read(activeViewIdProvider);
    final taskService = ref.read(taskServiceProvider);

    final isMyDay = activeView == 'my-day';
    final isImportant = activeView == 'important' || parsed.isImportant;
    final listId = (activeView != 'my-day' &&
            activeView != 'important' &&
            activeView != 'planned' &&
            activeView != 'all')
        ? activeView
        : 'default-tasks-list';

    taskService.createTask(
      listId: listId,
      title: parsed.cleanTitle,
      isMyDay: isMyDay,
      isImportant: isImportant,
      dueDate: parsed.dueDate,
      reminderAt: parsed.reminderAt,
    );

    HapticFeedback.lightImpact();
    _controller.clear();
    setState(() => _currentParsed = null);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(currentThemeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live Natural Language preview chips
          if (_currentParsed != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                children: [
                  if (_currentParsed!.dueDate != null)
                    _buildChip(
                      icon: Icons.calendar_today_rounded,
                      label: DateFormat('EEE, MMM d • h:mm a')
                          .format(_currentParsed!.dueDate!),
                      theme: appTheme,
                    ),
                  if (_currentParsed!.isImportant) ...[
                    const SizedBox(width: 6),
                    _buildChip(
                      icon: Icons.star_rounded,
                      label: 'Important',
                      theme: appTheme,
                      iconColor: Colors.amber,
                    ),
                  ],
                  for (final tag in _currentParsed!.tags) ...[
                    const SizedBox(width: 6),
                    _buildChip(
                      icon: Icons.tag_rounded,
                      label: tag,
                      theme: appTheme,
                    ),
                  ],
                ],
              ),
            ),
          ],

          AnimatedContainer(
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
                    Icons.add_task_rounded,
                    color: _isFocused
                        ? appTheme.accentColor
                        : appTheme.textMutedColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: appTheme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Add a task... (Try "File taxes tomorrow at 5pm !important")',
                        hintStyle: TextStyle(
                          color: appTheme.textMutedColor,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: _controller.text.trim().isNotEmpty
                          ? appTheme.accentColor
                          : appTheme.textMutedColor.withValues(alpha: 0.4),
                    ),
                    onPressed:
                        _controller.text.trim().isNotEmpty ? _submit : null,
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required DaybreakTheme theme,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? theme.accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
