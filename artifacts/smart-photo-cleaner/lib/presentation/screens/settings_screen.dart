import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router.dart';
import '../../core/constants/app_constants.dart';
import '../providers/theme_provider.dart';

/// Settings screen — theme, scan preferences, and app info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoSelectBest = true;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadVersion();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoSelectBest = prefs.getBool(AppConstants.prefAutoSelectBest) ?? true;
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = '${info.version} (${info.buildNumber})');
  }

  Future<void> _saveAutoSelect(bool value) async {
    setState(() => _autoSelectBest = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefAutoSelectBest, value);
  }

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final theme    = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: const Text('Theme'),
            subtitle: Text(_themeName(theme)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemePicker(context, theme, notifier),
          ),

          const Divider(indent: 16, endIndent: 16, height: 1),

          // ── Scanning ────────────────────────────────────────────────────
          _SectionHeader('Scanning'),
          SwitchListTile(
            secondary: const Icon(Icons.star_rounded),
            title: const Text('Auto-select best photo'),
            subtitle: const Text(
              'Automatically mark lower-quality photos for deletion',
            ),
            value: _autoSelectBest,
            onChanged: _saveAutoSelect,
          ),

          const Divider(indent: 16, endIndent: 16, height: 1),

          // ── Privacy ─────────────────────────────────────────────────────
          _SectionHeader('Privacy'),
          ListTile(
            leading: Icon(Icons.lock_rounded, color: Colors.green),
            title: const Text('100% On-Device Processing'),
            subtitle: const Text(
              'Your photos never leave your device. All AI analysis, '
              'duplicate detection, and quality scoring happens locally '
              'on your phone.',
            ),
            isThreeLine: true,
          ),

          const Divider(indent: 16, endIndent: 16, height: 1),

          // ── Support ─────────────────────────────────────────────────────
          _SectionHeader('Support'),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Help & FAQ'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.help),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.about),
          ),

          const Divider(indent: 16, endIndent: 16, height: 1),

          // ── Version ─────────────────────────────────────────────────────
          _SectionHeader('Version'),
          ListTile(
            leading: const Icon(Icons.tag_rounded),
            title: const Text('App Version'),
            subtitle: Text(
              _version.isNotEmpty ? _version : AppConstants.version,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    ThemeMode current,
    ThemeNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Choose Theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final mode in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
              ListTile(
                leading: Icon(_themeIcon(mode)),
                title: Text(_themeName(mode)),
                trailing:
                    mode == current ? const Icon(Icons.check_rounded) : null,
                onTap: () {
                  notifier.setTheme(mode);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _themeName(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System default';
    }
  }

  IconData _themeIcon(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      default:
        return Icons.brightness_auto_rounded;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
