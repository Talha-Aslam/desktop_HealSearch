import 'package:desktop_search_a_holic/mock_firebase.dart';

class ActivityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get recent activities for the current user
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      if (_auth.currentUser == null || _auth.currentUser!.email == null) {
        throw Exception('User not logged in');
      }

      List<Map<String, dynamic>> activities = []; // Get recent sales (last 5)
      QuerySnapshot recentSales = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      // Convert to list and sort by timestamp
      List<QueryDocumentSnapshot> salesDocs = recentSales.docs;
      salesDocs.sort((a, b) {
        Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
        Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;

        Timestamp? timestampA = dataA['createdAt'] as Timestamp?;
        Timestamp? timestampB = dataB['createdAt'] as Timestamp?;

        DateTime dateA = timestampA?.toDate() ?? DateTime.now();
        DateTime dateB = timestampB?.toDate() ?? DateTime.now();

        return dateB.compareTo(dateA); // Most recent first
      });

      // Take only the first 3 (most recent)
      List<QueryDocumentSnapshot> recentSalesDocs = salesDocs.take(3).toList();

      for (var doc in recentSalesDocs) {
        Map<String, dynamic> sale = doc.data() as Map<String, dynamic>;
        Timestamp? timestamp = sale['createdAt'] as Timestamp?;
        DateTime dateTime = timestamp?.toDate() ?? DateTime.now();

        activities.add({
          'type': 'sale',
          'icon': 'payment',
          'title': 'Payment Received',
          'subtitle':
              '\$${sale['total']?.toStringAsFixed(2) ?? '0.00'} from ${sale['customerName'] ?? 'Customer'} - ${_formatTimeAgo(dateTime)}',
          'timestamp': dateTime,
          'color': 'orange',
        });
      } // Get recent product additions (last 3)
      QuerySnapshot recentProducts = await _firestore
          .collection('products')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get(); // Convert to list and sort by createdAt
      List<QueryDocumentSnapshot> productDocs = recentProducts.docs;

      // Filter out dummy/test products
      productDocs = productDocs.where((doc) {
        Map<String, dynamic> product = doc.data() as Map<String, dynamic>;
        String? productId = product['id']?.toString();
        String? productName = product['name']?.toString();

        // Skip dummy products
        if (productId?.startsWith('dummy_') == true) return false;

        // Skip test products (optional - you can remove this if you want test data to show)
        if (productName?.toLowerCase().contains('test') == true) return false;

        return true;
      }).toList();

      productDocs.sort((a, b) {
        Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
        Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;

        // Handle different date formats in products
        DateTime dateA;
        DateTime dateB;

        try {
          if (dataA['createdAt'] is Timestamp) {
            dateA = (dataA['createdAt'] as Timestamp).toDate();
          } else {
            dateA = DateTime.parse(
                dataA['createdAt'] ?? DateTime.now().toIso8601String());
          }
        } catch (e) {
          dateA = DateTime.now();
        }

        try {
          if (dataB['createdAt'] is Timestamp) {
            dateB = (dataB['createdAt'] as Timestamp).toDate();
          } else {
            dateB = DateTime.parse(
                dataB['createdAt'] ?? DateTime.now().toIso8601String());
          }
        } catch (e) {
          dateB = DateTime.now();
        }

        return dateB.compareTo(dateA); // Most recent first
      }); // Take only the first 2 (most recent)
      List<QueryDocumentSnapshot> recentProductDocs =
          productDocs.take(2).toList();

      print(
          '🔍 ACTIVITY DEBUG: Found ${recentProducts.docs.length} total products');
      print(
          '🔍 ACTIVITY DEBUG: After filtering: ${productDocs.length} products');
      print(
          '🔍 ACTIVITY DEBUG: Showing top ${recentProductDocs.length} in activity feed');

      for (int i = 0; i < recentProductDocs.length; i++) {
        var doc = recentProductDocs[i];
        Map<String, dynamic> product = doc.data() as Map<String, dynamic>;
        print('🔍 ACTIVITY DEBUG: Product ${i + 1}: ${product['name']}');
      }

      for (var doc in recentProductDocs) {
        Map<String, dynamic> product = doc.data() as Map<String, dynamic>;
        DateTime dateTime;

        // Handle different date formats in products
        try {
          if (product['createdAt'] is Timestamp) {
            dateTime = (product['createdAt'] as Timestamp).toDate();
          } else {
            dateTime = DateTime.parse(
                product['createdAt'] ?? DateTime.now().toIso8601String());
          }
        } catch (e) {
          dateTime = DateTime.now();
        }

        activities.add({
          'type': 'product',
          'icon': 'inventory',
          'title': 'New Product Added',
          'subtitle': '${product['name']} - ${_formatTimeAgo(dateTime)}',
          'timestamp': dateTime,
          'color': 'green',
        });
      }

      // Get user registration activity (only show once)
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Timestamp? createdAt = userData['createdAt'] as Timestamp?;
        if (createdAt != null) {
          DateTime dateTime = createdAt.toDate();
          // Only show if registration was recent (within last 7 days)
          if (DateTime.now().difference(dateTime).inDays <= 7) {
            activities.add({
              'type': 'user',
              'icon': 'person_add',
              'title': 'Account Created',
              'subtitle':
                  'Welcome to HealSearch! - ${_formatTimeAgo(dateTime)}',
              'timestamp': dateTime,
              'color': 'purple',
            });
          }
        }
      }

      // Sort activities by timestamp (most recent first)
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Return only the 5 most recent activities
      return activities.take(5).toList();
    } catch (e) {
      throw Exception('Failed to get activities: $e');
    }
  }

  // Format time ago string
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Log a new activity (for future use)
  Future<void> logActivity(
      String type, String title, String description) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore.collection('activities').add({
          'userId': _auth.currentUser!.uid,
          'userEmail': _auth.currentUser!.email,
          'type': type,
          'title': title,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silent fail for activity logging
      print('Failed to log activity: $e');
    }
  }
}
