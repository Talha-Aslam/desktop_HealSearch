import 'dart:async';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart';

class SupabaseSyncService {
  final AppDatabase db;
  final SupabaseClient supabase;
  Timer? _syncTimer;
  bool? _salesSupportsItemsJson;
  bool _reportedMissingItemsJsonWarning = false;

  SupabaseSyncService(this.db, this.supabase);

  /// Starts the background synchronization process
  void startSync({Duration interval = const Duration(minutes: 1)}) {
    // Run periodically
    _syncTimer = Timer.periodic(interval, (_) => _performSync());

    // Also trigger an initial sync immediately on startup
    _performSync();
  }

  /// Stops the background synchronization process
  void stopSync() {
    _syncTimer?.cancel();
  }

  Future<void> _performSync() async {
    try {
      await _syncSales();
      // Note: By your definition, Medicines don't have an `is_synced_to_cloud` flag right now.
      // If they are strictly read-only from the cloud or synced differently, we handle that separately.
    } catch (e) {
      print('Background Sync Error: $e');
    }
  }

  Future<void> _syncSales() async {
    // 0. Ensure user is authenticated to get the Tenant ID
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profile = await supabase
        .from('user_profiles')
        .select('pharmacy_id')
        .eq('id', user.id)
        .maybeSingle();

    final pharmacyId = profile?['pharmacy_id'] as String?;
    if (pharmacyId == null) return;

    final supportsItemsJson = await _salesTableSupportsItemsJson();

    // 1. Fetch all unsynced sales from local Drift database
    final unsyncedSales = await (db.select(db.sales)
          ..where((t) => t.isSyncedToCloud.equals(false)))
        .get();

    if (unsyncedSales.isEmpty) {
      return; // Nothing to sync
    }

    // 2. Map Drift objects to JSON for Supabase
    final salesData = unsyncedSales
        .map((sale) => {
              'id': sale.id,
              'total_amount': sale.totalAmount,
              'created_at': sale.createdAt.toIso8601String(),
              'pharmacy_id': pharmacyId, // INJECT TENANT ID FOR RLS
              if (supportsItemsJson) 'items_json': sale.itemsJson,
            })
        .toList();

    // 3. Push to Supabase (upsert is safest in case of retries/conflicts)
    try {
      await supabase.from('sales').upsert(salesData);
    } catch (e) {
      // If the cloud schema doesn't support items_json yet, retry summary-only.
      if (supportsItemsJson) {
        _salesSupportsItemsJson = false;
        if (!_reportedMissingItemsJsonWarning) {
          _reportedMissingItemsJsonWarning = true;
          print(
              'WARNING: Supabase sales table appears to be missing items_json. Detailed invoice items will not sync until this column exists.');
        }

        final fallbackSalesData = unsyncedSales
            .map((sale) => {
                  'id': sale.id,
                  'total_amount': sale.totalAmount,
                  'created_at': sale.createdAt.toIso8601String(),
                  'pharmacy_id': pharmacyId,
                })
            .toList();
        await supabase.from('sales').upsert(fallbackSalesData);
      } else {
        rethrow;
      }
    }

    // 4. Update the local records to mark them as synced
    for (final sale in unsyncedSales) {
      await (db.update(db.sales)..where((t) => t.id.equals(sale.id)))
          .write(const SalesCompanion(isSyncedToCloud: Value(true)));
    }

    print('Successfully synced ${unsyncedSales.length} sales to Supabase.');
  }

  Future<bool> _salesTableSupportsItemsJson() async {
    if (_salesSupportsItemsJson != null) {
      return _salesSupportsItemsJson!;
    }

    try {
      await supabase.from('sales').select('items_json').limit(1);
      _salesSupportsItemsJson = true;
      return true;
    } catch (_) {
      _salesSupportsItemsJson = false;
      if (!_reportedMissingItemsJsonWarning) {
        _reportedMissingItemsJsonWarning = true;
        print(
            'WARNING: Supabase sales table is missing items_json. Add this column to store invoice line-item details in cloud backups.');
      }
      return false;
    }
  }
}
