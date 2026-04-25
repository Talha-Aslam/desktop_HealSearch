import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:desktop_search_a_holic/stock_alert_service.dart';

class StockAlertsPage extends StatefulWidget {
  const StockAlertsPage({super.key});

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Ensure monitoring is started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockAlertService =
          Provider.of<StockAlertService>(context, listen: false);
      if (!stockAlertService.isMonitoring) {
        stockAlertService.startMonitoring();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Stock Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<StockAlertService>(
            builder: (context, stockAlertService, child) {
              return IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => stockAlertService.checkAllProducts(),
                tooltip: 'Refresh Alerts',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Alerts'),
            Tab(text: 'Critical'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Out of Stock'),
          ],
        ),
      ),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Container(
              color: themeProvider.scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Alert Summary Cards
                  _buildAlertSummaryCards(themeProvider),

                  // Category Filter
                  _buildCategoryFilter(themeProvider),

                  // Tab View
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllAlertsTab(),
                        _buildCriticalAlertsTab(),
                        _buildLowStockAlertsTab(),
                        _buildOutOfStockAlertsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSummaryCards(ThemeProvider themeProvider) {
    return Consumer<StockAlertService>(
      builder: (context, stockAlertService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Alerts',
                  stockAlertService.totalAlerts.toString(),
                  Icons.notifications,
                  themeProvider.gradientColors[0],
                  themeProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Out of Stock',
                  stockAlertService.outOfStockAlerts.toString(),
                  Icons.dangerous,
                  Colors.red,
                  themeProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Critical',
                  stockAlertService.criticalAlerts.toString(),
                  Icons.warning,
                  Colors.orange,
                  themeProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Low Stock',
                  stockAlertService.lowStockAlerts.toString(),
                  Icons.warning_amber,
                  Colors.yellow.shade700,
                  themeProvider,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Card(
      color: themeProvider.cardBackgroundColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: themeProvider.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeProvider themeProvider) {
    // Get unique categories from alerts
    return Consumer<StockAlertService>(
      builder: (context, stockAlertService, child) {
        final categories = ['All'];
        final alertCategories = stockAlertService.activeAlerts
            .map((alert) => alert.category)
            .toSet()
            .toList();
        categories.addAll(alertCategories);

        if (categories.length <= 1) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Filter by Category: ',
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(color: themeProvider.textColor),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'All';
                  });
                },
                dropdownColor: themeProvider.cardBackgroundColor,
                style: TextStyle(color: themeProvider.textColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllAlertsTab() {
    return Consumer<StockAlertService>(
      builder: (context, stockAlertService, child) {
        List<StockAlert> alerts = _selectedCategory == 'All'
            ? stockAlertService.activeAlerts
            : stockAlertService.getAlertsByCategory(_selectedCategory);

        return _buildAlertsList(alerts);
      },
    );
  }

  Widget _buildCriticalAlertsTab() {
    return Consumer<StockAlertService>(
      builder: (context, stockAlertService, child) {
        List<StockAlert> alerts =
            stockAlertService.getAlertsBySeverity(AlertSeverity.critical);
        if (_selectedCategory != 'All') {
          alerts = alerts
              .where((alert) => alert.category == _selectedCategory)
              .toList();
        }
        return _buildAlertsList(alerts);
      },
    );
  }

  Widget _buildLowStockAlertsTab() {
    return Consumer<StockAlertService>(
      builder: (context, stockAlertService, child) {
        List<StockAlert> alerts =
            stockAlertService.getAlertsBySeverity(AlertSeverity.warning);
        if (_selectedCategory != 'All') {
          alerts = alerts
              .where((alert) => alert.category == _selectedCategory)
              .toList();
        }
        return _buildAlertsList(alerts);
      },
    );
  }

  Widget _buildOutOfStockAlertsTab() {
    return Consumer<StockAlertService>(
      builder: (context, stockAlertService, child) {
        List<StockAlert> alerts =
            stockAlertService.getAlertsBySeverity(AlertSeverity.danger);
        if (_selectedCategory != 'All') {
          alerts = alerts
              .where((alert) => alert.category == _selectedCategory)
              .toList();
        }
        return _buildAlertsList(alerts);
      },
    );
  }

  Widget _buildAlertsList(List<StockAlert> alerts) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final sortedAlerts = List<StockAlert>.from(alerts);

    if (sortedAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No alerts in this category',
              style: TextStyle(
                fontSize: 18,
                color: themeProvider.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Sort alerts by severity (most critical first) and then by time
    sortedAlerts.sort((a, b) {
      // First sort by severity (danger > critical > warning)
      final severityOrder = {
        AlertSeverity.danger: 0,
        AlertSeverity.critical: 1,
        AlertSeverity.warning: 2,
      };
      final severityComparison = (severityOrder[a.severity] ?? 3)
          .compareTo(severityOrder[b.severity] ?? 3);

      if (severityComparison != 0) return severityComparison;

      // Then sort by timestamp (newest first)
      return b.timestamp.compareTo(a.timestamp);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedAlerts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final alert = sortedAlerts[index];
        return _buildDetailedAlertCard(alert, themeProvider);
      },
    );
  }

  Widget _buildDetailedAlertCard(
      StockAlert alert, ThemeProvider themeProvider) {
    return Card(
      color: themeProvider.cardBackgroundColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alert.severity.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    alert.severity.icon,
                    color: alert.severity.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor,
                        ),
                      ),
                      Text(
                        alert.category,
                        style: TextStyle(
                          color: themeProvider.textColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: alert.severity.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    alert.severity.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Alert message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alert.severity.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: alert.severity.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.message,
                      style: TextStyle(
                        color: alert.severity.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Details row
            Row(
              children: [
                _buildDetailChip(
                  'Current Stock: ${alert.currentStock}',
                  Icons.inventory,
                  alert.severity.color,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  alert.timeAgo,
                  Icons.access_time,
                  themeProvider.textColor.withOpacity(0.6),
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 12),

            // Action section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: themeProvider.gradientColors[0],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Action Required: ${alert.actionRequired}',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/editProduct',
                        arguments: {'productId': alert.productId},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.gradientColors[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Update Stock'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
