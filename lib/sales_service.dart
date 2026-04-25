import 'package:desktop_search_a_holic/mock_firebase.dart';

class SalesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new sale/order to Firestore
  Future<String> addSale(Map<String, dynamic> saleData) async {
    try {
      // Add user email to sale data
      if (_auth.currentUser != null) {
        saleData['userEmail'] = _auth.currentUser!.email;
      }

      // Add timestamp
      saleData['createdAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef =
          await _firestore.collection('sales').add(saleData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get all sales from Firestore (filtered by current user)
  Future<List<Map<String, dynamic>>> getSales() async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Query without orderBy to avoid composite index requirement
      QuerySnapshot querySnapshot = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      List<Map<String, dynamic>> sales = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> saleData =
            Map<String, dynamic>.from(doc.data() as Map);
        saleData['id'] = doc.id; // Add document ID to the sale data
        sales.add(saleData);
      }

      // Sort by createdAt in memory (most recent first)
      sales.sort((a, b) {
        DateTime dateA = a['createdAt'] != null
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        DateTime dateB = b['createdAt'] != null
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        return dateB.compareTo(dateA);
      });

      return sales;
    } catch (e) {
      rethrow;
    }
  }

  // Get sales for today
  Future<List<Map<String, dynamic>>> getTodaySales() async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Calculate start and end of today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month,
          now.day + 1); // Filter sales by current user's email and today's date
      QuerySnapshot querySnapshot = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .where('createdAt', isGreaterThanOrEqualTo: today)
          .where('createdAt', isLessThan: tomorrow)
          .get();

      List<Map<String, dynamic>> sales = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> saleData =
            Map<String, dynamic>.from(doc.data() as Map);
        saleData['id'] = doc.id; // Add document ID to the sale data
        sales.add(saleData);
      }

      // Sort by createdAt in memory (most recent first)
      sales.sort((a, b) {
        DateTime dateA = a['createdAt'] != null
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        DateTime dateB = b['createdAt'] != null
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        return dateB.compareTo(dateA);
      });

      return sales;
    } catch (e) {
      rethrow;
    }
  }

  // Get a specific sale by ID
  Future<Map<String, dynamic>?> getSale(String saleId) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      DocumentSnapshot doc =
          await _firestore.collection('sales').doc(saleId).get();
      if (doc.exists) {
        Map<String, dynamic> saleData =
            Map<String, dynamic>.from(doc.data() as Map);

        // Check if the sale belongs to the current user
        if (saleData['userEmail'] == _auth.currentUser!.email) {
          saleData['id'] = doc.id; // Add document ID to the sale data
          return saleData;
        }
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update product inventory after a sale
  Future<void> updateProductInventory(
      String productId, int quantitySold) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      var docRef = _firestore.collection('products').doc(productId);
      var docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        var data = docSnap.data() as Map<String, dynamic>;
        int currentQty = 0;

        // Safely parse quantity even if it was accidentally saved as a String
        if (data['quantity'] != null) {
          if (data['quantity'] is String) {
            currentQty = int.tryParse(data['quantity']) ?? 0;
          } else if (data['quantity'] is num) {
            currentQty = (data['quantity'] as num).toInt();
          }
        }

        int newQty = currentQty - quantitySold;

        // Save back strictly as a number
        await docRef.update({'quantity': newQty});
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get sales statistics (for dashboard)
  Future<Map<String, dynamic>> getSalesStats() async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get all sales for current user
      QuerySnapshot salesSnapshot = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      double totalSales = 0;
      int totalOrders = salesSnapshot.docs.length;
      List<String> customers = [];
      Map<String, int> productSales = {};

      // Calculate stats from sales data
      for (var doc in salesSnapshot.docs) {
        Map<String, dynamic> saleData =
            Map<String, dynamic>.from(doc.data() as Map);

        // Add to total sales amount
        if (saleData['total'] != null) {
          totalSales += (saleData['total'] as num).toDouble();
        }

        // Add customer to unique customers list
        if (saleData['customerName'] != null &&
            saleData['customerName'] != 'Walk-in Customer' &&
            !customers.contains(saleData['customerName'])) {
          customers.add(saleData['customerName'] as String);
        }

        // Count product sales
        if (saleData['items'] != null) {
          List<dynamic> items = saleData['items'] as List<dynamic>;
          for (var item in items) {
            String productName = item['name'] as String;
            int quantity = item['quantity'] as int;

            if (productSales.containsKey(productName)) {
              productSales[productName] =
                  (productSales[productName] ?? 0) + quantity;
            } else {
              productSales[productName] = quantity;
            }
          }
        }
      }

      // Find top selling product
      String topSellingProduct = '';
      int topSellingCount = 0;

      productSales.forEach((product, count) {
        if (count > topSellingCount) {
          topSellingProduct = product;
          topSellingCount = count;
        }
      }); // Get product count from current user
      QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      return {
        'totalSalesAmount': totalSales,
        'totalOrders': totalOrders,
        'uniqueCustomers': customers.length,
        'topSellingProduct': topSellingProduct,
        'topSellingCount': topSellingCount,
        'totalProducts': productsSnapshot.docs.length,
      };
    } catch (e) {
      rethrow;
    }
  }
}
