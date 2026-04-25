import 'package:desktop_search_a_holic/mock_firebase.dart';

class BackupHistoryService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log a backup operation
  Future<void> logBackupOperation({
    required String type, // 'manual', 'automatic', 'export'
    required String status, // 'success', 'failed'
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore.collection('backup_history').add({
          'userId': _auth.currentUser!.uid,
          'userEmail': _auth.currentUser!.email,
          'type': type,
          'status': status,
          'description': description,
          'metadata': metadata ?? {},
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silent fail for logging
      print('Failed to log backup operation: $e');
    }
  }

  // Get backup history for current user
  Future<List<Map<String, dynamic>>> getBackupHistory({int limit = 20}) async {
    try {
      if (_auth.currentUser == null) {
        return [];
      }

      // Query without orderBy to avoid composite index requirement
      QuerySnapshot snapshot = await _firestore
          .collection('backup_history')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      List<Map<String, dynamic>> history = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        history.add(data);
      }

      // Sort by timestamp in memory (most recent first)
      history.sort((a, b) {
        DateTime dateA = a['timestamp'] != null
            ? (a['timestamp'] as Timestamp).toDate()
            : DateTime.now();
        DateTime dateB = b['timestamp'] != null
            ? (b['timestamp'] as Timestamp).toDate()
            : DateTime.now();
        return dateB.compareTo(dateA);
      });

      // Apply limit after sorting
      if (history.length > limit) {
        history = history.take(limit).toList();
      }

      return history;
    } catch (e) {
      print('Error fetching backup history: $e');
      return [];
    }
  }

  // Get backup statistics
  Future<Map<String, dynamic>> getBackupStats() async {
    try {
      if (_auth.currentUser == null) {
        return {
          'totalBackups': 0,
          'successfulBackups': 0,
          'failedBackups': 0,
          'lastBackup': null,
        };
      }

      // Get all backups for the user
      QuerySnapshot allBackups = await _firestore
          .collection('backup_history')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      // Filter successful backups in memory
      List<QueryDocumentSnapshot> successfulBackups =
          allBackups.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'success';
      }).toList();

      // Find most recent successful backup
      DateTime? lastBackup;
      if (successfulBackups.isNotEmpty) {
        // Sort successful backups by timestamp in memory
        successfulBackups.sort((a, b) {
          Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
          Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;

          DateTime dateA = dataA['timestamp'] != null
              ? (dataA['timestamp'] as Timestamp).toDate()
              : DateTime.now();
          DateTime dateB = dataB['timestamp'] != null
              ? (dataB['timestamp'] as Timestamp).toDate()
              : DateTime.now();

          return dateB.compareTo(dateA); // Most recent first
        });

        // Get the most recent successful backup
        Map<String, dynamic> recentData =
            successfulBackups.first.data() as Map<String, dynamic>;
        if (recentData['timestamp'] != null) {
          lastBackup = (recentData['timestamp'] as Timestamp).toDate();
        }
      }

      return {
        'totalBackups': allBackups.docs.length,
        'successfulBackups': successfulBackups.length,
        'failedBackups': allBackups.docs.length - successfulBackups.length,
        'lastBackup': lastBackup,
      };
    } catch (e) {
      print('Error fetching backup stats: $e');
      return {
        'totalBackups': 0,
        'successfulBackups': 0,
        'failedBackups': 0,
        'lastBackup': null,
      };
    }
  }

  // Clean up old backup logs (keep only last 100 records)
  Future<void> cleanupOldLogs() async {
    try {
      if (_auth.currentUser == null) {
        return;
      }

      // Get all backup logs for the user
      QuerySnapshot allLogs = await _firestore
          .collection('backup_history')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      if (allLogs.docs.length <= 100) {
        return; // No cleanup needed
      }

      // Sort logs by timestamp in memory (most recent first)
      List<QueryDocumentSnapshot> sortedLogs = allLogs.docs.toList();
      sortedLogs.sort((a, b) {
        Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
        Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;

        DateTime dateA = dataA['timestamp'] != null
            ? (dataA['timestamp'] as Timestamp).toDate()
            : DateTime.now();
        DateTime dateB = dataB['timestamp'] != null
            ? (dataB['timestamp'] as Timestamp).toDate()
            : DateTime.now();

        return dateB.compareTo(dateA); // Most recent first
      });

      // Keep only the first 100 (most recent) and delete the rest
      List<QueryDocumentSnapshot> logsToDelete = sortedLogs.skip(100).toList();

      if (logsToDelete.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        for (var doc in logsToDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('Cleaned up ${logsToDelete.length} old backup log entries');
      }
    } catch (e) {
      print('Error cleaning up old logs: $e');
    }
  }
}
