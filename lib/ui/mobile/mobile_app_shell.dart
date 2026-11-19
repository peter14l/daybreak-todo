import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/state/providers.dart';
import '../../core/theme/theme_provider.dart';
import '../onboarding/why_daybreak_dialog.dart';
import '../widgets/backup_import_dialog.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/task_detail_panel.dart';
import '../widgets/task_item_card.dart';
import '../widgets/theme_switcher_dialog.dart';

class MobileAppShell extends ConsumerStatefulWidget {
  const MobileAppShell({super.key});

  @override
  ConsumerState<MobileAppShell> createState() => _MobileAppShellState();
}

class _MobileAppShellState extends ConsumerState<MobileAppShell> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _viewIds = ['my-day', 'important', 'planned', 'all'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getViewTitle(String viewId) {
    switch (viewId) {
      case 'my-day':
        return 'My Day';
      case 'important':
        return 'Important';
      case 'planned':
        return 'Planned';
      case 'all':
        return 'All Tasks';
      default:
        return 'Tasks';
    }
  }

  IconData _getViewIcon(String viewId) {
    switch (viewId) {
      case 'my-day':
        return Icons.wb_sunny_rounded;
      case 'important':
        return Icons.star_rounded;
      case 'planned':
        return Icons.calendar_today_rounded;
      case 'all':
        return Icons.task_alt_rounded;
      default:
        return Icons.list_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(currentThemeProvider);

    return MaterialApp(
      title: 'Daybreak',
      debugShowCheckedModeBanner: false,
      theme: currentTheme.toMaterialTheme(),
      home: Builder(
        builder: (ctx) {
          final activeView = ref.watch(activeViewIdProvider);
          final tasksAsync = ref.watch(activeTasksStreamProvider);
          final searchQuery = ref.watch(searchQueryProvider);

          return Scaffold(
            backgroundColor: currentTheme.scaffoldBackground,
            appBar: AppBar(
              backgroundColor: currentTheme.sidebarBackground,
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: currentTheme.borderColor,
                  height: 1,
                ),
              ),
              leading: Icon(
                _getViewIcon(activeView),
                color: currentTheme.accentColor,
                size: 22,
              ),
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                          color: currentTheme.textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(
                          color: currentTheme.textMutedColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                      },
                    )
                  : Row(
                      children: [
                        Text(
                          _getViewTitle(activeView),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: currentTheme.textColor,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: currentTheme.accentColor
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentTheme.displayName.toUpperCase(),
                            style: TextStyle(
                              color: currentTheme.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: currentTheme.textColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.palette_outlined,
                    color: currentTheme.accentColor,
                    size: 20,
                  ),
                  tooltip: 'Switch Theme (${currentTheme.displayName})',
                  onPressed: () => ThemeSwitcherDialog.show(ctx),
                ),
                IconButton(
                  icon: Icon(
                    Icons.sync_alt_rounded,
                    color: currentTheme.textMutedColor,
                    size: 20,
                  ),
                  tooltip: 'Backup, Export & Import',
                  onPressed: () => BackupImportDialog.show(ctx),
                ),
                IconButton(
                  icon: Icon(
                    Icons.help_outline,
                    color: currentTheme.textMutedColor,
                    size: 20,
                  ),
                  tooltip: 'Why Daybreak?',
                  onPressed: () => WhyDaybreakDialog.show(ctx),
                ),
              ],
            ),
            body: Column(
              children: [
                // Smart Filter Bar (Feature 7)
                _buildFilterBar(currentTheme, tasksAsync.value ?? []),

                Expanded(
                  child: tasksAsync.when(
                    data: (tasks) {
                      final taskFilter = ref.watch(taskFilterProvider);
                      final selectedTag = ref.watch(selectedTagFilterProvider);

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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                size: 52,
                                color: currentTheme.accentColor
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks here yet',
                                style: TextStyle(
                                  color: currentTheme.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add one below to start your day fresh.',
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
                        itemCount: filtered.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemBuilder: (context, index) {
                          return TaskItemCard(
                            task: filtered[index],
                            onTap: () {
                              showModalBottomSheet(
                                context: ctx,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (sheetCtx) => Container(
                                  height: MediaQuery.of(sheetCtx).size.height *
                                      0.85,
                                  decoration: BoxDecoration(
                                    color: currentTheme.surface,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: TaskDetailPanel(
                                    taskId: filtered[index].id,
                                    onClose: () => Navigator.of(sheetCtx).pop(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(currentTheme.accentColor),
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
                const QuickAddBar(),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: currentTheme.borderColor, width: 1),
                ),
              ),
              child: NavigationBar(
                backgroundColor: currentTheme.sidebarBackground,
                indicatorColor: currentTheme.accentColor.withValues(alpha: 0.2),
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) {
                  setState(() {
                    _currentIndex = idx;
                    ref.read(activeViewIdProvider.notifier).state =
                        _viewIds[idx];
                  });
                },
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.wb_sunny_outlined,
                        color: currentTheme.textMutedColor),
                    selectedIcon: Icon(Icons.wb_sunny_rounded,
                        color: currentTheme.accentColor),
                    label: 'My Day',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.star_border_rounded,
                        color: currentTheme.textMutedColor),
                    selectedIcon: Icon(Icons.star_rounded,
                        color: currentTheme.accentColor),
                    label: 'Important',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_today_outlined,
                        color: currentTheme.textMutedColor),
                    selectedIcon: Icon(Icons.calendar_today_rounded,
                        color: currentTheme.accentColor),
                    label: 'Planned',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.task_alt_rounded,
                        color: currentTheme.textMutedColor),
                    selectedIcon: Icon(Icons.task_alt_rounded,
                        color: currentTheme.accentColor),
                    label: 'All Tasks',
                  ),
                ],
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
