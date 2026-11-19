import 'package:flutter/material.dart';

class WhyDaybreakDialog extends StatelessWidget {
  const WhyDaybreakDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const WhyDaybreakDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('🌅', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why Daybreak?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Every morning is a fresh start.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Why it was built banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Built as the high-speed, native successor for task planning before Microsoft To Do retires in June 2027.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Feature Pillars Scrollable List
              Expanded(
                child: ListView(
                  children: [
                    _buildPillarItem(
                      context,
                      icon: Icons.bolt,
                      iconColor: Colors.amber,
                      title: '1. Local-First Speed + Cloud Sync',
                      description:
                          'Instant SQLite reads and writes with zero loading spinners or network lag. Changes queue offline and sync securely with Supabase.',
                    ),
                    _buildPillarItem(
                      context,
                      icon: Icons.laptop_windows,
                      iconColor: Colors.blueAccent,
                      title: '2. True Native OS Design (No Electron)',
                      description:
                          'Native Windows 11 Mica Alt translucent surfaces with keyboard navigation, paired with Material 3 Expressive dynamic Monet palettes on Android.',
                    ),
                    _buildPillarItem(
                      context,
                      icon: Icons.wb_sunny_outlined,
                      iconColor: Colors.orange,
                      title: '3. True "My Day" Daily Reset',
                      description:
                          'Start every morning with a clean slate. Yesterday\'s daily view clears at midnight without losing tasks from their parent list—no overdue red-badge anxiety.',
                    ),
                    _buildPillarItem(
                      context,
                      icon: Icons.widgets_outlined,
                      iconColor: Colors.teal,
                      title: '4. Aesthetic Free Widgets',
                      description:
                          'Interactive Android 4x3 checklist & 4x1 Focus pill, plus a Windows Compact Glance mini-mode (Ctrl+M)—all included for free without subscription paywalls.',
                    ),
                    _buildPillarItem(
                      context,
                      icon: Icons.sync_alt,
                      iconColor: Colors.purpleAccent,
                      title: '5. One-Click To Do Migration',
                      description:
                          'Seamlessly import your existing lists and tasks directly via Microsoft Graph API or from exported JSON archive backups.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Start Planning Today',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillarItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
