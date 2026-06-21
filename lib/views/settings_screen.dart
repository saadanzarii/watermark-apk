import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/theme_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  value: ThemeMode.system,
                  groupValue: themeViewModel.themeMode,
                  onChanged: (val) => themeViewModel.setThemeMode(val!),
                  secondary: const Icon(Icons.brightness_auto),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Theme'),
                  value: ThemeMode.light,
                  groupValue: themeViewModel.themeMode,
                  onChanged: (val) => themeViewModel.setThemeMode(val!),
                  secondary: const Icon(Icons.light_mode),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Theme'),
                  value: ThemeMode.dark,
                  groupValue: themeViewModel.themeMode,
                  onChanged: (val) => themeViewModel.setThemeMode(val!),
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Upcoming Features'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Cloud Sync'),
              subtitle: const Text('Coming soon in v2.0'),
              trailing: Switch(value: false, onChanged: null), // Disabled
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Watermark Studio Premium'),
                  subtitle: Text('Version 1.1.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star_rate),
                  title: const Text('Rate the App'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
