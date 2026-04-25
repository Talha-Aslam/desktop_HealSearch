import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/reports_service.dart';
import 'package:intl/intl.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  _ReportsState createState() => _ReportsState();
}

class _ReportsState extends State<Reports> with WidgetsBindingObserver {
  List<Map<String, dynamic>> reports = [];
  String _selectedPeriod = 'All';
  String _selectedType = 'All';
  String _sortBy = 'Date (Latest)';
  bool _isLoading = true;
  bool _isRefreshing = false;
  DateTime? _lastRefreshedAt;
  Timer? _autoRefreshTimer;
  final ReportsService _reportsService = ReportsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReports();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadReports(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadReports(silent: true);
    }
  }

  Future<void> _loadReports({bool silent = false}) async {
    try {
      if (!silent && mounted) {
        setState(() {
          _isLoading = true;
        });
      } else if (mounted) {
        setState(() {
          _isRefreshing = true;
        });
      }

      List<Map<String, dynamic>> loadedReports =
          await _reportsService.getAllReports();

      if (!mounted) return;

      setState(() {
        reports = loadedReports;
        _isLoading = false;
        _isRefreshing = false;
        _lastRefreshedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load live reports: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showReportDetails(
      Map<String, dynamic> report, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: themeProvider.cardBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Fixed at top
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getReportTypeColor(report['type'])
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getReportTypeIcon(report['type']),
                        color: _getReportTypeColor(report['type']),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report['title'],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Report #${report['id']} • ${DateFormat('MMM dd, yyyy').format(report['date'])}',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.textColor.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: report['status'] == 'Completed'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        report['status'],
                        style: TextStyle(
                          color: report['status'] == 'Completed'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.textColor.withOpacity(0.8),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Data points
                        Text(
                          'Key Metrics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Data grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: report['data'].length,
                          itemBuilder: (context, index) {
                            String key = report['data'].keys.elementAt(index);
                            dynamic value = report['data'][key];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatKey(key),
                                    style: TextStyle(
                                      color: themeProvider.textColor
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      _formatValue(value),
                                      style: TextStyle(
                                        color: themeProvider.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Actions - Fixed at bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: themeProvider.textColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredReports() {
    return reports.where((report) {
      bool matchesPeriod = _selectedPeriod == 'All' ||
          (_selectedPeriod == 'This Week' &&
              report['date']
                  .isAfter(DateTime.now().subtract(const Duration(days: 7)))) ||
          (_selectedPeriod == 'This Month' &&
              report['date'].isAfter(
                  DateTime.now().subtract(const Duration(days: 30)))) ||
          (_selectedPeriod == 'This Quarter' &&
              report['date']
                  .isAfter(DateTime.now().subtract(const Duration(days: 90))));

      bool matchesType =
          _selectedType == 'All' || report['type'] == _selectedType;

      return matchesPeriod && matchesType;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'Date (Latest)') {
          return b['date'].compareTo(a['date']);
        } else if (_sortBy == 'Date (Oldest)') {
          return a['date'].compareTo(b['date']);
        } else if (_sortBy == 'Title (A-Z)') {
          return a['title'].compareTo(b['title']);
        } else {
          return a['type'].compareTo(b['type']);
        }
      });
  }

  String _formatKey(String key) {
    // Convert camelCase or snake_case to Title Case with spaces
    String result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );

    // Replace underscores with spaces
    result = result.replaceAll('_', ' ');

    // Capitalize first letter
    result = '${result[0].toUpperCase()}${result.substring(1)}';

    return result;
  }

  String _formatValue(dynamic value) {
    if (value is num) {
      // Format numbers with proper decimal places
      if (value is double) {
        // Check if it's a whole number
        if (value == value.roundToDouble()) {
          return value.toInt().toString();
        } else {
          // Format with 2 decimal places for currency/financial values
          return value.toStringAsFixed(2);
        }
      } else {
        return value.toString();
      }
    }
    return value.toString();
  }

  IconData _getReportTypeIcon(String type) {
    switch (type) {
      case 'Sales':
        return Icons.point_of_sale;
      case 'Inventory':
        return Icons.inventory;
      case 'Customer':
        return Icons.people;
      case 'Financial':
        return Icons.attach_money;
      case 'Products':
        return Icons.category;
      default:
        return Icons.description;
    }
  }

  Color _getReportTypeColor(String type) {
    switch (type) {
      case 'Sales':
        return Colors.blue;
      case 'Inventory':
        return Colors.purple;
      case 'Customer':
        return Colors.orange;
      case 'Financial':
        return Colors.green;
      case 'Products':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final filteredReports = _getFilteredReports();

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
          'Business Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Reports',
            onPressed: _isRefreshing ? null : () => _loadReports(),
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
              child: Column(
                children: [
                  // Data Source Indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isRefreshing ? Icons.sync : Icons.verified,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _lastRefreshedAt == null
                                ? 'Loading live reports from your actual business data...'
                                : '✅ Showing live reports from your actual business data. Last refreshed at ${DateFormat('HH:mm:ss').format(_lastRefreshedAt!)}',
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        if (_lastRefreshedAt != null)
                          TextButton.icon(
                            onPressed: _isRefreshing
                                ? null
                                : () => _loadReports(silent: true),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Filter bar
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeProvider.cardBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Time period filter
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Period',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedPeriod,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    filled: true,
                                    fillColor: themeProvider.isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'All', child: Text('All Time')),
                                    DropdownMenuItem(
                                        value: 'This Week',
                                        child: Text('This Week')),
                                    DropdownMenuItem(
                                        value: 'This Month',
                                        child: Text('This Month')),
                                    DropdownMenuItem(
                                        value: 'This Quarter',
                                        child: Text('This Quarter')),
                                  ],
                                  style:
                                      TextStyle(color: themeProvider.textColor),
                                  dropdownColor:
                                      themeProvider.cardBackgroundColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPeriod = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Report type filter
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report Type',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedType,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    filled: true,
                                    fillColor: themeProvider.isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'All', child: Text('All Types')),
                                    DropdownMenuItem(
                                        value: 'Sales', child: Text('Sales')),
                                    DropdownMenuItem(
                                        value: 'Inventory',
                                        child: Text('Inventory')),
                                    DropdownMenuItem(
                                        value: 'Customer',
                                        child: Text('Customer')),
                                    DropdownMenuItem(
                                        value: 'Financial',
                                        child: Text('Financial')),
                                    DropdownMenuItem(
                                        value: 'Products',
                                        child: Text('Products')),
                                  ],
                                  style:
                                      TextStyle(color: themeProvider.textColor),
                                  dropdownColor:
                                      themeProvider.cardBackgroundColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Sort by filter
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sort By',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: _sortBy,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    filled: true,
                                    fillColor: themeProvider.isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Date (Latest)',
                                        child: Text('Date (Latest)')),
                                    DropdownMenuItem(
                                        value: 'Date (Oldest)',
                                        child: Text('Date (Oldest)')),
                                    DropdownMenuItem(
                                        value: 'Title (A-Z)',
                                        child: Text('Title (A-Z)')),
                                    DropdownMenuItem(
                                        value: 'Type', child: Text('Type')),
                                  ],
                                  style:
                                      TextStyle(color: themeProvider.textColor),
                                  dropdownColor:
                                      themeProvider.cardBackgroundColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _sortBy = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reports list
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: themeProvider.gradientColors[0],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading reports...',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredReports.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 64,
                                      color: themeProvider.textColor
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reports found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: themeProvider.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try changing your filters',
                                      style: TextStyle(
                                        color: themeProvider.textColor
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: filteredReports.length,
                                itemBuilder: (context, index) {
                                  final report = filteredReports[index];

                                  return Card(
                                    color: themeProvider.cardBackgroundColor,
                                    elevation: 2.0,
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () => _showReportDetails(
                                          report, themeProvider),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // Report icon
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: _getReportTypeColor(
                                                        report['type'])
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                _getReportTypeIcon(
                                                    report['type']),
                                                color: _getReportTypeColor(
                                                    report['type']),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Report details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    report['title'],
                                                    style: TextStyle(
                                                      color: themeProvider
                                                          .textColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    report['description'],
                                                    style: TextStyle(
                                                      color: themeProvider
                                                          .textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getReportTypeColor(
                                                                      report[
                                                                          'type'])
                                                                  .withOpacity(
                                                                      0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                          report['type'],
                                                          style: TextStyle(
                                                            color:
                                                                _getReportTypeColor(
                                                                    report[
                                                                        'type']),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                          'Report #${report['id']}',
                                                          style: TextStyle(
                                                            color: themeProvider
                                                                .textColor
                                                                .withOpacity(
                                                                    0.5),
                                                            fontSize: 12,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status and date
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: report['status'] ==
                                                            'Completed'
                                                        ? Colors.green
                                                            .withOpacity(0.2)
                                                        : Colors.orange
                                                            .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    report['status'],
                                                    style: TextStyle(
                                                      color: report['status'] ==
                                                              'Completed'
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  DateFormat('MMM dd, yyyy')
                                                      .format(report['date']),
                                                  style: TextStyle(
                                                    color: themeProvider
                                                        .textColor
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),

                  // Summary bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.cardBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSummaryItem(
                            context,
                            'Total Reports',
                            reports.length.toString(),
                            Icons.description,
                          ),
                          _buildSummaryItem(
                            context,
                            'Sales Reports',
                            reports
                                .where((r) => r['type'] == 'Sales')
                                .length
                                .toString(),
                            Icons.point_of_sale,
                          ),
                          _buildSummaryItem(
                            context,
                            'Financial Reports',
                            reports
                                .where((r) => r['type'] == 'Financial')
                                .length
                                .toString(),
                            Icons.attach_money,
                          ),
                          _buildSummaryItem(
                            context,
                            'This Month',
                            reports
                                .where((r) => r['date'].isAfter(DateTime.now()
                                    .subtract(const Duration(days: 30))))
                                .length
                                .toString(),
                            Icons.today,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Generate new report
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'New Report',
            text: 'Your report is being generated. It will be available soon.',
            confirmBtnColor: themeProvider.gradientColors[0],
            backgroundColor: themeProvider.cardBackgroundColor,
            titleColor: themeProvider.textColor,
            textColor: themeProvider.textColor.withOpacity(0.8),
          );
        },
        backgroundColor: themeProvider.gradientColors[0],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String title, String value, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      width: 120, // Fixed width to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: themeProvider.gradientColors[0],
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              color: themeProvider.textColor.withOpacity(0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
