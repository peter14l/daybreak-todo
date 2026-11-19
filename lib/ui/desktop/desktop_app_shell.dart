import 'package:fluent_ui/fluent_ui.dart';
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
        color: const Color(0x00000000),
      );
    } catch (_) {
      try {
        await Window.setEffect(
          effect: WindowEffect.acrylic,
          color: const Color(0x20000000),
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
        theme: FluentThemeData(
          accentColor: Colors.orange,
          scaffoldBackgroundColor: Colors.transparent,
          navigationPaneTheme: const NavigationPaneThemeData(
            backgroundColor: Colors.transparent,
          ),
        ),
        home:
            isCompact ? _buildCompactGlanceView() : _buildStandardDesktopView(),
      ),
    );
  }

  /// Distraction-free Compact Glance mini-mode (360x540)
  Widget _buildCompactGlanceView() {
    final tasksAsync = ref.watch(activeTasksStreamProvider);

    return ScaffoldPage(
      content: Container(
        color: const Color(0xE61E1E2C),
        child: Column(
          children: [
            // Drag titlebar
            DragToMoveArea(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0x33000000),
                child: Row(
                  children: [
                    const Text(
                      '🌅 Daybreak Glance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isAlwaysOnTop ? FluentIcons.pinned : FluentIcons.pin,
                        size: 14,
                        color: _isAlwaysOnTop ? Colors.orange : Colors.white,
                      ),
                      onPressed: () async {
                        setState(() => _isAlwaysOnTop = !_isAlwaysOnTop);
                        await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        FluentIcons.full_screen,
                        size: 14,
                        color: Colors.white,
                      ),
                      onPressed: _toggleCompactGlanceMode,
                    ),
                    IconButton(
                      icon: const Icon(
                        FluentIcons.chrome_close,
                        size: 14,
                        color: Colors.white,
                      ),
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
                      child: Text(
                        'My Day is clear! 🌅',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, idx) =>
                        TaskItemCard(task: tasks[idx]),
                  );
                },
                loading: () => const Center(child: ProgressRing()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),

            QuickAddBar(focusNode: _quickAddFocusNode),
          ],
        ),
      ),
    );
  }

  /// Full Standard Windows 11 Desktop View with NavigationView
  Widget _buildStandardDesktopView() {
    final activeView = ref.watch(activeViewIdProvider);
    final tasksAsync = ref.watch(activeTasksStreamProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final customListsAsync = ref.watch(allListsStreamProvider);

    final mainContent = Container(
      color: Colors.transparent,
      child: Column(
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                  itemBuilder: (context, idx) => TaskItemCard(task: tasks[idx]),
                );
              },
              loading: () => const Center(child: ProgressRing()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),

          // Quick add bar
          QuickAddBar(focusNode: _quickAddFocusNode),
        ],
      ),
    );

    return NavigationView(
      titleBar: TitleBar(
        title: const DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'Daybreak',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        endHeader: DragToMoveArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Search input
              SizedBox(
                width: 220,
                child: TextBox(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  placeholder: 'Search (Ctrl+F)',
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Compact Glance Mode (Ctrl+M)',
                child: IconButton(
                  icon: const Icon(FluentIcons.mini_expand),
                  onPressed: _toggleCompactGlanceMode,
                ),
              ),
              Tooltip(
                message: 'Why Daybreak?',
                child: IconButton(
                  icon: const Icon(FluentIcons.info),
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
            icon: const Icon(FluentIcons.sunny),
            title: const Text('My Day'),
            body: mainContent,
          ),
          PaneItem(
            icon: const Icon(FluentIcons.favorite_star),
            title: const Text('Important'),
            body: mainContent,
          ),
          PaneItem(
            icon: const Icon(FluentIcons.calendar),
            title: const Text('Planned'),
            body: mainContent,
          ),
          PaneItem(
            icon: const Icon(FluentIcons.check_list),
            title: const Text('All Tasks'),
            body: mainContent,
          ),
          PaneItemSeparator(),
          PaneItemHeader(header: const Text('Lists')),
          ...customListsAsync.when<List<NavigationPaneItem>>(
            data: (lists) => lists
                .map(
                  (l) => PaneItemAction(
                    icon: const Icon(FluentIcons.bulleted_list),
                    title: Text(l.name),
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
}
