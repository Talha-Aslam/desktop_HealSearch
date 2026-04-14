import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _notificationsEnabled = true;
  bool _autoBackupEnabled = true;
  String _defaultView = 'Dashboard';
  String _dataRefreshRate = 'Every 30 minutes';
  String _language = 'English';
  bool _compactMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? true;
      _defaultView = prefs.getString('defaultView') ?? 'Dashboard';
      _dataRefreshRate =
          prefs.getString('dataRefreshRate') ?? 'Every 30 minutes';
      _language = prefs.getString('language') ?? 'English';
      _compactMode = prefs.getBool('compactMode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('autoBackupEnabled', _autoBackupEnabled);
    await prefs.setString('defaultView', _defaultView);
    await prefs.setString('dataRefreshRate', _dataRefreshRate);
    await prefs.setString('language', _language);
    await prefs.setBool('compactMode', _compactMode);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeProvider.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
            onPressed: () {
              _showResetConfirmation(context, themeProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            const Sidebar(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: themeProvider.scaffoldBackgroundColor,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Theme settings section
                    _buildSectionHeader(context, 'Theme Settings'),
                    Card(
                      color: themeProvider.cardBackgroundColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            title: 'Dark Mode',
                            subtitle: 'Enable dark theme for the application',
                            icon: Icons.dark_mode,
                            trailing: Switch(
                              value: themeProvider.isDarkMode,
                              activeThumbColor: themeProvider.gradientColors[0],
                              onChanged: (value) {
                                themeProvider.toggleTheme();
                              },
                            ),
                            onTap: () {
                              themeProvider.toggleTheme();
                            },
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Compact Mode',
                            subtitle: 'Reduce spacing in lists and views',
                            icon: Icons.format_size,
                            trailing: Switch(
                              value: _compactMode,
                              activeThumbColor: themeProvider.gradientColors[0],
                              onChanged: (value) {
                                setState(() {
                                  _compactMode = value;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _compactMode = !_compactMode;
                              });
                            },
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // General settings section
                    _buildSectionHeader(context, 'General Settings'),
                    Card(
                      color: themeProvider.cardBackgroundColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            title: 'Default View',
                            subtitle: 'Choose which screen to show on startup',
                            icon: Icons.home,
                            trailing: DropdownButton<String>(
                              value: _defaultView,
                              dropdownColor: themeProvider.cardBackgroundColor,
                              style: TextStyle(color: themeProvider.textColor),
                              underline: Container(
                                height: 0,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _defaultView = newValue;
                                  });
                                }
                              },
                              items: <String>[
                                'Dashboard',
                                'Products',
                                'Orders',
                                'Reports',
                                'Analytics'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Language',
                            subtitle: 'Choose your preferred language',
                            icon: Icons.language,
                            trailing: DropdownButton<String>(
                              value: _language,
                              dropdownColor: themeProvider.cardBackgroundColor,
                              style: TextStyle(color: themeProvider.textColor),
                              underline: Container(
                                height: 0,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _language = newValue;
                                  });
                                }
                              },
                              items: <String>[
                                'English',
                                'Spanish',
                                'French',
                                'German',
                                'Arabic'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Data Refresh Rate',
                            subtitle: 'How often to refresh data automatically',
                            icon: Icons.refresh,
                            trailing: DropdownButton<String>(
                              value: _dataRefreshRate,
                              dropdownColor: themeProvider.cardBackgroundColor,
                              style: TextStyle(color: themeProvider.textColor),
                              underline: Container(
                                height: 0,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _dataRefreshRate = newValue;
                                  });
                                }
                              },
                              items: <String>[
                                'Every 5 minutes',
                                'Every 15 minutes',
                                'Every 30 minutes',
                                'Every hour',
                                'Manual refresh only'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notifications section
                    _buildSectionHeader(context, 'Notifications & Data'),
                    Card(
                      color: themeProvider.cardBackgroundColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            title: 'Notifications',
                            subtitle: 'Enable or disable system notifications',
                            icon: Icons.notifications,
                            trailing: Switch(
                              value: _notificationsEnabled,
                              activeThumbColor: themeProvider.gradientColors[0],
                              onChanged: (value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _notificationsEnabled = !_notificationsEnabled;
                              });
                            },
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Automatic Backup',
                            subtitle: 'Automatically backup your data daily',
                            icon: Icons.backup,
                            trailing: Switch(
                              value: _autoBackupEnabled,
                              activeThumbColor: themeProvider.gradientColors[0],
                              onChanged: (value) {
                                setState(() {
                                  _autoBackupEnabled = value;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _autoBackupEnabled = !_autoBackupEnabled;
                              });
                            },
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Backup Now',
                            subtitle: 'Create a manual backup of all your data',
                            icon: Icons.save,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Backup started...'),
                                ),
                              );
                              // Simulate backup process
                              Future.delayed(const Duration(seconds: 2), () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Backup completed successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              });
                            },
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Clear Cache',
                            subtitle: 'Remove temporary files to free up space',
                            icon: Icons.cleaning_services,
                            onTap: () {
                              _showClearCacheDialog(context, themeProvider);
                            },
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // About section
                    _buildSectionHeader(context, 'About'),
                    Card(
                      color: themeProvider.cardBackgroundColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            title: 'App Version',
                            subtitle: 'v1.0.0 (Build 2025.05.08)',
                            icon: Icons.info,
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Terms of Service',
                            subtitle: 'Read the terms and conditions',
                            icon: Icons.description,
                            onTap: () {
                              _showTermsDialog(context, themeProvider);
                            },
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Privacy Policy',
                            subtitle: 'How we handle your data',
                            icon: Icons.privacy_tip,
                            onTap: () {
                              _showPrivacyDialog(context, themeProvider);
                            },
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            themeProvider: themeProvider,
                          ),
                          _buildDivider(),
                          _buildSettingTile(
                            title: 'Check for Updates',
                            subtitle: 'Check if a new version is available',
                            icon: Icons.system_update,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('You have the latest version'),
                                ),
                              );
                            },
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.gradientColors[0],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: themeProvider.gradientColors[0],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    required ThemeProvider themeProvider,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeProvider.gradientColors[0].withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: themeProvider.gradientColors[0],
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: themeProvider.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: themeProvider.textColor.withOpacity(0.7),
          fontSize: 13,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
    );
  }

  void _showClearCacheDialog(
      BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardBackgroundColor,
        title: Text(
          'Clear Cache',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: Text(
          'This will clear all temporary files. Your data will not be affected. Do you want to continue?',
          style: TextStyle(color: themeProvider.textColor.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.textColor.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.gradientColors[0],
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(
      BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardBackgroundColor,
        title: Text(
          'Reset to Defaults',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: Text(
          'This will reset all settings to their default values. Do you want to continue?',
          style: TextStyle(color: themeProvider.textColor.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.textColor.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notificationsEnabled = true;
                _autoBackupEnabled = true;
                _defaultView = 'Dashboard';
                _dataRefreshRate = 'Every 30 minutes';
                _language = 'English';
                _compactMode = false;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardBackgroundColor,
        title: Text(
          'Terms of Service',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.4,
          child: SingleChildScrollView(
            child: Text(
              'This is a sample Terms of Service document. In a real application, this would contain the actual legal terms and conditions that users must agree to when using the application.\n\n'
              'The terms would typically cover topics such as:\n\n'
              '1. User Responsibilities\n'
              '2. Acceptable Use Policy\n'
              '3. Intellectual Property Rights\n'
              '4. Limitation of Liability\n'
              '5. Governing Law\n'
              '6. Changes to Terms\n'
              '7. Termination Policy\n\n'
              'By using this application, you agree to these terms and conditions.',
              style: TextStyle(color: themeProvider.textColor.withOpacity(0.8)),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.gradientColors[0],
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardBackgroundColor,
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.4,
          child: SingleChildScrollView(
            child: Text(
              'This is a sample Privacy Policy document. In a real application, this would contain the actual privacy policy that explains how user data is collected, used, and protected.\n\n'
              'The policy would typically cover topics such as:\n\n'
              '1. What personal data is collected\n'
              '2. How data is used and processed\n'
              '3. Data storage and security measures\n'
              '4. Third-party sharing policies\n'
              '5. User rights regarding their data\n'
              '6. Cookies and tracking technologies\n'
              '7. Changes to the privacy policy\n\n'
              'We are committed to protecting your privacy and ensuring that your personal information is handled in a safe and responsible manner.',
              style: TextStyle(color: themeProvider.textColor.withOpacity(0.8)),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.gradientColors[0],
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
