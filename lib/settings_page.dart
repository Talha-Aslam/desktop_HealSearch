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

class _SettingsPageState extends State<SettingsPage> {
  bool _autoBackupEnabled = true;
  double _fontSize = 13.0;
  bool _isDisposed = false;

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
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Reset to defaults',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Settings?'),
                      content: const Text(
                          'This will reset all settings to their default values.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _resetSettings();
                            Navigator.pop(context);
                          },
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
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Theme Section
                      _buildSectionHeader(context, 'Appearance'),
                      Card(
                        color: themeProvider.cardBackgroundColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Theme Mode Toggle
                              ListTile(
                                leading: Icon(
                                  themeProvider.isDarkMode
                                      ? Icons.dark_mode
                                      : Icons.light_mode,
                                  color: themeProvider.gradientColors[0],
                                ),
                                title: Text(
                                  'Theme Mode',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  themeProvider.isDarkMode
                                      ? 'Dark Mode'
                                      : 'Light Mode',
                                  style: TextStyle(
                                    color: themeProvider.textColor
                                        .withOpacity(0.7),
                                  ),
                                ),
                                trailing: Switch(
                                  value: themeProvider.isDarkMode,
                                  activeThumbColor:
                                      themeProvider.gradientColors[0],
                                  onChanged: (value) {
                                    themeProvider.toggleTheme();
                                  },
                                ),
                              ),

                              const Divider(),

                              // Theme Colors
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, bottom: 8, top: 8),
                                child: Text(
                                  'Theme Colors',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.textColor,
                                  ),
                                ),
                              ),

                              // Theme Presets with fixed height to prevent overflow
                              Container(
                                height:
                                    90, // Increased height to avoid overflow
                                margin: const EdgeInsets.only(
                                    bottom: 8), // Added margin
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _presetThemes.length,
                                  itemBuilder: (context, index) {
                                    final theme = _presetThemes[index];
                                    bool isSelected =
                                        themeProvider.gradientColors[0] ==
                                            theme['primary'];

                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () {
                                          themeProvider.setGradientColors([
                                            theme['primary'],
                                            theme['secondary'],
                                          ]);
                                        },
                                        child: Column(
                                          mainAxisSize: MainAxisSize
                                              .min, // Added to minimize column height
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    theme['primary'],
                                                    theme['secondary'],
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              theme['name'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: themeProvider.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const Divider(),

                              // Font Size
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.text_fields,
                                      color: themeProvider.gradientColors[0],
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Font Size: ${_fontSize.clamp(10.0, 17.0).toInt()}',
                                      style: TextStyle(
                                        color: themeProvider.textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Slider(
                                value: _fontSize.clamp(10.0, 17.0),
                                min: 10,
                                max: 17,
                                divisions: 7,
                                activeColor: themeProvider.gradientColors[0],
                                inactiveColor: themeProvider.gradientColors[0]
                                    .withOpacity(0.3),
                                label: _fontSize
                                    .clamp(10.0, 17.0)
                                    .toInt()
                                    .toString(),
                                onChanged: (value) {
                                  if (_isDisposed) return;

                                  setState(() {
                                    _fontSize = value;
                                  });
                                  // Debug: print the font size change
                                  print('Font size changed to: $value');
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

                              // Text Size Preview
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode
                                      ? Colors.black26
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'This is a preview of your selected text size',
                                      style: themeProvider.bodyTextStyle,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Current font size: ${themeProvider.fontSize.toStringAsFixed(1)}px',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: themeProvider.textColor
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Data
                      _buildSectionHeader(context, 'Data'),
                      Card(
                        color: themeProvider.cardBackgroundColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Auto Backup Toggle
                              ListTile(
                                leading: Icon(
                                  Icons.backup,
                                  color: themeProvider.gradientColors[0],
                                ),
                                title: Text(
                                  'Auto Backup',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  _autoBackupEnabled
                                      ? 'Daily automatic backup enabled'
                                      : 'Daily automatic backup disabled',
                                  style: TextStyle(
                                    color: themeProvider.textColor
                                        .withOpacity(0.7),
                                  ),
                                ),
                                trailing: Switch(
                                  value: _autoBackupEnabled,
                                  activeThumbColor:
                                      themeProvider.gradientColors[0],
                                  onChanged: (value) async {
                                    if (_isDisposed) return;

                                    setState(() {
                                      _autoBackupEnabled = value;
                                    });

                                    try {
                                      // Save preference and update auto backup service
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setBool(
                                          'auto_backup_enabled', value);

                                      if (value) {
                                        await _autoBackupService.initialize();
                                      } else {
                                        _autoBackupService.dispose();
                                      }
                                    } catch (e) {
                                      print(
                                          'Error updating auto backup setting: $e');
                                      // Show user-friendly error message
                                      if (mounted && !_isDisposed) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to update auto backup setting: $e'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),

                              const Divider(),

                              // Manual Backup Button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (_isDisposed) return;

                                    // Store context safely before any async operations
                                    final pageContext = context;
                                    if (!mounted) return;

                                    // Show loading dialog
                                    showDialog(
                                      context: pageContext,
                                      barrierDismissible: false,
                                      builder: (dialogContext) => AlertDialog(
                                        backgroundColor:
                                            themeProvider.cardBackgroundColor,
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                              color: themeProvider
                                                  .gradientColors[0],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Creating backup...',
                                              style: TextStyle(
                                                  color:
                                                      themeProvider.textColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );

                                    try {
                                      // Perform actual backup using export service with timeout
                                      bool success =
                                          await ExportService.createBackup()
                                              .timeout(
                                        const Duration(seconds: 30),
                                        onTimeout: () {
                                          throw TimeoutException(
                                              'Backup operation timed out after 30 seconds');
                                        },
                                      );

                                      if (mounted &&
                                          !_isDisposed &&
                                          Navigator.canPop(pageContext)) {
                                        Navigator.pop(
                                            pageContext); // Close loading dialog
                                      }

                                      if (success && mounted && !_isDisposed) {
                                        ScaffoldMessenger.of(pageContext)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Backup created successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else if (mounted && !_isDisposed) {
                                        ScaffoldMessenger.of(pageContext)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Backup failed. Check console logs for details. Make sure you are logged in.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted && !_isDisposed) {
                                        if (Navigator.canPop(pageContext)) {
                                          Navigator.pop(
                                              pageContext); // Close loading dialog
                                        }

                                        ScaffoldMessenger.of(pageContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Backup failed: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        themeProvider.gradientColors[0],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.backup),
                                  label: const Text('Create Backup Now'),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_isDisposed) return;

                                    // Store the main page context safely before opening dialog
                                    final mainPageContext = context;
                                    if (!mounted) return;

                                    showDialog(
                                      context: mainPageContext,
                                      builder: (dialogContext) => AlertDialog(
                                        backgroundColor:
                                            themeProvider.cardBackgroundColor,
                                        title: Text(
                                          'Export Data',
                                          style: TextStyle(
                                              color: themeProvider.textColor),
                                        ),
                                        content: Text(
                                          'Choose a format to export your data. Files will be saved to:\nDocuments/HealSearch/Exports/',
                                          style: TextStyle(
                                              color: themeProvider.textColor),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () async {
                                              if (_isDisposed) return;

                                              // Use the main page context, not dialog context
                                              if (!mounted) return;

                                              Navigator.pop(dialogContext);

                                              // Show loading dialog with cancel option
                                              bool operationCancelled = false;
                                              if (!mounted || _isDisposed) {
                                                return;
                                              }

                                              showDialog(
                                                context: mainPageContext,
                                                barrierDismissible: false,
                                                builder:
                                                    (loadingDialogContext) =>
                                                        AlertDialog(
                                                  backgroundColor: themeProvider
                                                      .cardBackgroundColor,
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      CircularProgressIndicator(
                                                        color: themeProvider
                                                            .gradientColors[0],
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      Text(
                                                        'Exporting data as CSV...',
                                                        style: TextStyle(
                                                            color: themeProvider
                                                                .textColor),
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      TextButton(
                                                        onPressed: () {
                                                          operationCancelled =
                                                              true;
                                                          if (Navigator.canPop(
                                                              loadingDialogContext)) {
                                                            Navigator.pop(
                                                                loadingDialogContext);
                                                          }
                                                        },
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );

                                              try {
                                                // Add timeout to prevent hanging
                                                bool success =
                                                    await ExportService
                                                            .exportAllData()
                                                        .timeout(
                                                  const Duration(seconds: 30),
                                                  onTimeout: () {
                                                    throw TimeoutException(
                                                        'Export operation timed out after 30 seconds');
                                                  },
                                                );

                                                if (mounted &&
                                                    !operationCancelled &&
                                                    !_isDisposed &&
                                                    Navigator.canPop(
                                                        mainPageContext)) {
                                                  Navigator.pop(
                                                      mainPageContext); // Close loading dialog
                                                }

                                                if (success &&
                                                    mounted &&
                                                    !operationCancelled &&
                                                    !_isDisposed) {
                                                  ScaffoldMessenger.of(
                                                          mainPageContext)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              'Data exported successfully as CSV'),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            'Location: Documents/HealSearch/Exports/',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.9),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      duration: const Duration(
                                                          seconds: 5),
                                                    ),
                                                  );
                                                } else if (mounted &&
                                                    !operationCancelled &&
                                                    !_isDisposed) {
                                                  ScaffoldMessenger.of(
                                                          mainPageContext)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Export failed. Please try again.'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted &&
                                                    !operationCancelled &&
                                                    !_isDisposed) {
                                                  if (Navigator.canPop(
                                                      mainPageContext)) {
                                                    Navigator.pop(
                                                        mainPageContext); // Close loading dialog
                                                  }
                                                  ScaffoldMessenger.of(
                                                          mainPageContext)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Export failed: ${e.toString()}'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text('CSV'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (_isDisposed) return;
                                              if (!mounted) return;

                                              Navigator.pop(dialogContext);
                                              if (mounted && !_isDisposed) {
                                                ScaffoldMessenger.of(
                                                        mainPageContext)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Excel export coming soon...'),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Excel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (_isDisposed) return;
                                              if (!mounted) return;

                                              Navigator.pop(dialogContext);
                                              if (mounted && !_isDisposed) {
                                                ScaffoldMessenger.of(
                                                        mainPageContext)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'PDF export coming soon...'),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('PDF'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeProvider.isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    foregroundColor: themeProvider.textColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.download),
                                  label:
                                      const Text('Export Data (CSV/Excel/PDF)'),
                                ),
                              ),

                              // View Backup History Button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_isDisposed) return;
                                    Navigator.pushNamed(
                                        context, '/backup-history');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeProvider
                                        .gradientColors[0]
                                        .withOpacity(0.8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.history),
                                  label: const Text('View Backup History'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Privacy & Legal Section
                      _buildSectionHeader(context, 'Privacy & Legal'),
                      Card(
                        color: themeProvider.cardBackgroundColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Information note
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: themeProvider.gradientColors[0]
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: themeProvider.gradientColors[0]
                                        .withOpacity(0.3),
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
                                        'This section provides legal documents and privacy information. For data operations, use the Data section above.',
                                        style: TextStyle(
                                          color: themeProvider.textColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Privacy Policy Link
                              ListTile(
                                leading: Icon(
                                  Icons.privacy_tip,
                                  color: themeProvider.gradientColors[0],
                                ),
                                title: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'View our privacy policy and data handling practices',
                                  style: TextStyle(
                                    color: themeProvider.textColor
                                        .withOpacity(0.7),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color:
                                      themeProvider.textColor.withOpacity(0.5),
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPolicyPage(),
                                    ),
                                  );
                                },
                              ),

                              // Terms of Service Link
                              ListTile(
                                leading: Icon(
                                  Icons.description,
                                  color: themeProvider.gradientColors[0],
                                ),
                                title: Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'View terms and conditions of use',
                                  style: TextStyle(
                                    color: themeProvider.textColor
                                        .withOpacity(0.7),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color:
                                      themeProvider.textColor.withOpacity(0.5),
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsOfServicePage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // About Section
                      _buildSectionHeader(context, 'About'),
                      Card(
                        color: themeProvider.cardBackgroundColor,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.info,
                                  color: themeProvider.gradientColors[0],
                                ),
                                title: Text(
                                  'App Version',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '1.0.0',
                                  style: TextStyle(
                                    color: themeProvider.textColor
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.update,
                                  color: themeProvider.gradientColors[0],
                                ),
                                title: Text(
                                  'Check for Updates',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color:
                                      themeProvider.textColor.withOpacity(0.7),
                                ),
                                onTap: () {
                                  if (_isDisposed) return;

                                  // Store context safely
                                  final pageContext = context;
                                  if (!mounted) return;

                                  // Show a simulated update check dialog
                                  showDialog(
                                    context: pageContext,
                                    builder: (dialogContext) => AlertDialog(
                                      backgroundColor:
                                          themeProvider.cardBackgroundColor,
                                      title: Text(
                                        'Check for Updates',
                                        style: TextStyle(
                                            color: themeProvider.textColor),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color:
                                                themeProvider.gradientColors[0],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Checking for updates...',
                                            style: TextStyle(
                                                color: themeProvider.textColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  // Simulate update check
                                  Future.delayed(const Duration(seconds: 2),
                                      () {
                                    if (!mounted || _isDisposed) return;

                                    if (Navigator.canPop(pageContext)) {
                                      Navigator.pop(pageContext);
                                    }

                                    if (mounted && !_isDisposed) {
                                      showDialog(
                                        context: pageContext,
                                        builder: (dialogContext) => AlertDialog(
                                          backgroundColor:
                                              themeProvider.cardBackgroundColor,
                                          title: Text(
                                            'Update Status',
                                            style: TextStyle(
                                                color: themeProvider.textColor),
                                          ),
                                          content: Text(
                                            'You are running the latest version.',
                                            style: TextStyle(
                                                color: themeProvider.textColor),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dialogContext),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  });
                                },
                              ),
                              const Divider(),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 16.0),
                                  child: Text(
                                    '© 2025 HealSearch. All rights reserved.',
                                    style: TextStyle(
                                      color: themeProvider.textColor
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}
