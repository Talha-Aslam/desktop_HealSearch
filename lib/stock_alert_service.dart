import 'dart:async';
import 'package:desktop_search_a_holic/main.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockAlertService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int defaultLowStockThreshold = 10;
  static const int defaultCriticalStockThreshold = 5;
  static const int defaultOutOfStockThreshold = 0;

  List<StockAlert> _activeAlerts = [];
  bool _isMonitoring = false;
  Timer? _timer;

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

  Future<String?> _getPharmacyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await _supabase
        .from('user_profiles')
        .select('pharmacy_id')
        .eq('id', user.id)
        .maybeSingle();

    return profile?['pharmacy_id'] as String?;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    await checkAllProducts();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      checkAllProducts();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;
  }

  Future<void> checkAllProducts() async {
    final pharmacyId = await _getPharmacyId();
    if (pharmacyId == null) {
      _activeAlerts = [];
      notifyListeners();
      return;
    }

    try {
      final products = await (appDb.select(appDb.medicines)
            ..where((t) => t.pharmacyId.equals(pharmacyId)))
          .get();

      final now = DateTime.now();
      final alerts = <StockAlert>[];

      for (final product in products) {
        final alert = _evaluateProductStock(
          productId: product.id.toString(),
          productName: product.name,
          category: product.category ?? 'Other',
          currentStock: product.stock,
          now: now,
        );

        if (alert != null) {
          alerts.add(alert);
        }
      }

      alerts.sort((a, b) {
        const severityOrder = {
          AlertSeverity.danger: 0,
          AlertSeverity.critical: 1,
          AlertSeverity.warning: 2,
        };
        final severityComparison = (severityOrder[a.severity] ?? 3)
            .compareTo(severityOrder[b.severity] ?? 3);
        if (severityComparison != 0) return severityComparison;
        return b.timestamp.compareTo(a.timestamp);
      });

      _activeAlerts = alerts;
      notifyListeners();
    } catch (_) {
      // Keep existing alerts on transient failures.
    }
  }

  StockAlert? _evaluateProductStock({
    required String productId,
    required String productName,
    required String category,
    required int currentStock,
    required DateTime now,
  }) {
    if (currentStock <= defaultOutOfStockThreshold) {
      return StockAlert(
        id: 'stock_alert_${productId}_${now.millisecondsSinceEpoch}',
        productId: productId,
        productName: productName,
        category: category,
        currentStock: currentStock,
        threshold: defaultOutOfStockThreshold,
        severity: AlertSeverity.danger,
        message: '$productName is out of stock',
        timestamp: now,
        actionRequired: 'Restock immediately',
      );
    }

    if (currentStock <= defaultCriticalStockThreshold) {
      return StockAlert(
        id: 'stock_alert_${productId}_${now.millisecondsSinceEpoch}',
        productId: productId,
        productName: productName,
        category: category,
        currentStock: currentStock,
        threshold: defaultCriticalStockThreshold,
        severity: AlertSeverity.critical,
        message: '$productName is critically low ($currentStock remaining)',
        timestamp: now,
        actionRequired: 'Restock soon',
      );
    }

    if (currentStock <= defaultLowStockThreshold) {
      return StockAlert(
        id: 'stock_alert_${productId}_${now.millisecondsSinceEpoch}',
        productId: productId,
        productName: productName,
        category: category,
        currentStock: currentStock,
        threshold: defaultLowStockThreshold,
        severity: AlertSeverity.warning,
        message: '$productName is running low ($currentStock remaining)',
        timestamp: now,
        actionRequired: 'Consider restocking',
      );
    }

    return null;
  }

  List<StockAlert> getAlertsBySeverity(AlertSeverity severity) {
    return _activeAlerts.where((alert) => alert.severity == severity).toList();
  }

  List<StockAlert> getAlertsByCategory(String category) {
    return _activeAlerts.where((alert) => alert.category == category).toList();
  }

  void acknowledgeAlert(String alertId) {
    _activeAlerts.removeWhere((alert) => alert.id == alertId);
    notifyListeners();
  }

  StockStatus getProductStockStatus(int quantity) {
    if (quantity <= defaultOutOfStockThreshold) {
      return StockStatus.outOfStock;
    }
    if (quantity <= defaultCriticalStockThreshold) {
      return StockStatus.critical;
    }
    if (quantity <= defaultLowStockThreshold) {
      return StockStatus.low;
    }
    return StockStatus.normal;
  }

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

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

enum AlertSeverity {
  warning,
  critical,
  danger,
}

enum StockStatus {
  normal,
  low,
  critical,
  outOfStock,
}

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
