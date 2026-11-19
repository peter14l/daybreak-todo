import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/state/providers.dart';
import '../../core/theme/theme_provider.dart';
import '../onboarding/why_daybreak_dialog.dart';
import '../widgets/quick_add_bar.dart';
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
                  onPressed: () => ThemeSwitcherDialog.show(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.help_outline,
                    color: currentTheme.textMutedColor,
                    size: 20,
                  ),
                  tooltip: 'Why Daybreak?',
                  onPressed: () => WhyDaybreakDialog.show(context),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: tasksAsync.when(
                    data: (tasks) {
                      var filtered = tasks;
                      if (searchQuery.isNotEmpty) {
                        filtered = tasks
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
                          return TaskItemCard(task: filtered[index]);
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
}
