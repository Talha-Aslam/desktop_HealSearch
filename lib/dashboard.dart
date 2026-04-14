import 'package:flutter/material.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sales_service.dart';
import 'package:desktop_search_a_holic/activity_service.dart';
import 'package:desktop_search_a_holic/stock_alert_service.dart';
import 'package:desktop_search_a_holic/stock_alerts_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final SalesService _salesService = SalesService();
  final ActivityService _activityService = ActivityService();
  Map<String, dynamic> _salesStats = {
    'totalSalesAmount': 0.0,
    'totalOrders': 0,
    'uniqueCustomers': 0,
    'topSellingProduct': 'N/A',
    'topSellingCount': 0,
  };
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // Start stock monitoring when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final stockAlertService =
            Provider.of<StockAlertService>(context, listen: false);
        if (!stockAlertService.isMonitoring) {
          stockAlertService.startMonitoring();
        }
        print('✅ StockAlertService found and monitoring started');
      } catch (e) {
        print('❌ Error accessing StockAlertService: $e');
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      // Load sales stats and activities in parallel
      final results = await Future.wait([
        _salesService.getSalesStats(),
        _activityService.getRecentActivities(),
      ]);

      if (!mounted) return;
      setState(() {
        _salesStats = results[0] as Map<String, dynamic>;
        _recentActivities = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

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
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Dashboard',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      color: themeProvider.cardBackgroundColor,
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.dashboard,
                                  size: 36,
                                  color: themeProvider.gradientColors[0],
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Welcome to the Dashboard',
                                  style: themeProvider.largeTextStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Here you can manage your products, view reports, and more.',
                              style: themeProvider.bodyTextStyle,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/reports');
                              },
                              icon: const Icon(Icons.analytics),
                              label: const Text('View Reports'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    themeProvider.gradientColors[0],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stock Alerts - Compact View
                    Consumer<StockAlertService>(
                      builder: (context, stockAlertService, child) {
                        return StockAlertsWidget(
                          showCompact: true,
                          onViewAll: () {
                            Navigator.pushNamed(context, '/stock-alerts');
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Statistics Row
                    Text(
                      'Statistics',
                      style: themeProvider.titleTextStyle.copyWith(
                        fontSize: themeProvider.fontSize + 6,
                      ),
                    ),
                    const SizedBox(height: 16), // Statistics Cards Grid
                    _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: themeProvider.gradientColors[0],
                            ),
                          )
                        : GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: size.width > 1200
                                ? 4
                                : (size.width > 800 ? 3 : 2),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard(
                                context,
                                'Products',
                                _salesStats['totalProducts']?.toString() ?? '0',
                                Icons.shopping_cart,
                                Colors.blue,
                              ),
                              _buildStatCard(
                                context,
                                'Orders',
                                _salesStats['totalOrders'].toString(),
                                Icons.shopping_basket,
                                Colors.green,
                              ),
                              _buildStatCard(
                                context,
                                'Revenue',
                                '\$${_salesStats['totalSalesAmount'].toStringAsFixed(2)}',
                                Icons.attach_money,
                                Colors.orange,
                              ),
                              _buildStatCard(
                                context,
                                'Customers',
                                _salesStats['uniqueCustomers'].toString(),
                                Icons.people,
                                Colors.purple,
                              ),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // Recent Items
                    Text(
                      'Recent Activities',
                      style: themeProvider.titleTextStyle.copyWith(
                        fontSize: themeProvider.fontSize + 6,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Activity Cards
                    Card(
                      color: themeProvider.cardBackgroundColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: themeProvider.isDarkMode
                              ? Colors.blue.shade800
                              : Colors.blue.shade100,
                          child: Icon(
                            Icons.shopping_cart,
                            color: themeProvider.isDarkMode
                                ? Colors.blue.shade100
                                : Colors.blue.shade800,
                          ),
                        ),
                        title: Text(
                          'New Product Added',
                          style: themeProvider.bodyTextStyleBold,
                        ),
                        subtitle: Text(
                          'Paracetamol 500mg - 10 minutes ago',
                          style: themeProvider.subtitleTextStyle,
                        ),
                      ),
                    ), // Activities list
                    if (_recentActivities.isEmpty)
                      Card(
                        color: themeProvider.cardBackgroundColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.timeline,
                                size: 48,
                                color: themeProvider.textColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent activities',
                                style: themeProvider.bodyTextStyle.copyWith(
                                  fontSize: themeProvider.fontSize + 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start using the app to see activities here',
                                style: themeProvider.bodyTextStyle,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._recentActivities.map((activity) => Card(
                            color: themeProvider.cardBackgroundColor,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getActivityColor(
                                    activity['color'], themeProvider),
                                child: Icon(
                                  _getActivityIcon(activity['icon']),
                                  color: _getActivityIconColor(
                                      activity['color'], themeProvider),
                                ),
                              ),
                              title: Text(
                                activity['title'],
                                style: themeProvider.bodyTextStyleBold,
                              ),
                              subtitle: Text(
                                activity['subtitle'],
                                style: themeProvider.subtitleTextStyle,
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      color: themeProvider.cardBackgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: themeProvider.bodyTextStyleBold,
                ),
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: themeProvider.fontSize + 14,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for activity display
  Color _getActivityColor(String colorName, ThemeProvider themeProvider) {
    switch (colorName) {
      case 'orange':
        return themeProvider.isDarkMode
            ? Colors.orange.shade800
            : Colors.orange.shade100;
      case 'green':
        return themeProvider.isDarkMode
            ? Colors.green.shade800
            : Colors.green.shade100;
      case 'purple':
        return themeProvider.isDarkMode
            ? Colors.purple.shade800
            : Colors.purple.shade100;
      case 'blue':
        return themeProvider.isDarkMode
            ? Colors.blue.shade800
            : Colors.blue.shade100;
      default:
        return themeProvider.isDarkMode
            ? Colors.grey.shade800
            : Colors.grey.shade100;
    }
  }

  Color _getActivityIconColor(String colorName, ThemeProvider themeProvider) {
    switch (colorName) {
      case 'orange':
        return themeProvider.isDarkMode
            ? Colors.orange.shade100
            : Colors.orange.shade800;
      case 'green':
        return themeProvider.isDarkMode
            ? Colors.green.shade100
            : Colors.green.shade800;
      case 'purple':
        return themeProvider.isDarkMode
            ? Colors.purple.shade100
            : Colors.purple.shade800;
      case 'blue':
        return themeProvider.isDarkMode
            ? Colors.blue.shade100
            : Colors.blue.shade800;
      default:
        return themeProvider.isDarkMode
            ? Colors.grey.shade100
            : Colors.grey.shade800;
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'payment':
        return Icons.payment;
      case 'inventory':
        return Icons.inventory;
      case 'person_add':
        return Icons.person_add;
      case 'shopping_bag':
        return Icons.shopping_bag;
      default:
        return Icons.notifications;
    }
  }
}
