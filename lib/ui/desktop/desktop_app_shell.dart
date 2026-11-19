import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show
        Builder,
        DefaultMaterialLocalizations,
        DefaultWidgetsLocalizations,
        Icons,
        InkWell,
        Material,
        Theme;
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/db/app_database.dart';
import '../../core/platform/platform_config.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../onboarding/why_daybreak_dialog.dart';
import '../widgets/account_sync_dialog.dart';
import '../widgets/backup_import_dialog.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/task_detail_panel.dart';
import '../widgets/task_item_card.dart';
import '../widgets/theme_switcher_dialog.dart';

class DesktopAppShell extends ConsumerStatefulWidget {
  const DesktopAppShell({super.key});

  @override
  ConsumerState<DesktopAppShell> createState() => _DesktopAppShellState();
}

class _DesktopAppShellState extends ConsumerState<DesktopAppShell>
    with WindowListener {
  int _selectedTopIndex = 0;
  final FocusNode _quickAddFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isAlwaysOnTop = false;
  AppThemeStyle? _lastAppliedStyle;

  final List<String> _viewIds = ['my-day', 'important', 'planned', 'all'];

  @override
  void initState() {
    super.initState();
    try {
      windowManager.addListener(this);
    } catch (_) {}
    _initWindowEffect();
  }

  @override
  void dispose() {
    try {
      windowManager.removeListener(this);
    } catch (_) {}
    _quickAddFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initWindowEffect() async {
    if (!isWindows) return;
    try {
      await Window.initialize();
      final currentTheme = ref.read(currentThemeProvider);
      await _applyWindowTheme(currentTheme);
    } catch (_) {}
  }

  Future<void> _applyWindowTheme(DaybreakTheme theme) async {
    if (!isWindows) return;
    try {
      if (theme.isTranslucent) {
        await Window.setEffect(
          effect: WindowEffect.tabbed,
          color: const Color(0x00000000),
        );
      } else {
        await Window.setEffect(
          effect: WindowEffect.solid,
          color: theme.scaffoldBackground,
        );
      }
    } catch (_) {}
  }

  Future<void> _toggleCompactGlanceMode() async {
    final currentCompact = ref.read(isCompactGlanceProvider);
    final newCompact = !currentCompact;
    ref.read(isCompactGlanceProvider.notifier).state = newCompact;

    if (newCompact) {
      ref.read(activeViewIdProvider.notifier).state = 'my-day';
      await windowManager.setSize(const Size(360, 540));
      await windowManager.setMinimumSize(const Size(320, 480));
      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    } else {
      await windowManager.setSize(const Size(1200, 780));
      await windowManager.setMinimumSize(const Size(900, 600));
      await windowManager.setAlwaysOnTop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = ref.watch(isCompactGlanceProvider);
    final currentTheme = ref.watch(currentThemeProvider);

    // Reactively update window effect when theme changes
    if (_lastAppliedStyle != currentTheme.style) {
      _lastAppliedStyle = currentTheme.style;
      _applyWindowTheme(currentTheme);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          _quickAddFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyM, control: true): () {
          _toggleCompactGlanceMode();
        },
      },
      child: FluentApp(
        title: 'Daybreak',
        debugShowCheckedModeBanner: false,
        theme: currentTheme.toFluentTheme(),
        localizationsDelegates: const [
          FluentLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Theme(
          data: currentTheme.toMaterialTheme(),
          child: Material(
            color: Colors.transparent,
            child: Builder(
              builder: (ctx) => isCompact
                  ? _buildCompactGlanceView(currentTheme, ctx)
                  : _buildStandardDesktopView(currentTheme, ctx),
            ),
          ),
        ),
      ),
    );
  }

  /// Distraction-free Compact Glance mini-mode (360x540)
  Widget _buildCompactGlanceView(
      DaybreakTheme currentTheme, BuildContext context) {
    final tasksAsync = ref.watch(activeTasksStreamProvider);

    return ScaffoldPage(
      content: Container(
        color: currentTheme.isTranslucent
            ? const Color(0xE618181B)
            : currentTheme.scaffoldBackground,
        child: Column(
          children: [
            // Drag titlebar
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: currentTheme.sidebarBackground,
                border: Border(
                  bottom: BorderSide(color: currentTheme.borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DragToMoveArea(
                      child: Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_rounded,
                            size: 14,
                            color: currentTheme.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daybreak Glance',
                            style: TextStyle(
                              color: currentTheme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Switch Theme (${currentTheme.displayName})',
                    child: IconButton(
                      icon: Icon(
                        Icons.palette_outlined,
                        size: 13,
                        color: currentTheme.accentColor,
                      ),
                      onPressed: () => ThemeSwitcherDialog.show(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isAlwaysOnTop ? FluentIcons.pinned : FluentIcons.pin,
                      size: 13,
                      color: _isAlwaysOnTop
                          ? currentTheme.accentColor
                          : currentTheme.textMutedColor,
                    ),
                    onPressed: () async {
                      setState(() => _isAlwaysOnTop = !_isAlwaysOnTop);
                      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      FluentIcons.full_screen,
                      size: 13,
                      color: currentTheme.textMutedColor,
                    ),
                    onPressed: _toggleCompactGlanceMode,
                  ),
                  IconButton(
                    icon: Icon(
                      FluentIcons.chrome_close,
                      size: 13,
                      color: currentTheme.textMutedColor,
                    ),
                    onPressed: () => windowManager.close(),
                  ),
                ],
              ),
            ),

            // Mini Checklist
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 32,
                            color:
                                currentTheme.accentColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'My Day is clear!',
                            style: TextStyle(
                              color: currentTheme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Press Ctrl+N to add a focus task',
                            style: TextStyle(
                              color: currentTheme.textMutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, idx) =>
                        TaskItemCard(task: tasks[idx]),
                  );
                },
                loading: () => Center(
                  child: ProgressRing(
                    activeColor: currentTheme.accentColor,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: TextStyle(color: currentTheme.textColor),
                  ),
                ),
              ),
            ),

            QuickAddBar(focusNode: _quickAddFocusNode),
          ],
        ),
      ),
    );
  }

  /// Full Standard Windows 11 Desktop View with NavigationView
  Widget _buildStandardDesktopView(
      DaybreakTheme currentTheme, BuildContext context) {
    final activeView = ref.watch(activeViewIdProvider);
    final tasksAsync = ref.watch(activeTasksStreamProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final customListsAsync = ref.watch(allListsStreamProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    final taskFilter = ref.watch(taskFilterProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);

    final mainContent = Row(
      children: [
        Expanded(
          child: Container(
            color: currentTheme.isTranslucent
                ? Colors.transparent
                : currentTheme.scaffoldBackground,
            child: Column(
              children: [
                // Elegant Header matching index.html
                tasksAsync.maybeWhen(
                  data: (tasks) =>
                      _buildViewHeader(activeView, tasks, currentTheme),
                  orElse: () => _buildViewHeader(activeView, [], currentTheme),
                ),

                // Smart Filter Bar (Feature 7)
                _buildFilterBar(currentTheme, tasksAsync.value ?? []),

                // Tasks List
                Expanded(
                  child: tasksAsync.when(
                    data: (tasks) {
                      var filtered = tasks;
                      if (taskFilter == TaskFilter.pending) {
                        filtered =
                            filtered.where((t) => !t.isCompleted).toList();
                      } else if (taskFilter == TaskFilter.completed) {
                        filtered =
                            filtered.where((t) => t.isCompleted).toList();
                      } else if (taskFilter == TaskFilter.important) {
                        filtered =
                            filtered.where((t) => t.isImportant).toList();
                      }
                      if (selectedTag != null) {
                        filtered = filtered
                            .where((t) => t.title
                                .toLowerCase()
                                .contains('#${selectedTag.toLowerCase()}'))
                            .toList();
                      }
                      if (searchQuery.isNotEmpty) {
                        filtered = filtered
                            .where((t) => t.title
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase()))
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 40,
                                color: currentTheme.textMutedColor
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'No matching tasks found'
                                    : 'No tasks in this list yet',
                                style: TextStyle(
                                  color: currentTheme.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Press Ctrl+N to quickly add a task',
                                style: TextStyle(
                                  color: currentTheme.textMutedColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) =>
                            TaskItemCard(task: filtered[idx]),
                      );
                    },
                    loading: () => Center(
                      child: ProgressRing(
                        activeColor: currentTheme.accentColor,
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Error: $err',
                        style: TextStyle(color: currentTheme.textColor),
                      ),
                    ),
                  ),
                ),

                // Quick add bar
                QuickAddBar(focusNode: _quickAddFocusNode),
              ],
            ),
          ),
        ),
        if (selectedTaskId != null) ...[
          Container(
            width: 1,
            color: currentTheme.borderColor,
          ),
          SizedBox(
            width: 380,
            child: TaskDetailPanel(
              taskId: selectedTaskId,
              onClose: () =>
                  ref.read(selectedTaskIdProvider.notifier).state = null,
            ),
          ),
        ],
      ],
    );

    return NavigationView(
      titleBar: TitleBar(
        title: DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny_rounded,
                  size: 16,
                  color: currentTheme.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daybreak',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: currentTheme.textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: currentTheme.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: currentTheme.accentColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    currentTheme.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: currentTheme.accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        endHeader: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Search input
            SizedBox(
              width: 220,
              child: TextBox(
                controller: _searchController,
                focusNode: _searchFocusNode,
                placeholder: 'Search (Ctrl+F)',
                style: TextStyle(color: currentTheme.textColor, fontSize: 13),
                placeholderStyle: TextStyle(
                  color: currentTheme.textMutedColor,
                  fontSize: 13,
                ),
                decoration: WidgetStatePropertyAll(
                  BoxDecoration(
                    color: currentTheme.surface,
                    borderRadius: currentTheme.borderRadius,
                    border: Border.all(
                      color: currentTheme.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
              ),
            ),
            const SizedBox(width: 8),

            // Theme Switcher button
            Tooltip(
              message: 'Switch Theme (${currentTheme.displayName})',
              child: IconButton(
                icon: Icon(
                  Icons.palette_outlined,
                  size: 16,
                  color: currentTheme.accentColor,
                ),
                onPressed: () => ThemeSwitcherDialog.show(context),
              ),
            ),

            // Compact glance button
            Tooltip(
              message: 'Compact Glance Mode (Ctrl+M)',
              child: IconButton(
                icon: Icon(
                  FluentIcons.mini_expand,
                  size: 14,
                  color: currentTheme.textColor,
                ),
                onPressed: _toggleCompactGlanceMode,
              ),
            ),

            // Why Daybreak
            Tooltip(
              message: 'Why Daybreak?',
              child: IconButton(
                icon: Icon(
                  FluentIcons.info,
                  size: 14,
                  color: currentTheme.textColor,
                ),
                onPressed: () => WhyDaybreakDialog.show(context),
              ),
            ),

            // Backup & Import
            Tooltip(
              message: 'Backup, Export & Import Tasks',
              child: IconButton(
                icon: Icon(
                  Icons.sync_alt_rounded,
                  size: 15,
                  color: currentTheme.textColor,
                ),
                onPressed: () => BackupImportDialog.show(context),
              ),
            ),

            // Account & Cloud Sync
            Tooltip(
              message: 'Account & Cloud Sync',
              child: IconButton(
                icon: Icon(
                  Icons.account_circle_outlined,
                  size: 16,
                  color: currentTheme.accentColor,
                ),
                onPressed: () => AccountSyncDialog.show(context),
              ),
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _selectedTopIndex,
        onChanged: (index) {
          setState(() {
            _selectedTopIndex = index;
            if (index < _viewIds.length) {
              ref.read(activeViewIdProvider.notifier).state = _viewIds[index];
            }
          });
        },
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: Icon(FluentIcons.sunny,
                color: _selectedTopIndex == 0
                    ? currentTheme.accentColor
                    : currentTheme.textMutedColor),
            title:
                Text('My Day', style: TextStyle(color: currentTheme.textColor)),
            body: mainContent,
          ),
          PaneItem(
            icon: Icon(FluentIcons.favorite_star,
                color: _selectedTopIndex == 1
                    ? currentTheme.accentColor
                    : currentTheme.textMutedColor),
            title: Text('Important',
                style: TextStyle(color: currentTheme.textColor)),
            body: mainContent,
          ),
          PaneItem(
            icon: Icon(FluentIcons.calendar,
                color: _selectedTopIndex == 2
                    ? currentTheme.accentColor
                    : currentTheme.textMutedColor),
            title: Text('Planned',
                style: TextStyle(color: currentTheme.textColor)),
            body: mainContent,
          ),
          PaneItem(
            icon: Icon(FluentIcons.check_list,
                color: _selectedTopIndex == 3
                    ? currentTheme.accentColor
                    : currentTheme.textMutedColor),
            title: Text('All Tasks',
                style: TextStyle(color: currentTheme.textColor)),
            body: mainContent,
          ),
          PaneItemSeparator(),
          PaneItemHeader(
            header: Text(
              'LISTS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: currentTheme.textMutedColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...customListsAsync.when<List<NavigationPaneItem>>(
            data: (lists) => lists
                .map(
                  (l) => PaneItemAction(
                    icon: Icon(
                      FluentIcons.bulleted_list,
                      color: currentTheme.textMutedColor,
                    ),
                    title: Text(l.name,
                        style: TextStyle(color: currentTheme.textColor)),
                    body: mainContent,
                    onTap: () {
                      ref.read(activeViewIdProvider.notifier).state = l.id;
                    },
                  ),
                )
                .toList(),
            loading: () => <NavigationPaneItem>[],
            error: (_, __) => <NavigationPaneItem>[],
          ),
        ],
      ),
    );
  }

  Widget _buildViewHeader(
      String activeView, List<Task> tasks, DaybreakTheme currentTheme) {
    String title;
    String subtitle;
    IconData icon;

    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;

    switch (activeView) {
      case 'my-day':
        title = 'My Day';
        icon = Icons.wb_sunny_rounded;
        subtitle = totalCount > 0
            ? '$completedCount of $totalCount completed · Midnight rollover active'
            : 'Every morning is a fresh start';
        break;
      case 'important':
        title = 'Important';
        icon = Icons.star_rounded;
        final pending = tasks.where((t) => !t.isCompleted).length;
        subtitle =
            '$pending high-priority task${pending == 1 ? '' : 's'} flagged';
        break;
      case 'planned':
        title = 'Planned';
        icon = Icons.calendar_today_rounded;
        subtitle = 'Scheduled tasks and upcoming milestones';
        break;
      case 'all':
        title = 'All Tasks';
        icon = Icons.task_alt_rounded;
        subtitle = '$totalCount total tasks in local SQLite database';
        break;
      default:
        title = 'Custom List';
        icon = Icons.list_rounded;
        subtitle = '$totalCount items';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 14),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: currentTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: currentTheme.borderRadius,
              border: Border.all(
                color: currentTheme.accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: currentTheme.accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: currentTheme.textColor,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: currentTheme.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(DaybreakTheme currentTheme, List<Task> tasks) {
    final activeFilter = ref.watch(taskFilterProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);

    // Extract tags from tasks
    final tagRegex = RegExp(r'#(\w+)', caseSensitive: false);
    final foundTags = <String>{};
    for (final t in tasks) {
      for (final m in tagRegex.allMatches(t.title)) {
        if (m.group(1) != null) foundTags.add(m.group(1)!.toLowerCase());
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'All',
              activeFilter == TaskFilter.all && selectedTag == null,
              () {
                ref.read(taskFilterProvider.notifier).state = TaskFilter.all;
                ref.read(selectedTagFilterProvider.notifier).state = null;
              },
              currentTheme,
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              'Pending',
              activeFilter == TaskFilter.pending && selectedTag == null,
              () {
                ref.read(taskFilterProvider.notifier).state =
                    TaskFilter.pending;
                ref.read(selectedTagFilterProvider.notifier).state = null;
              },
              currentTheme,
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              'Completed',
              activeFilter == TaskFilter.completed && selectedTag == null,
              () {
                ref.read(taskFilterProvider.notifier).state =
                    TaskFilter.completed;
                ref.read(selectedTagFilterProvider.notifier).state = null;
              },
              currentTheme,
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              '⭐ Important',
              activeFilter == TaskFilter.important && selectedTag == null,
              () {
                ref.read(taskFilterProvider.notifier).state =
                    TaskFilter.important;
                ref.read(selectedTagFilterProvider.notifier).state = null;
              },
              currentTheme,
            ),
            for (final tag in foundTags) ...[
              const SizedBox(width: 6),
              _buildFilterChip(
                '#$tag',
                selectedTag == tag,
                () {
                  ref.read(selectedTagFilterProvider.notifier).state =
                      selectedTag == tag ? null : tag;
                },
                currentTheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, VoidCallback onTap, DaybreakTheme theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accentColor.withValues(alpha: 0.18)
              : theme.surfaceHover,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.accentColor : theme.borderColor,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.accentColor : theme.textMutedColor,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
