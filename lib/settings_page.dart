import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:desktop_search_a_holic/auto_backup_service.dart';
import 'package:desktop_search_a_holic/export_service.dart';
import 'package:desktop_search_a_holic/privacy_policy_page.dart';
import 'package:desktop_search_a_holic/terms_of_service_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

extension ColorExtension on Color {
  /// Get the luminance of this color (0.0 to 1.0)
  double get luminance {
    return (0.299 * red + 0.587 * green + 0.114 * blue) / 255;
  }
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool _autoBackupEnabled = true;
  double _fontSize = 13.0;
  bool _isDisposed = false;
  late AnimationController _animationController;

  // Service instances
  final AutoBackupService _autoBackupService = AutoBackupService();

  // Store theme provider reference safely
  ThemeProvider? _themeProvider;

  final List<Map<String, dynamic>> _presetThemes = [
    {
      'name': 'Default Blue',
      'primary': Colors.blue,
      'secondary': Colors.lightBlueAccent,
    },
    {
      'name': 'Purple Elegance',
      'primary': Colors.purple,
      'secondary': Colors.purpleAccent,
    },
    {
      'name': 'Forest Green',
      'primary': Colors.green,
      'secondary': Colors.lightGreen,
    },
    {
      'name': 'Sunset Orange',
      'primary': Colors.deepOrange,
      'secondary': Colors.orange,
    },
    {
      'name': 'Ruby Red',
      'primary': Colors.red,
      'secondary': Colors.redAccent,
    },
    {
      'name': 'Teal Calm',
      'primary': Colors.teal,
      'secondary': Colors.tealAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Use a future to delay settings loading to ensure context is available
    Future.microtask(() {
      if (mounted && !_isDisposed) {
        _loadSettings();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely store the ThemeProvider reference when dependencies change
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if widget is still mounted and not disposed before accessing context
      if (!mounted || _isDisposed || _themeProvider == null) return;

      if (mounted && !_isDisposed) {
        setState(() {
          _autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? true;
          // Clamp font size to the valid range (10-17)
          _fontSize = _themeProvider!.fontSize.clamp(10.0, 17.0);
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      // Set default values if loading fails
      if (mounted && !_isDisposed) {
        setState(() {
          _autoBackupEnabled = true;
          _fontSize = 13.0;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if widget is still mounted and not disposed before accessing context
      if (!mounted || _isDisposed || _themeProvider == null) return;

      await prefs.setBool('auto_backup_enabled', _autoBackupEnabled);

      // Update font size through theme provider
      await _themeProvider!.setFontSize(_fontSize);

      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if widget is still mounted and not disposed before accessing context
      if (!mounted || _isDisposed || _themeProvider == null) return;

      if (mounted && !_isDisposed) {
        setState(() {
          _autoBackupEnabled = true;
          _fontSize = 13.0;
        });
      }

      await prefs.clear();
      // Reset font size in theme provider
      await _themeProvider!.setFontSize(13.0);

      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    } catch (e) {
      print('Error resetting settings: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting settings: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _themeProvider = null; // Clear the reference
    // Dispose of auto backup service to prevent memory leaks
    try {
      _autoBackupService.dispose();
    } catch (e) {
      print('Error disposing auto backup service: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
            elevation: 4,
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Reset to defaults',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: themeProvider.cardBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        'Reset Settings?',
                        style: TextStyle(color: themeProvider.textColor),
                      ),
                      content: Text(
                        'This will reset all settings to their default values.',
                        style: TextStyle(color: themeProvider.textColor),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _resetSettings();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save settings',
                onPressed: _saveSettings,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider.scaffoldBackgroundColor,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      // Theme Section
                      _buildSectionHeader(context, 'Appearance', Icons.palette),
                      _buildAppearanceCard(context, themeProvider),
                      const SizedBox(height: 32),

                      // Data
                      _buildSectionHeader(
                          context, 'Data & Backup', Icons.backup),
                      _buildDataCard(context, themeProvider),
                      const SizedBox(height: 32),

                      // Privacy & Legal Section
                      _buildSectionHeader(
                          context, 'Privacy & Legal', Icons.security),
                      _buildPrivacyCard(context, themeProvider),
                      const SizedBox(height: 32),

                      // About Section
                      _buildSectionHeader(context, 'About', Icons.info),
                      _buildAboutCard(context, themeProvider),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceCard(
      BuildContext context, ThemeProvider themeProvider) {
    return Card(
      color: themeProvider.cardBackgroundColor,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: themeProvider.gradientColors[0].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Theme Mode',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? 'Dark Mode Enabled'
                      : 'Light Mode Enabled',
                  style: TextStyle(
                    color: themeProvider.textColor.withOpacity(0.7),
                  ),
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  activeColor: themeProvider.gradientColors[0],
                  activeThumbColor: Colors.white,
                  inactiveThumbColor: Colors.grey,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Theme Colors
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                'Color Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Theme Presets
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presetThemes.length,
                itemBuilder: (context, index) {
                  final theme = _presetThemes[index];
                  bool isSelected =
                      themeProvider.gradientColors[0] == theme['primary'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: AnimatedScale(
                      scale: isSelected ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: InkWell(
                        onTap: () {
                          themeProvider.setGradientColors([
                            theme['primary'],
                            theme['secondary'],
                          ]);
                          _animationController.forward().then((_) {
                            _animationController.reverse();
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme['primary'],
                                    theme['secondary'],
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: theme['primary'].withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              theme['name'],
                              style: TextStyle(
                                fontSize: 11,
                                color: themeProvider.textColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Font Size
            Container(
              decoration: BoxDecoration(
                color: themeProvider.gradientColors[0].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: themeProvider.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.text_fields,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Font Size',
                              style: TextStyle(
                                color: themeProvider.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_fontSize.clamp(10.0, 17.0).toInt()}px - Current',
                              style: TextStyle(
                                color: themeProvider.textColor.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Slider(
                      value: _fontSize.clamp(10.0, 17.0),
                      min: 10,
                      max: 17,
                      divisions: 7,
                      activeColor: themeProvider.gradientColors[0],
                      inactiveColor:
                          themeProvider.gradientColors[0].withOpacity(0.2),
                      label: _fontSize.clamp(10.0, 17.0).toInt().toString(),
                      onChanged: (value) {
                        if (_isDisposed) return;

                        setState(() {
                          _fontSize = value;
                        });
                        // Immediately apply font size change with safety check
                        try {
                          if (mounted &&
                              !_isDisposed &&
                              _themeProvider != null) {
                            _themeProvider!.setFontSize(value);
                          }
                        } catch (e) {
                          print('Error applying font size: $e');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Text Size Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.black38
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: themeProvider.gradientColors[0].withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Preview of your selected text size',
                          style: TextStyle(
                            fontSize: _fontSize.clamp(10.0, 17.0),
                            color: themeProvider.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This updates in real-time',
                          style: TextStyle(
                            fontSize:
                                (_fontSize.clamp(10.0, 17.0) - 2).clamp(8, 15),
                            color: themeProvider.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      color: themeProvider.cardBackgroundColor,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto Backup Toggle
            Container(
              decoration: BoxDecoration(
                color: themeProvider.gradientColors[0].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.backup,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Auto Backup',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  _autoBackupEnabled
                      ? 'Daily automatic backup enabled'
                      : 'Daily automatic backup disabled',
                  style: TextStyle(
                    color: themeProvider.textColor.withOpacity(0.7),
                  ),
                ),
                trailing: Switch(
                  value: _autoBackupEnabled,
                  activeColor: themeProvider.gradientColors[0],
                  activeThumbColor: Colors.white,
                  onChanged: (value) async {
                    if (_isDisposed) return;

                    setState(() {
                      _autoBackupEnabled = value;
                    });

                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('auto_backup_enabled', value);

                      if (value) {
                        await _autoBackupService.initialize();
                      } else {
                        _autoBackupService.dispose();
                      }
                    } catch (e) {
                      print('Error updating auto backup setting: $e');
                      if (mounted && !_isDisposed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update setting: $e'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Manual Backup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_isDisposed) return;
                  final pageContext = context;
                  if (!mounted) return;

                  showDialog(
                    context: pageContext,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: themeProvider.cardBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: themeProvider.gradientColors[0],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Creating backup...',
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                        ],
                      ),
                    ),
                  );

                  try {
                    bool success = await ExportService.createBackup().timeout(
                      const Duration(seconds: 30),
                      onTimeout: () {
                        throw TimeoutException(
                            'Backup operation timed out after 30 seconds');
                      },
                    );

                    if (mounted &&
                        !_isDisposed &&
                        Navigator.canPop(pageContext)) {
                      Navigator.pop(pageContext);
                    }

                    if (success && mounted && !_isDisposed) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          content: const Text('Backup created successfully'),
                          backgroundColor: Colors.green.shade400,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else if (mounted && !_isDisposed) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Backup failed. Make sure you are logged in.'),
                          backgroundColor: Colors.red.shade400,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted && !_isDisposed) {
                      if (Navigator.canPop(pageContext)) {
                        Navigator.pop(pageContext);
                      }

                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          content: Text('Backup failed: ${e.toString()}'),
                          backgroundColor: Colors.red.shade400,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.gradientColors[0],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 3,
                ),
                icon: const Icon(Icons.backup),
                label: const Text(
                  'Create Backup Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Export Data Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_isDisposed) return;
                  final mainPageContext = context;
                  if (!mounted) return;

                  showDialog(
                    context: mainPageContext,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: themeProvider.cardBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        'Export Data',
                        style: TextStyle(color: themeProvider.textColor),
                      ),
                      content: Text(
                        'Choose a format to export your data. Files will be saved to:\nDocuments/HealSearch/Exports/',
                        style: TextStyle(color: themeProvider.textColor),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            if (mounted && !_isDisposed) {
                              ScaffoldMessenger.of(mainPageContext)
                                  .showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('Excel export coming soon...'),
                                  backgroundColor: Colors.orange.shade400,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.gradientColors[0],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      themeProvider.gradientColors[0].withOpacity(0.7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                icon: const Icon(Icons.download),
                label: const Text(
                  'Export Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // View Backup History Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_isDisposed) return;
                  Navigator.pushNamed(context, '/backup-history');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeProvider.gradientColors[0],
                  side: BorderSide(color: themeProvider.gradientColors[0]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.history),
                label: const Text(
                  'View Backup History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      color: themeProvider.cardBackgroundColor,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.gradientColors[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: themeProvider.gradientColors[0].withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: themeProvider.gradientColors[0],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This section provides legal documents and privacy information.',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Policy Link
            _buildPrivacyTile(
              context,
              themeProvider,
              'Privacy Policy',
              'View our privacy policy',
              Icons.privacy_tip,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Terms of Service Link
            _buildPrivacyTile(
              context,
              themeProvider,
              'Terms of Service',
              'View terms and conditions',
              Icons.description,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      color: themeProvider.cardBackgroundColor,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: themeProvider.gradientColors[0].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'App Version',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'v1.0.0 (Build 2025)',
                  style: TextStyle(
                    color: themeProvider.textColor.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: themeProvider.gradientColors[0].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.update,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Check for Updates',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: themeProvider.textColor.withOpacity(0.5),
                  size: 16,
                ),
                onTap: () {
                  if (_isDisposed) return;
                  final pageContext = context;
                  if (!mounted) return;

                  showDialog(
                    context: pageContext,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: themeProvider.cardBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: themeProvider.gradientColors[0],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Checking for updates...',
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                        ],
                      ),
                    ),
                  );

                  Future.delayed(const Duration(seconds: 2), () {
                    if (!mounted || _isDisposed) return;

                    if (Navigator.canPop(pageContext)) {
                      Navigator.pop(pageContext);
                    }

                    if (mounted && !_isDisposed) {
                      showDialog(
                        context: pageContext,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: themeProvider.cardBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            'Update Status',
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                          content: Text(
                            'You are running the latest version (v1.0.0).',
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    themeProvider.gradientColors[0],
                              ),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2025 HealSearch. All rights reserved.',
                style: TextStyle(
                  color: themeProvider.textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            color: themeProvider.gradientColors[0],
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.gradientColors[0].withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeProvider.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: themeProvider.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: themeProvider.textColor.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: themeProvider.textColor.withOpacity(0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
