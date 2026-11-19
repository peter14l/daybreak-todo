import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/microsoft_import_service.dart';
import '../../core/state/providers.dart';
import '../../core/theme/theme_provider.dart';

class BackupImportDialog extends ConsumerStatefulWidget {
  const BackupImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const BackupImportDialog(),
    );
  }

  @override
  ConsumerState<BackupImportDialog> createState() => _BackupImportDialogState();
}

class _BackupImportDialogState extends ConsumerState<BackupImportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importJsonController = TextEditingController();

  bool _isExporting = false;
  String? _exportedJson;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importJsonController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    final db = ref.read(databaseProvider);
    final service = MicrosoftTodoImportService(db.taskDao, db.taskListDao);
    final json = await service.exportToJsonString();
    setState(() {
      _isExporting = false;
      _exportedJson = json;
    });
  }

  Future<void> _handleImport() async {
    final text = _importJsonController.text.trim();
    if (text.isEmpty) return;

    final db = ref.read(databaseProvider);
    final service = MicrosoftTodoImportService(db.taskDao, db.taskListDao);
    final result = await service.importFromJsonString(text);

    setState(() {
      if (result.errors.isEmpty) {
        _isSuccess = true;
        _statusMessage =
            'Successfully imported ${result.listsImported} lists and ${result.tasksImported} tasks!';
        _importJsonController.clear();
      } else {
        _isSuccess = false;
        _statusMessage = 'Import error: ${result.errors.join(', ')}';
      }
    });

    ref.read(taskServiceProvider).refreshWidgets();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: theme.borderRadius,
        side: BorderSide(color: theme.borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.sync_alt_rounded,
                      color: theme.accentColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Backup, Export & Import',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textMutedColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: theme.accentColor,
                labelColor: theme.accentColor,
                unselectedLabelColor: theme.textMutedColor,
                tabs: const [
                  Tab(text: 'Export Backup'),
                  Tab(text: 'Import Tasks / Backup'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab contents
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Export
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export all your tasks, lists, and subtasks into a portable JSON backup archive.',
                          style: TextStyle(
                            color: theme.textMutedColor,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.accentColor,
                            foregroundColor: const Color(0xFF121212),
                            shape: RoundedRectangleBorder(
                              borderRadius: theme.borderRadius,
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text(_isExporting
                              ? 'Exporting...'
                              : 'Generate Backup JSON'),
                          onPressed: _isExporting ? null : _handleExport,
                        ),
                        if (_exportedJson != null) ...[
                          const SizedBox(height: 14),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackground,
                                borderRadius: theme.borderRadius,
                                border: Border.all(color: theme.borderColor),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _exportedJson!,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontFamily: 'monospace',
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copy to Clipboard'),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _exportedJson!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Backup copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Tab 2: Import
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paste Daybreak JSON backup content or Microsoft To-Do export JSON below:',
                          style: TextStyle(
                            color: theme.textMutedColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackground,
                              borderRadius: theme.borderRadius,
                              border: Border.all(color: theme.borderColor),
                            ),
                            child: TextField(
                              controller: _importJsonController,
                              maxLines: null,
                              expands: true,
                              style: TextStyle(
                                color: theme.textColor,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Paste {"lists": [...], "tasks": [...]} here...',
                                hintStyle: TextStyle(
                                    color: theme.textMutedColor, fontSize: 12),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        if (_statusMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _isSuccess
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.accentColor,
                              foregroundColor: const Color(0xFF121212),
                              shape: RoundedRectangleBorder(
                                borderRadius: theme.borderRadius,
                              ),
                            ),
                            icon:
                                const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('Import Tasks Now'),
                            onPressed: _handleImport,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
