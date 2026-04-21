import 'package:desktop_search_a_holic/mock_firebase.dart';

class ReportsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate real-time sales report
  Future<Map<String, dynamic>> generateSalesReport() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get sales data for current user
      QuerySnapshot salesSnapshot = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      double totalSales = 0;
      int totalOrders = salesSnapshot.docs.length;
      Map<String, int> productSales = {};

      // Calculate monthly sales (current month)
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      double monthlySales = 0;
      int monthlyOrders = 0;

      for (var doc in salesSnapshot.docs) {
        Map<String, dynamic> saleData = doc.data() as Map<String, dynamic>;

        if (saleData['total'] != null) {
          totalSales += (saleData['total'] as num).toDouble();
        }

        // Check if sale is from current month
        if (saleData['createdAt'] != null) {
          Timestamp timestamp = saleData['createdAt'] as Timestamp;
          DateTime saleDate = timestamp.toDate();

          if (saleDate.isAfter(startOfMonth)) {
            monthlySales += (saleData['total'] as num?)?.toDouble() ?? 0;
            monthlyOrders++;
          }
        }

        // Count product sales
        if (saleData['items'] != null) {
          List<dynamic> items = saleData['items'] as List<dynamic>;
          for (var item in items) {
            String productName = item['name'] as String;
            int quantity = item['quantity'] as int;
            productSales[productName] =
                (productSales[productName] ?? 0) + quantity;
          }
        }
      }

      // Find top selling product
      String topProduct = 'N/A';
      int topSales = 0;
      productSales.forEach((product, sales) {
        if (sales > topSales) {
          topProduct = product;
          topSales = sales;
        }
      });

      return {
        'id': 'sales_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Sales Report',
        'description': 'Comprehensive sales analysis and performance metrics',
        'type': 'Sales',
        'date': DateTime.now(),
        'status': 'Completed',
        'data': {
          'totalSales': totalSales,
          'totalOrders': totalOrders,
          'monthlySales': monthlySales,
          'monthlyOrders': monthlyOrders,
          'topProduct': topProduct,
          'topProductSales': topSales,
          'itemsSold': productSales.values.fold(0, (sum, sales) => sum + sales),
        }
      };
    } catch (e) {
      rethrow;
    }
  }

  // Generate real-time inventory report
  Future<Map<String, dynamic>> generateInventoryReport() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      int totalItems = productsSnapshot.docs.length;
      int lowStock = 0;
      int outOfStock = 0;
      double totalValue = 0;

      for (var doc in productsSnapshot.docs) {
        Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;

        int stock = int.tryParse(productData['stock']?.toString() ?? '0') ?? 0;
        double price =
            double.tryParse(productData['price']?.toString() ?? '0') ?? 0;

        totalValue += stock * price;

        if (stock == 0) {
          outOfStock++;
        } else if (stock <= 10) {
          // Define low stock threshold
          lowStock++;
        }
      }

      return {
        'id': 'inventory_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Inventory Status Report',
        'description': 'Current inventory levels and stock analysis',
        'type': 'Inventory',
        'date': DateTime.now(),
        'status': 'Completed',
        'data': {
          'totalItems': totalItems,
          'lowStock': lowStock,
          'outOfStock': outOfStock,
          'totalValue': totalValue,
        }
      };
    } catch (e) {
      rethrow;
    }
  }

  // Generate customer insights report
  Future<Map<String, dynamic>> generateCustomerReport() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      QuerySnapshot salesSnapshot = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      Set<String> allCustomers = {};
      Set<String> monthlyCustomers = {};
      Map<String, int> customerPurchases = {};

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in salesSnapshot.docs) {
        Map<String, dynamic> saleData = doc.data() as Map<String, dynamic>;

        String customerName =
            saleData['customerName']?.toString() ?? 'Walk-in Customer';
        if (customerName != 'Walk-in Customer' && customerName.isNotEmpty) {
          allCustomers.add(customerName);

          // Count customer purchases
          customerPurchases[customerName] =
              (customerPurchases[customerName] ?? 0) + 1;

          // Check if purchase is from current month
          if (saleData['createdAt'] != null) {
            Timestamp timestamp = saleData['createdAt'] as Timestamp;
            DateTime saleDate = timestamp.toDate();

            if (saleDate.isAfter(startOfMonth)) {
              monthlyCustomers.add(customerName);
            }
          }
        }
      }

      // Count repeat customers (more than 1 purchase)
      int repeatCustomers =
          customerPurchases.values.where((count) => count > 1).length;

      return {
        'id': 'customer_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Customer Insights',
        'description': 'Customer behavior analysis and retention metrics',
        'type': 'Customer',
        'date': DateTime.now(),
        'status': 'Completed',
        'data': {
          'totalCustomers': allCustomers.length,
          'newCustomers': monthlyCustomers.length,
          'repeatCustomers': repeatCustomers,
          'averagePurchases': allCustomers.isEmpty
              ? 0
              : (customerPurchases.values.fold(0, (sum, count) => sum + count) /
                      allCustomers.length)
                  .round(),
        }
      };
    } catch (e) {
      rethrow;
    }
  }

  // Generate financial report
  Future<Map<String, dynamic>> generateFinancialReport() async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      final now = DateTime.now();
      final startOfQuarter =
          DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);

      QuerySnapshot salesSnapshot = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .where('createdAt', isGreaterThanOrEqualTo: startOfQuarter)
          .get();

      double revenue = 0;
      for (var doc in salesSnapshot.docs) {
        Map<String, dynamic> saleData = doc.data() as Map<String, dynamic>;
        if (saleData['total'] != null) {
          revenue += (saleData['total'] as num).toDouble();
        }
      }

      // Estimate expenses as 60% of revenue (this could be enhanced with actual expense tracking)
      double estimatedExpenses = revenue * 0.6;
      double profit = revenue - estimatedExpenses;

      return {
        'id': 'financial_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Quarterly Financial Report',
        'description': 'Financial performance for current quarter',
        'type': 'Financial',
        'date': DateTime.now(),
        'status': 'Completed',
        'data': {
          'revenue': revenue,
          'expenses': estimatedExpenses,
          'profit': profit,
          'profitMargin': revenue > 0 ? ((profit / revenue) * 100).round() : 0,
        }
      };
    } catch (e) {
      rethrow;
    }
  }

  // Get all reports
  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      List<Future<Map<String, dynamic>>> reportFutures = [
        generateSalesReport(),
        generateInventoryReport(),
        generateCustomerReport(),
        generateFinancialReport(),
      ];

      List<Map<String, dynamic>> reports = await Future.wait(reportFutures);

      // Sort by date (newest first)
      reports.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      return reports;
    } catch (e) {
      rethrow;
    }
  }
}
