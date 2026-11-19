import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../onboarding/why_daybreak_dialog.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/task_item_card.dart';

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
        return 'My Day 🌅';
      case 'important':
        return 'Important ⭐';
      case 'planned':
        return 'Planned 📅';
      case 'all':
        return 'All Tasks 📋';
      default:
        return 'Tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    const defaultSunriseSeed = Color(0xFFFFB74C);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightColorScheme =
            lightDynamic ?? ColorScheme.fromSeed(seedColor: defaultSunriseSeed);
        final darkColorScheme = darkDynamic ??
            ColorScheme.fromSeed(
                seedColor: defaultSunriseSeed, brightness: Brightness.dark);

        return MaterialApp(
          title: 'Daybreak',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            scaffoldBackgroundColor: lightColorScheme.surface,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            scaffoldBackgroundColor: darkColorScheme.surface,
          ),
          themeMode: ThemeMode.system,
          home: Builder(
            builder: (ctx) {
              final activeView = ref.watch(activeViewIdProvider);
              final tasksAsync = ref.watch(activeTasksStreamProvider);
              final searchQuery = ref.watch(searchQueryProvider);

              return Scaffold(
                appBar: AppBar(
                  title: _isSearching
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Search tasks...',
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                        )
                      : Text(
                          _getViewTitle(activeView),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                  actions: [
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search),
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
                      icon: const Icon(Icons.help_outline),
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
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tasks here yet.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add one below to start your day fresh.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
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
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      ),
                    ),
                    const QuickAddBar(),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) {
                    setState(() {
                      _currentIndex = idx;
                      ref.read(activeViewIdProvider.notifier).state =
                          _viewIds[idx];
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.wb_sunny_outlined),
                      selectedIcon: Icon(Icons.wb_sunny),
                      label: 'My Day',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.star_border),
                      selectedIcon: Icon(Icons.star),
                      label: 'Important',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_today_outlined),
                      selectedIcon: Icon(Icons.calendar_today),
                      label: 'Planned',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.checklist_outlined),
                      selectedIcon: Icon(Icons.checklist),
                      label: 'All Tasks',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
