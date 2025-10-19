import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remote_mouse/providers/settings_provider.dart';
import 'package:remote_mouse/providers/theme_provider.dart';
import 'package:remote_mouse/widgets/onboarding_reset_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.read<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _SectionHeader(
            icon: Icons.palette_rounded,
            title: 'Appearance',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_rounded),
                              label: Text('Light'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_rounded),
                              label: Text('Dark'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_rounded),
                              label: Text('Auto'),
                            ),
                          ],
                          selected: {themeProvider.themeMode},
                          onSelectionChanged: (value) {
                            if (value.isNotEmpty) {
                              themeProvider.setThemeMode(value.first);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Controls Section
          _SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Controls',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                // const Divider(height: 1, indent: 16, endIndent: 16),
                // const OnboardingResetButton(), // Add this import at the top
                SwitchListTile(
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Vibrate on interactions'),
                  secondary: Icon(
                    Icons.vibration_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  value: settingsProvider.hapticFeedback,
                  onChanged: (value) =>
                      settingsProvider.setHapticFeedback(value),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Vertical Scrolling'),
                  subtitle: const Text('Enable vertical scroll wheel'),
                  secondary: Icon(
                    Icons.swap_vert_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  value: settingsProvider.verticalScrolling,
                  onChanged: (value) =>
                      settingsProvider.setVerticalScrolling(value),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Horizontal Scrolling'),
                  subtitle: const Text('Enable horizontal scroll wheel'),
                  secondary: Icon(
                    Icons.swap_horiz_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  value: settingsProvider.horizontalScrolling,
                  onChanged: (value) =>
                      settingsProvider.setHorizontalScrolling(value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sensitivity Section
          _SectionHeader(
            icon: Icons.speed_rounded,
            title: 'Sensitivity',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mouse_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mouse Sensitivity',
                          style: textTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          settingsProvider.mouseSensitivity.toStringAsFixed(1),
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: 0.5,
                    max: 5.0,
                    divisions: 45,
                    value: settingsProvider.mouseSensitivity,
                    label: settingsProvider.mouseSensitivity.toStringAsFixed(1),
                    onChanged: (value) =>
                        settingsProvider.setMouseSensitivity(value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.gesture_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scroll Sensitivity',
                          style: textTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          settingsProvider.scrollSensitivity.toStringAsFixed(1),
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: 0.2,
                    max: 2.0,
                    divisions: 18,
                    value: settingsProvider.scrollSensitivity,
                    label: settingsProvider.scrollSensitivity.toStringAsFixed(
                      1,
                    ),
                    onChangeEnd: (value) =>
                        settingsProvider.setScrollSensitivity(value),
                    onChanged: (value) =>
                        settingsProvider.setScrollSensitivity(value),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Desktop Client Section
          _SectionHeader(
            icon: Icons.computer_rounded,
            title: 'Desktop Client',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.desktop_windows_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Download Desktop App'),
                  subtitle: const Text('Install the companion app on your PC'),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    launchUrl(
                      Uri.parse(
                        "https://github.com.waniathar/remote_mouse_server/blob/main/README.md",
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.help_outline_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Setup Guide'),
                  subtitle: const Text('Learn how to connect your devices'),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    launchUrl(
                      Uri.parse(
                        "https://github.com.waniathar/remote_mouse_server/blob/main/README.md",
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _SectionHeader(
            icon: Icons.info_rounded,
            title: 'About',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.mouse_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('Remote Mouse'),
                  subtitle: Text('Version $appVersion (Build $appBuild)'),
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.bug_report_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Report an Issue'),
                  subtitle: const Text('Help us improve the app'),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () async {
                    // TODO: Replace with your actual issues URL
                    final uri = Uri.parse(
                      'https://github.com/waniathar/remote_mouse_client/issues',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
                Visibility(
                  visible: false,
                  child: const Divider(height: 1, indent: 16, endIndent: 16),
                ),
                Visibility(
                  visible: false, //Intentionally kept hidden
                  child: ListTile(
                    leading: Icon(
                      Icons.privacy_tip_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Privacy Policy'),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      // TODO: Navigate to privacy policy
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.gavel_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Licenses'),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Remote Mouse',
                      applicationVersion: appVersion,
                      applicationIcon: Icon(
                        Icons.mouse_rounded,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Developer Section
          _SectionHeader(
            icon: Icons.person_rounded,
            title: 'Developer',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Athar Wani',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Flutter Developer',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      _SocialButton(
                        icon: Icons.web,
                        label: 'X/Twitter',
                        onTap: () {
                          final uri = Uri.parse(
                            'https://twitter.com/waniatharr',
                          );
                          launchUrl(uri);
                        },
                      ),
                      _SocialButton(
                        icon: Icons.code_rounded,
                        label: 'GitHub',
                        onTap: () {
                          final uri = Uri.parse('https://github.com/waniathar');
                          launchUrl(uri);
                        },
                      ),
                      _SocialButton(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        onTap: () {
                          final uri = Uri.parse(
                            'mailto:atharwani001@gmail.com',
                          );
                          launchUrl(uri);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'Made with ❤️ using Flutter',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showAboutDialog(
      context: context,
      applicationName: 'Remote Mouse',
      applicationVersion: appVersion,
      applicationIcon: Icon(
        Icons.mouse_rounded,
        size: 48,
        color: colorScheme.primary,
      ),
      applicationLegalese: '© 2024 Remote Mouse\nAll rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Control your computer remotely using your phone as a mouse and keyboard. '
          'Features gyroscope-based motion tracking for smooth cursor control.',
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.secondaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
    );
  }
}
