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

class _ReportsState extends State<Reports> {
  List<Map<String, dynamic>> reports = [];
  String _selectedPeriod = 'All';
  String _selectedType = 'All';
  String _sortBy = 'Date (Latest)';
  bool _isLoading = true;
  final ReportsService _reportsService = ReportsService();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('=== REPORTS PAGE: Loading reports from ReportsService ===');
      List<Map<String, dynamic>> loadedReports =
          await _reportsService.getAllReports();

      print('✅ SUCCESS: Loaded ${loadedReports.length} REAL DATA reports');

      // Display notification about real data
      if (mounted && loadedReports.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Showing ${loadedReports.length} real-time reports generated from your actual data'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      setState(() {
        reports = loadedReports;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR loading real reports: $e');
      setState(() {
        _isLoading = false;
      });

      // Check if we have any real data
      _checkRealDataAvailability();

      // Load dummy data as fallback
      _loadDummyReports();
    }
  }

  Future<void> _checkRealDataAvailability() async {
    try {
      print('=== CHECKING REAL DATA AVAILABILITY ===');

      // Check if user has any sales data
      final salesReport = await _reportsService.generateSalesReport();
      print('📊 Sales Report Data: ${salesReport['data']}');

      // Check if user has any product data
      final inventoryReport = await _reportsService.generateInventoryReport();
      print('📦 Inventory Report Data: ${inventoryReport['data']}');

      int totalSales = salesReport['data']['totalOrders'] ?? 0;
      int totalProducts = inventoryReport['data']['totalItems'] ?? 0;
      double salesAmount = salesReport['data']['totalSales'] ?? 0.0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Showing sample data as fallback.\n'
                'Real data available: $totalSales sales (\$${salesAmount.toStringAsFixed(2)}), $totalProducts products'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Error checking real data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ No real data available. Showing sample reports for demonstration.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _loadDummyReports() {
    print('=== LOADING DUMMY/SAMPLE DATA AS FALLBACK ===');

    // Simulate loading time
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '📋 Loaded sample reports for demonstration. Create sales in POS to see real data.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Dummy data for reports with more comprehensive information
      var dummyReports = [
        {
          "id": "R001",
          "title": "Monthly Sales Summary",
          "description": "Overall sales performance for the last month.",
          "type": "Sales",
          "date": DateTime.now().subtract(const Duration(days: 2)),
          "status": "Completed",
          "data": {
            "totalSales": 24500,
            "itemsSold": 132,
            "topProduct": "Paracetamol 500mg"
          }
        },
        {
          "id": "R002",
          "title": "Inventory Status Report",
          "description":
              "Current inventory levels and items that need reordering.",
          "type": "Inventory",
          "date": DateTime.now().subtract(const Duration(days: 5)),
          "status": "Completed",
          "data": {"totalItems": 246, "lowStock": 18, "outOfStock": 3}
        },
        {
          "id": "R003",
          "title": "Customer Insights",
          "description":
              "Analysis of customer behaviors and frequent purchases.",
          "type": "Customer",
          "date": DateTime.now().subtract(const Duration(days: 8)),
          "status": "Completed",
          "data": {
            "totalCustomers": 85,
            "newCustomers": 12,
            "repeatCustomers": 68
          }
        },
        {
          "id": "R004",
          "title": "Quarterly Financial Report",
          "description":
              "Financial performance for the last quarter including revenue and expenses.",
          "type": "Financial",
          "date": DateTime.now().subtract(const Duration(days: 15)),
          "status": "Completed",
          "data": {"revenue": 78400, "expenses": 52600, "profit": 25800}
        },
        {
          "id": "R005",
          "title": "Product Performance Analysis",
          "description": "Analysis of best and worst performing products.",
          "type": "Products",
          "date": DateTime.now().subtract(const Duration(days: 20)),
          "status": "Completed",
          "data": {
            "topSellingProduct": "Aspirin 300mg",
            "worstSellingProduct": "Vitamin B Complex",
            "totalProducts": 120
          }
        },
        {
          "id": "R006",
          "title": "Annual Business Overview",
          "description":
              "Comprehensive annual business overview with forecasts.",
          "type": "Financial",
          "date": DateTime.now().subtract(const Duration(days: 60)),
          "status": "Completed",
          "data": {
            "annualRevenue": 285000,
            "growthRate": "12.5%",
            "projectedGrowth": "15.2%"
          }
        },
        {
          "id": "R007",
          "title": "Supply Chain Performance",
          "description":
              "Analysis of supply chain efficiency and vendor relations.",
          "type": "Inventory",
          "date": DateTime.now().subtract(const Duration(days: 25)),
          "status": "Pending",
          "data": {
            "onTimeDelivery": "92%",
            "averageDeliveryTime": "3.2 days",
            "topVendor": "MediSupplier Inc."
          }
        },
      ];

      setState(() {
        reports = dummyReports;
        _isLoading = false;
      });
    });
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Reports',
            onPressed: _loadReports,
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
                      color: reports.any((r) =>
                              r['id']?.toString().startsWith('R0') == true)
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: reports.any((r) =>
                                  r['id']?.toString().startsWith('R0') == true)
                              ? Colors.orange.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          reports.any((r) =>
                                  r['id']?.toString().startsWith('R0') == true)
                              ? Icons.science
                              : Icons.verified,
                          color: reports.any((r) =>
                                  r['id']?.toString().startsWith('R0') == true)
                              ? Colors.orange
                              : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            reports.any((r) =>
                                    r['id']?.toString().startsWith('R0') ==
                                    true)
                                ? '📋 Showing sample reports for demonstration. Create sales in POS to see real data.'
                                : '✅ Showing real-time reports generated from your actual business data.',
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        if (reports.any((r) =>
                            r['id']?.toString().startsWith('R0') == true))
                          TextButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/pos'),
                            icon: const Icon(Icons.point_of_sale, size: 16),
                            label: const Text('Go to POS',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
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
