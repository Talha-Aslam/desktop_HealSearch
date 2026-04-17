import 'package:desktop_search_a_holic/mock_firebase.dart';

class DataDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Delete all user data (for GDPR compliance)
  Future<void> deleteAllUserData(String userId) async {
    try {
      // Delete products
      await _deleteCollection('products', userId);

      // Delete sales
      await _deleteCollection('sales', userId);

      // Delete backup history
      await _deleteCollection('backup_history', userId);

      // Delete user profile/settings
      await _firestore.collection('users').doc(userId).delete();

      print('All user data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// Delete a specific collection for a user
  Future<void> _deleteCollection(String collectionName, String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Deleted $collectionName collection for user $userId');
    } catch (e) {
      print('Error deleting $collectionName: $e');
      throw Exception('Failed to delete $collectionName: $e');
    }
  }

  /// Anonymize user data instead of deletion (alternative option)
  Future<void> anonymizeUserData(String userId) async {
    try {
      // Replace personal information with anonymous data
      await _firestore.collection('users').doc(userId).update({
        'email': 'anonymous@example.com',
        'name': 'Anonymous User',
        'phone': '',
        'address': '',
        'businessName': 'Anonymous Business',
        'dataAnonymized': true,
        'anonymizedAt': FieldValue.serverTimestamp(),
      });

      // Anonymize customer data in sales
      final QuerySnapshot salesSnapshot = await _firestore
          .collection('sales')
          .where('userId', isEqualTo: userId)
          .get();

      final WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in salesSnapshot.docs) {
        batch.update(doc.reference, {
          'customerName': 'Anonymous Customer',
          'customerPhone': '',
          'customerEmail': '',
        });
      }

      await batch.commit();
      print('User data anonymized successfully');
    } catch (e) {
      print('Error anonymizing user data: $e');
      throw Exception('Failed to anonymize user data: $e');
    }
  }

  /// Get data retention summary
  Future<Map<String, dynamic>> getDataRetentionSummary(String userId) async {
    try {
      final Map<String, dynamic> summary = {};

      // Count products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .get();
      summary['products'] = productsSnapshot.docs.length;

      // Count sales
      final salesSnapshot = await _firestore
          .collection('sales')
          .where('userId', isEqualTo: userId)
          .get();
      summary['sales'] = salesSnapshot.docs.length;

      // Get oldest and newest records
      if (salesSnapshot.docs.isNotEmpty) {
        final dates = salesSnapshot.docs
            .map((doc) => doc.data()['timestamp'])
            .where((timestamp) => timestamp != null)
            .map((timestamp) => timestamp is Timestamp
                ? timestamp.toDate()
                : DateTime.parse(timestamp.toString()))
            .toList();

        if (dates.isNotEmpty) {
          dates.sort();
          summary['oldestRecord'] = dates.first.toIso8601String();
          summary['newestRecord'] = dates.last.toIso8601String();
        }
      }

      return summary;
    } catch (e) {
      print('Error getting data retention summary: $e');
      return {};
    }
  }
}
