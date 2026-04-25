import 'package:desktop_search_a_holic/main.dart';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static bool _reportedItemsJsonWarning = false;

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

  // Get recent invoices from local Drift sales table (tenant-scoped).
  Future<List<Map<String, dynamic>>> getRecentInvoices({int limit = 10}) async {
    final pharmacyId = await _getPharmacyId();
    if (pharmacyId == null) return [];

    final rows = await (appDb.select(appDb.sales)
          ..where((t) => t.pharmacyId.equals(pharmacyId))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.createdAt, mode: drift.OrderingMode.desc)
          ])
          ..limit(limit))
        .get();

    return rows
        .map((sale) => {
              'id': sale.id.toString(),
              'invoiceNumber': 'INV-${sale.id.toString().padLeft(6, '0')}',
              'customerName': 'Walk-in Customer',
              'customerPhone': 'N/A',
              'date': sale.createdAt,
              'items': _decodeItemsJson(sale.itemsJson),
              'subtotal': sale.totalAmount,
              'tax': 0.0,
              'discount': 0.0,
              'total': sale.totalAmount,
              'status': 'PAID',
              'paymentMethod': 'Cash',
            })
        .toList();
  }

  Future<Map<String, dynamic>?> getInvoiceById(String saleId) async {
    final pharmacyId = await _getPharmacyId();
    if (pharmacyId == null) return null;

    final id = int.tryParse(saleId);
    if (id == null) return null;

    final row = await (appDb.select(appDb.sales)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.pharmacyId.equals(pharmacyId)))
        .getSingleOrNull();

    if (row == null) return null;

    return {
      'id': row.id.toString(),
      'invoiceNumber': 'INV-${row.id.toString().padLeft(6, '0')}',
      'customerName': 'Walk-in Customer',
      'customerPhone': 'N/A',
      'date': row.createdAt,
      'items': _decodeItemsJson(row.itemsJson),
      'subtotal': row.totalAmount,
      'tax': 0.0,
      'discount': 0.0,
      'total': row.totalAmount,
      'status': 'PAID',
      'paymentMethod': 'Cash',
    };
  }

  Future<void> backupInvoiceToSupabase({
    required int saleId,
    required String pharmacyId,
    required double totalAmount,
    required DateTime createdAt,
    String? itemsJson,
  }) async {
    final payload = {
      'id': saleId,
      'pharmacy_id': pharmacyId,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      if (itemsJson != null) 'items_json': itemsJson,
    };

    try {
      await _supabase.from('sales').upsert(payload);
    } catch (_) {
      if (itemsJson == null) rethrow;

      if (!_reportedItemsJsonWarning) {
        _reportedItemsJsonWarning = true;
        print(
            'WARNING: Supabase sales table does not accept items_json. Invoice backup is falling back to summary-only rows.');
      }

      await _supabase.from('sales').upsert({
        'id': saleId,
        'pharmacy_id': pharmacyId,
        'total_amount': totalAmount,
        'created_at': createdAt.toIso8601String(),
      });
    }
  }

  Future<bool> deleteInvoice(String saleId) async {
    final pharmacyId = await _getPharmacyId();
    if (pharmacyId == null) return false;

    final id = int.tryParse(saleId);
    if (id == null) return false;

    final deleted = await (appDb.delete(appDb.sales)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.pharmacyId.equals(pharmacyId)))
        .go();

    // Best-effort cloud cleanup for backup row.
    try {
      await _supabase
          .from('sales')
          .delete()
          .eq('id', id)
          .eq('pharmacy_id', pharmacyId);
    } catch (_) {
      // Ignore cloud cleanup failures; local source of truth already updated.
    }

    return deleted > 0;
  }

  List<Map<String, dynamic>> _decodeItemsJson(String? itemsJson) {
    if (itemsJson == null || itemsJson.trim().isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(itemsJson);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {
      // Fallback below.
    }

    return const <Map<String, dynamic>>[];
  }

  // Backward-compatible helper used by existing UI code.
  String generatePrintableInvoiceText(Map<String, dynamic> invoice) {
    return generateInvoiceText(invoice);
  }

  String generateInvoiceText(Map<String, dynamic> invoice) {
    final buffer = StringBuffer();

    buffer.writeln('HEALSEARCH');
    buffer.writeln('Invoice: ${invoice['invoiceNumber']}');
    buffer.writeln(
        'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(invoice['date'])}');
    buffer.writeln('Customer: ${invoice['customerName']}');
    buffer.writeln('Phone: ${invoice['customerPhone']}');
    buffer.writeln('----------------------------------------');

    final items = (invoice['items'] as List<dynamic>? ?? const []);
    if (items.isEmpty) {
      buffer.writeln('No line-items available for this invoice.');
      buffer.writeln('This invoice was generated from local sales total.');
    } else {
      for (final item in items) {
        final name = item['name']?.toString() ?? 'Item';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final lineTotal = qty * price;
        buffer.writeln(
            '$name x$qty  @ ${price.toStringAsFixed(2)} = ${lineTotal.toStringAsFixed(2)}');
      }
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('Subtotal: ${invoice['subtotal'].toStringAsFixed(2)}');
    buffer.writeln('Tax:      ${invoice['tax'].toStringAsFixed(2)}');
    buffer.writeln('Discount: ${invoice['discount'].toStringAsFixed(2)}');
    buffer.writeln('TOTAL:    ${invoice['total'].toStringAsFixed(2)}');
    buffer.writeln('Status: ${invoice['status']}');

    return buffer.toString();
  }

  String generateShareableInvoiceText(Map<String, dynamic> invoice) {
    return generateInvoiceText(invoice);
  }

  String generateEmailInvoiceText(Map<String, dynamic> invoice) {
    return generateInvoiceText(invoice);
  }
}
