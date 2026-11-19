import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/platform/platform_config.dart';
import '../../core/state/providers.dart';
import '../onboarding/why_daybreak_dialog.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/task_item_card.dart';

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
      // Apply Mica Alt (WindowEffect.tabbed) with fallback to acrylic
      await Window.setEffect(
        effect: WindowEffect.tabbed,
        color: const material.Color(0x00000000),
      );
    } catch (_) {
      try {
        await Window.setEffect(
          effect: WindowEffect.acrylic,
          color: const material.Color(0x20000000),
        );
      } catch (_) {}
    }
  }

  Future<void> _toggleCompactGlanceMode() async {
    final currentCompact = ref.read(isCompactGlanceProvider);
    final newCompact = !currentCompact;
    ref.read(isCompactGlanceProvider.notifier).state = newCompact;

    if (newCompact) {
      ref.read(activeViewIdProvider.notifier).state = 'my-day';
      await windowManager.setSize(const material.Size(360, 540));
      await windowManager.setMinSize(const material.Size(320, 480));
      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    } else {
      await windowManager.setSize(const material.Size(1200, 780));
      await windowManager.setMinSize(const material.Size(900, 600));
      await windowManager.setAlwaysOnTop(false);
    }
  }

  @override
  material.Widget build(BuildContext context) {
    final isCompact = ref.watch(isCompactGlanceProvider);

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
      child: fluent.FluentApp(
        title: 'Daybreak',
        debugShowCheckedModeBanner: false,
        theme: fluent.FluentThemeData(
          accentColor: fluent.Colors.orange,
          scaffoldBackgroundColor: fluent.Colors.transparent,
          navigationPaneTheme: const fluent.NavigationPaneThemeData(
            backgroundColor: fluent.Colors.transparent,
          ),
        ),
        home:
            isCompact ? _buildCompactGlanceView() : _buildStandardDesktopView(),
      ),
    );
  }

  /// Distraction-free Compact Glance mini-mode (360x540)
  material.Widget _buildCompactGlanceView() {
    final tasksAsync = ref.watch(activeTasksStreamProvider);

    return material.Scaffold(
      backgroundColor: const material.Color(0xE61E1E2C),
      body: material.Column(
        children: [
          // Drag titlebar
          DragToMoveArea(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: const material.Color(0x33000000),
              child: Row(
                children: [
                  const Text('🌅 Daybreak Glance',
                      style: TextStyle(
                          color: material.Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 16,
                      color: _isAlwaysOnTop
                          ? material.Colors.amber
                          : material.Colors.white70,
                    ),
                    onPressed: () async {
                      setState(() => _isAlwaysOnTop = !_isAlwaysOnTop);
                      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen,
                        size: 16, color: material.Colors.white70),
                    tooltip: 'Restore full window (Ctrl+M)',
                    onPressed: _toggleCompactGlanceMode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: material.Colors.white70),
                    onPressed: () => windowManager.close(),
                  ),
                ],
              ),
            ),
          ),

          // Mini Checklist
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('My Day is clear! 🌅',
                        style: TextStyle(color: material.Colors.white70)),
                  );
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, idx) => TaskItemCard(task: tasks[idx]),
                );
              },
              loading: () =>
                  const Center(child: material.CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          QuickAddBar(focusNode: _quickAddFocusNode),
        ],
      ),
    );
  }

  /// Full Standard Windows 11 Desktop View with NavigationView
  material.Widget _buildStandardDesktopView() {
    final activeView = ref.watch(activeViewIdProvider);
    final tasksAsync = ref.watch(activeTasksStreamProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final customListsAsync = ref.watch(allListsStreamProvider);

    return fluent.NavigationView(
      appBar: fluent.NavigationAppBar(
        title: const DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'Daybreak',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        actions: DragToMoveArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Search input
              SizedBox(
                width: 220,
                child: fluent.TextBox(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  placeholder: 'Search (Ctrl+F)',
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              fluent.Tooltip(
                message: 'Compact Glance Mode (Ctrl+M)',
                child: fluent.IconButton(
                  icon: const fluent.Icon(fluent.FluentIcons.mini_expand),
                  onPressed: _toggleCompactGlanceMode,
                ),
              ),
              fluent.Tooltip(
                message: 'Why Daybreak?',
                child: fluent.IconButton(
                  icon: const fluent.Icon(fluent.FluentIcons.info),
                  onPressed: () => WhyDaybreakDialog.show(context),
                ),
              ),
              const SizedBox(width: 8),
              const WindowCaption(
                brightness: Brightness.dark,
              ),
            ],
          ),
        ),
      ),
      pane: fluent.NavigationPane(
        selected: _selectedTopIndex,
        onChanged: (index) {
          setState(() {
            _selectedTopIndex = index;
            if (index < _viewIds.length) {
              ref.read(activeViewIdProvider.notifier).state = _viewIds[index];
            }
          });
        },
        displayMode: fluent.PaneDisplayMode.compact,
        items: [
          fluent.PaneItem(
            icon: const fluent.Icon(fluent.FluentIcons.sunny),
            title: const Text('My Day'),
            body: const SizedBox.shrink(),
          ),
          fluent.PaneItem(
            icon: const fluent.Icon(fluent.FluentIcons.favorite_star),
            title: const Text('Important'),
            body: const SizedBox.shrink(),
          ),
          fluent.PaneItem(
            icon: const fluent.Icon(fluent.FluentIcons.calendar),
            title: const Text('Planned'),
            body: const SizedBox.shrink(),
          ),
          fluent.PaneItem(
            icon: const fluent.Icon(fluent.FluentIcons.checklist),
            title: const Text('All Tasks'),
            body: const SizedBox.shrink(),
          ),
        ],
        customPaneItems: [
          const fluent.PaneItemSeparator(),
          fluent.PaneItemHeader(header: const Text('Lists')),
          ...customListsAsync.when(
            data: (lists) => lists.map((l) => fluent.PaneItemAction(
                  icon: const fluent.Icon(fluent.FluentIcons.bulleted_list),
                  title: Text(l.name),
                  onTap: () {
                    ref.read(activeViewIdProvider.notifier).state = l.id;
                  },
                )),
            loading: () => [],
            error: (_, __) => [],
          ),
        ],
      ),
      content: material.Material(
        color: material.Colors.transparent,
        child: material.Column(
          children: [
            // Active list header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                activeView == 'my-day'
                    ? 'My Day 🌅'
                    : activeView == 'important'
                        ? 'Important ⭐'
                        : activeView == 'planned'
                            ? 'Planned 📅'
                            : activeView == 'all'
                                ? 'All Tasks 📋'
                                : 'Custom List',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            // Tasks List
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
                    return const Center(
                      child: Text('No tasks here. Press Ctrl+N to create one!'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) =>
                        TaskItemCard(task: filtered[idx]),
                  );
                },
                loading: () =>
                    const Center(child: material.CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),

            // Quick add bar
            QuickAddBar(focusNode: _quickAddFocusNode),
          ],
        ),
      ),
    );
  }
}
