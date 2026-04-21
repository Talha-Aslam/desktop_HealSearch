import 'package:flutter/material.dart';
import 'package:desktop_search_a_holic/mock_firebase.dart';
import 'dart:async';

class StockAlertService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default thresholds
  static const int DEFAULT_LOW_STOCK_THRESHOLD = 10;
  static const int DEFAULT_CRITICAL_STOCK_THRESHOLD = 5;
  static const int DEFAULT_OUT_OF_STOCK_THRESHOLD = 0;

  // Alert states
  List<StockAlert> _activeAlerts = [];
  bool _isMonitoring = false;
  StreamSubscription<QuerySnapshot>? _productSubscription;

  // Getters
  List<StockAlert> get activeAlerts => _activeAlerts;
  bool get isMonitoring => _isMonitoring;
  int get totalAlerts => _activeAlerts.length;
  int get criticalAlerts => _activeAlerts
      .where((alert) => alert.severity == AlertSeverity.critical)
      .length;
  int get lowStockAlerts => _activeAlerts
      .where((alert) => alert.severity == AlertSeverity.warning)
      .length;
  int get outOfStockAlerts => _activeAlerts
      .where((alert) => alert.severity == AlertSeverity.danger)
      .length;

  // Start monitoring products for stock alerts
  Future<void> startMonitoring() async {
    if (_isMonitoring || _auth.currentUser == null) return;

    try {
      _isMonitoring = true;

      // Listen to real-time product changes
      _productSubscription = _firestore
          .collection('products')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .snapshots()
          .listen(_handleProductUpdate);

      // Initial check
      await checkAllProducts();

      print('Stock monitoring started successfully');
    } catch (e) {
      print('Error starting stock monitoring: $e');
      _isMonitoring = false;
    }
  }

  // Stop monitoring
  void stopMonitoring() {
    _productSubscription?.cancel();
    _productSubscription = null;
    _isMonitoring = false;
    print('Stock monitoring stopped');
  }

  // Handle real-time product updates
  void _handleProductUpdate(QuerySnapshot snapshot) {
    try {
      List<StockAlert> newAlerts = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;
        productData['id'] = doc.id;

        StockAlert? alert = _evaluateProductStock(productData);
        if (alert != null) {
          newAlerts.add(alert);
        }
      }

      // Update alerts and notify listeners
      _activeAlerts = newAlerts;
      notifyListeners();
    } catch (e) {
      print('Error handling product update: $e');
    }
  }

  // Evaluate a single product for stock alerts
  StockAlert? _evaluateProductStock(Map<String, dynamic> product) {
    try {
      int currentStock = (product['quantity'] ?? 0).toInt();
      String productName = product['name'] ?? 'Unknown Product';
      String productId = product['id'] ?? '';
      String category = product['category'] ?? 'Other';

      // Get custom thresholds (if stored in user preferences) or use defaults
      int lowStockThreshold = DEFAULT_LOW_STOCK_THRESHOLD;
      int criticalStockThreshold = DEFAULT_CRITICAL_STOCK_THRESHOLD;

      // Determine alert severity and create alert
      if (currentStock <= DEFAULT_OUT_OF_STOCK_THRESHOLD) {
        return StockAlert(
          id: 'stock_alert_${productId}_${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          productName: productName,
          category: category,
          currentStock: currentStock,
          threshold: DEFAULT_OUT_OF_STOCK_THRESHOLD,
          severity: AlertSeverity.danger,
          message: '$productName is out of stock',
          timestamp: DateTime.now(),
          actionRequired: 'Restock immediately',
        );
      } else if (currentStock <= criticalStockThreshold) {
        return StockAlert(
          id: 'stock_alert_${productId}_${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          productName: productName,
          category: category,
          currentStock: currentStock,
          threshold: criticalStockThreshold,
          severity: AlertSeverity.critical,
          message: '$productName is critically low ($currentStock remaining)',
          timestamp: DateTime.now(),
          actionRequired: 'Restock soon',
        );
      } else if (currentStock <= lowStockThreshold) {
        return StockAlert(
          id: 'stock_alert_${productId}_${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          productName: productName,
          category: category,
          currentStock: currentStock,
          threshold: lowStockThreshold,
          severity: AlertSeverity.warning,
          message: '$productName is running low ($currentStock remaining)',
          timestamp: DateTime.now(),
          actionRequired: 'Consider restocking',
        );
      }

      return null; // No alert needed
    } catch (e) {
      print('Error evaluating product stock: $e');
      return null;
    }
  }

  // Manual check of all products
  Future<void> checkAllProducts() async {
    if (_auth.currentUser == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      List<StockAlert> alerts = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;
        productData['id'] = doc.id;

        StockAlert? alert = _evaluateProductStock(productData);
        if (alert != null) {
          alerts.add(alert);
        }
      }

      _activeAlerts = alerts;
      notifyListeners();
    } catch (e) {
      print('Error checking all products: $e');
    }
  }

  // Get alerts by severity
  List<StockAlert> getAlertsBySeverity(AlertSeverity severity) {
    return _activeAlerts.where((alert) => alert.severity == severity).toList();
  }

  // Get alerts by category
  List<StockAlert> getAlertsByCategory(String category) {
    return _activeAlerts.where((alert) => alert.category == category).toList();
  }

  // Mark alert as acknowledged (for future enhancement)
  void acknowledgeAlert(String alertId) {
    // Could store acknowledged alerts in preferences or database
    // For now, we'll just remove from active alerts
    _activeAlerts.removeWhere((alert) => alert.id == alertId);
    notifyListeners();
  }

  // Get stock status for a specific product
  StockStatus getProductStockStatus(int quantity) {
    if (quantity <= DEFAULT_OUT_OF_STOCK_THRESHOLD) {
      return StockStatus.outOfStock;
    } else if (quantity <= DEFAULT_CRITICAL_STOCK_THRESHOLD) {
      return StockStatus.critical;
    } else if (quantity <= DEFAULT_LOW_STOCK_THRESHOLD) {
      return StockStatus.low;
    } else {
      return StockStatus.normal;
    }
  }

  // Get color for stock status
  Color getStockStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return Colors.red;
      case StockStatus.critical:
        return Colors.orange;
      case StockStatus.low:
        return Colors.yellow.shade700;
      case StockStatus.normal:
        return Colors.green;
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

// Stock Alert Model
class StockAlert {
  final String id;
  final String productId;
  final String productName;
  final String category;
  final int currentStock;
  final int threshold;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final String actionRequired;
  final bool isAcknowledged;

  StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.category,
    required this.currentStock,
    required this.threshold,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.actionRequired,
    this.isAcknowledged = false,
  });

  // Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Alert Severity Enum
enum AlertSeverity {
  warning, // Low stock
  critical, // Critical stock
  danger, // Out of stock
}

// Stock Status Enum
enum StockStatus {
  normal,
  low,
  critical,
  outOfStock,
}

// Extension for AlertSeverity
extension AlertSeverityExtension on AlertSeverity {
  Color get color {
    switch (this) {
      case AlertSeverity.warning:
        return Colors.yellow.shade700;
      case AlertSeverity.critical:
        return Colors.orange;
      case AlertSeverity.danger:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.warning:
        return Icons.warning_amber;
      case AlertSeverity.critical:
        return Icons.error_outline;
      case AlertSeverity.danger:
        return Icons.dangerous;
    }
  }

  String get label {
    switch (this) {
      case AlertSeverity.warning:
        return 'Low Stock';
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.danger:
        return 'Out of Stock';
    }
  }
}
