import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';

class DataVisualizationWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final String title;

  const DataVisualizationWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.grey.shade100.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.gradientColors[0].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: themeProvider.gradientColors[0],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDataVisualization(data, themeProvider),
        ],
      ),
    );
  }

  Widget _buildDataVisualization(
      Map<String, dynamic> data, ThemeProvider themeProvider) {
    // Sales data visualization (check for revenue AND orders)
    if (data.containsKey('revenue') && data.containsKey('orders')) {
      return _buildSalesChart(data, themeProvider);
    }

    // Inventory data visualization (check for inventory-specific fields)
    if (data.containsKey('totalItems') ||
        data.containsKey('total') ||
        data.containsKey('lowStock') ||
        data.containsKey('outOfStock')) {
      return _buildInventoryChart(data, themeProvider);
    }

    // Alert data visualization (check if alerts key exists and has appropriate data)
    if (data.containsKey('alerts')) {
      return _buildAlertChart(data, themeProvider);
    }

    // Default data display for any other data
    return _buildDataTable(data, themeProvider);
  }

  Widget _buildSalesChart(
      Map<String, dynamic> data, ThemeProvider themeProvider) {
    double revenue = (data['revenue'] as num?)?.toDouble() ?? 0;
    int orders = data['orders'] ?? 0;
    double avgOrder = orders > 0 ? revenue / orders : 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricCard('Revenue', '\$${revenue.toStringAsFixed(2)}',
                Icons.attach_money, Colors.green, themeProvider),
            _buildMetricCard('Orders', orders.toString(), Icons.shopping_cart,
                Colors.blue, themeProvider),
            _buildMetricCard('Avg Order', '\$${avgOrder.toStringAsFixed(2)}',
                Icons.trending_up, Colors.orange, themeProvider),
          ],
        ),
        const SizedBox(height: 12),
        // Simple progress bars for visual appeal
        _buildProgressBar(
            'Sales Performance', revenue / 1000, Colors.green, themeProvider),
      ],
    );
  }

  Widget _buildInventoryChart(
      Map<String, dynamic> data, ThemeProvider themeProvider) {
    int total = data['totalItems'] ?? data['total'] ?? 0;
    int lowStock = data['lowStock'] ?? 0;
    int outOfStock = data['outOfStock'] ?? 0;
    int healthy = total - lowStock - outOfStock;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricCard('Total', total.toString(), Icons.inventory,
                Colors.blue, themeProvider),
            _buildMetricCard('Healthy', healthy.toString(), Icons.check_circle,
                Colors.green, themeProvider),
            _buildMetricCard('Low Stock', lowStock.toString(), Icons.warning,
                Colors.orange, themeProvider),
            _buildMetricCard('Out of Stock', outOfStock.toString(), Icons.error,
                Colors.red, themeProvider),
          ],
        ),
        const SizedBox(height: 12),
        if (total > 0) ...[
          _buildProgressBar(
              'Healthy Stock', healthy / total, Colors.green, themeProvider),
          const SizedBox(height: 4),
          _buildProgressBar(
              'Low Stock', lowStock / total, Colors.orange, themeProvider),
          const SizedBox(height: 4),
          _buildProgressBar(
              'Out of Stock', outOfStock / total, Colors.red, themeProvider),
        ],
      ],
    );
  }

  Widget _buildAlertChart(
      Map<String, dynamic> data, ThemeProvider themeProvider) {
    // Handle different possible data structures
    List<dynamic> alerts = [];

    if (data['alerts'] is List) {
      alerts = data['alerts'] as List<dynamic>;
    } else if (data['alerts'] is int) {
      // If alerts is just a count, create a simple display
      int alertCount = data['alerts'] as int;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard('Total Alerts', alertCount.toString(),
                  Icons.notifications, Colors.orange, themeProvider),
              _buildMetricCard(
                  'Status',
                  alertCount > 0 ? 'Action Needed' : 'All Good',
                  alertCount > 0 ? Icons.warning : Icons.check_circle,
                  alertCount > 0 ? Colors.red : Colors.green,
                  themeProvider),
            ],
          ),
        ],
      );
    }

    Map<String, int> severityCount = {};

    for (var alert in alerts) {
      String severity = alert['severity']?.toString() ?? 'unknown';
      severityCount[severity] = (severityCount[severity] ?? 0) + 1;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricCard(
                'Critical',
                (severityCount['AlertSeverity.critical'] ?? 0).toString(),
                Icons.error,
                Colors.red,
                themeProvider),
            _buildMetricCard(
                'Warning',
                (severityCount['AlertSeverity.warning'] ?? 0).toString(),
                Icons.warning,
                Colors.orange,
                themeProvider),
            _buildMetricCard('Total', alerts.length.toString(),
                Icons.notifications, Colors.blue, themeProvider),
          ],
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: alerts.length.clamp(0, 5),
              itemBuilder: (context, index) {
                var alert = alerts[index];
                return _buildAlertCard(alert, themeProvider);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertCard(
      Map<String, dynamic> alert, ThemeProvider themeProvider) {
    Color alertColor = Colors.orange;
    if (alert['severity']?.toString().contains('critical') == true) {
      alertColor = Colors.red;
    }
    if (alert['severity']?.toString().contains('warning') == true) {
      alertColor = Colors.orange;
    }

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert['name']?.toString() ?? 'Unknown Product',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Stock: ${alert['stock']}',
            style: TextStyle(
              fontSize: 11,
              color: themeProvider.textColor.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: alertColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              alert['severity']?.toString().split('.').last.toUpperCase() ??
                  'ALERT',
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(
      Map<String, dynamic> data, ThemeProvider themeProvider) {
    return Column(
      children: data.entries.take(6).map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatKey(entry.key),
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.textColor.withOpacity(0.7),
                ),
              ),
              Text(
                _formatValue(entry.value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon,
      Color color, ThemeProvider themeProvider) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: themeProvider.textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      String label, double progress, Color color, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: themeProvider.textColor.withOpacity(0.7),
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ')
        .trim();
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is List) {
      return '${value.length} items';
    } else if (value is Map) {
      return '${value.length} entries';
    }
    return value.toString();
  }
}

class ActionButtonsWidget extends StatelessWidget {
  final List<Map<String, dynamic>>? suggestions;
  final Function(String) onActionPressed;

  const ActionButtonsWidget({
    super.key,
    this.suggestions,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (suggestions == null || suggestions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions!.map((suggestion) {
          return _buildActionButton(
            suggestion['text'] ?? '',
            suggestion['action'] ?? '',
            themeProvider,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(
      String text, String action, ThemeProvider themeProvider) {
    return InkWell(
      onTap: () => onActionPressed(action),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: themeProvider.gradientColors[0].withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeProvider.gradientColors[0].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getActionIcon(action),
              size: 14,
              color: themeProvider.gradientColors[0],
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.gradientColors[0],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'navigate_add_product':
      case 'add_product':
        return Icons.add_box_outlined;
      case 'show_products':
      case 'inventory_status':
        return Icons.inventory_outlined;
      case 'stock_alerts':
      case 'detailed_alerts':
        return Icons.warning_outlined;
      case 'today_sales':
      case 'sales_report':
        return Icons.trending_up_outlined;
      case 'dashboard':
      case 'business_overview':
        return Icons.dashboard_outlined;
      case 'search_products':
      case 'search_sales':
        return Icons.search_outlined;
      case 'generate_report':
      case 'detailed_sales_report':
        return Icons.assessment_outlined;
      case 'customer_insights':
      case 'customer_trends':
        return Icons.people_outlined;
      case 'navigate_alerts':
        return Icons.notification_important_outlined;
      case 'help_topics':
      case 'all_features':
        return Icons.help_outline;
      default:
        return Icons.arrow_forward_outlined;
    }
  }
}

class TypingIndicatorWidget extends StatefulWidget {
  final ThemeProvider themeProvider;

  const TypingIndicatorWidget({
    super.key,
    required this.themeProvider,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    _animations = _controllers
        .map((controller) => Tween<double>(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: Curves.easeInOut),
            ))
        .toList();

    // Start animations with delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.themeProvider.gradientColors[0]
                    .withOpacity(_animations[index].value),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}
