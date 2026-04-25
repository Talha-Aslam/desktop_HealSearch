import 'dart:io';
import 'dart:convert';

import 'package:desktop_search_a_holic/data/database.dart';
import 'package:desktop_search_a_holic/main.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:desktop_search_a_holic/tenant_provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadData extends StatefulWidget {
  const UploadData({super.key});

  @override
  State<UploadData> createState() => _UploadDataState();
}

class _UploadDataState extends State<UploadData> {
  bool _isBusy = false;
  String _status = '';
  List<Map<String, dynamic>> _previewRows = const [];

  Future<String?> _resolvePharmacyId() async {
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    final fromProvider = tenantProvider.pharmacyId;
    if (fromProvider != null && fromProvider.isNotEmpty) {
      return fromProvider;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select('pharmacy_id')
        .eq('id', user.id)
        .maybeSingle();

    final pharmacyId = profile?['pharmacy_id'] as String?;
    if (pharmacyId != null && pharmacyId.isNotEmpty) {
      tenantProvider.setPharmacyId(pharmacyId);
    }
    return pharmacyId;
  }

  Future<void> _pickAndImportInventory() async {
    final pharmacyId = await _resolvePharmacyId();
    if (pharmacyId == null) {
      _showError('No active pharmacy session found. Please login again.');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isBusy = true;
        _status = 'Reading file...';
      });

      final path = result.files.single.path!;
      final fileName = result.files.single.name.toLowerCase();

      List<Map<String, dynamic>> rows;
      if (fileName.endsWith('.xlsx')) {
        rows = await _readXlsxRows(path);
      } else {
        rows = await _readCsvRows(path);
      }

      if (rows.isEmpty) {
        throw Exception('No valid product rows found in file.');
      }

      setState(() {
        _previewRows = rows.take(5).toList();
        _status = 'Parsed ${rows.length} rows. Ready to import.';
      });

      if (!mounted) return;
      _showImportConfirmation(rows, pharmacyId);
    } catch (e) {
      _showError('Import failed: $e');
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _readXlsxRows(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw Exception('Workbook has no sheets.');
    }

    final sheet = workbook.tables.values.first;
    if (sheet.maxRows < 2) {
      throw Exception(
          'Excel must contain header row and at least one data row.');
    }

    final headers = sheet.rows.first
        .map((cell) => (cell?.value?.toString() ?? '').trim().toLowerCase())
        .toList();

    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < sheet.maxRows; i++) {
      final row = i < sheet.rows.length ? sheet.rows[i] : const [];
      final mapped = _mapRow(
        headers,
        List<String>.generate(
          headers.length,
          (idx) => idx < row.length
              ? (row[idx]?.value?.toString() ?? '').trim()
              : '',
        ),
      );
      if (mapped != null) {
        rows.add(mapped);
      }
    }

    return rows;
  }

  Future<List<Map<String, dynamic>>> _readCsvRows(String filePath) async {
    final content = await File(filePath).readAsString();
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      throw Exception('CSV must contain header row and at least one data row.');
    }

    final headers = lines.first
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList(growable: false);

    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < lines.length; i++) {
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      final mapped = _mapRow(headers, values);
      if (mapped != null) {
        rows.add(mapped);
      }
    }
    return rows;
  }

  Map<String, dynamic>? _mapRow(List<String> headers, List<String> values) {
    String? name;
    String? genericName;
    String? category;
    double price = 0;
    int stock = 0;
    DateTime? expiryDate;

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      final value = i < values.length ? values[i] : '';

      if (header.contains('name') && !header.contains('generic')) {
        name = value;
      } else if (header.contains('generic')) {
        genericName = value.isEmpty ? null : value;
      } else if (header.contains('category')) {
        category = value.isEmpty ? null : value;
      } else if (header.contains('price')) {
        price = double.tryParse(value) ?? 0;
      } else if (header.contains('quantity') || header.contains('stock')) {
        stock = int.tryParse(value) ?? 0;
      } else if (header.contains('expiry')) {
        expiryDate = DateTime.tryParse(value);
      }
    }

    if (name == null || name.trim().isEmpty) {
      return null;
    }

    return {
      'name': name.trim(),
      'genericName': genericName,
      'category': category,
      'price': price,
      'stock': stock,
      'expiryDate': expiryDate,
    };
  }

  void _showImportConfirmation(
    List<Map<String, dynamic>> rows,
    String pharmacyId,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeProvider.cardBackgroundColor,
        title: Text(
          'Confirm Bulk Import',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import ${rows.length} products into your inventory?',
                style: TextStyle(color: themeProvider.textColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Preview:',
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: _previewRows.length,
                  itemBuilder: (context, index) {
                    final item = _previewRows[index];
                    return Text(
                      '- ${item['name']} | ${item['stock']} pcs | \$${(item['price'] as num).toStringAsFixed(2)}',
                      style: TextStyle(color: themeProvider.textColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _isBusy = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _importRowsToInventory(rows, pharmacyId);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importRowsToInventory(
    List<Map<String, dynamic>> rows,
    String pharmacyId,
  ) async {
    try {
      var inserted = 0;
      for (final row in rows) {
        await appDb.into(appDb.medicines).insert(
              MedicinesCompanion(
                pharmacyId: drift.Value(pharmacyId),
                name: drift.Value(row['name'] as String),
                genericName: drift.Value(row['genericName'] as String?),
                category: drift.Value(row['category'] as String?),
                price: drift.Value((row['price'] as num).toDouble()),
                stock: drift.Value((row['stock'] as num).toInt()),
                expiryDate: drift.Value(row['expiryDate'] as DateTime?),
              ),
            );
        inserted++;
      }

      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _status = 'Import complete: $inserted product(s) added.';
      });

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Import Completed',
        text: '$inserted products imported successfully.',
      );
    } catch (e) {
      _showError('Failed to import inventory: $e');
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _exportInventoryToExcel() async {
    await _exportToExcel(
      exportType: 'inventory',
      buildRows: (pharmacyId) async {
        final rows = await (appDb.select(appDb.medicines)
              ..where((t) => t.pharmacyId.equals(pharmacyId))
              ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
            .get();

        return rows
            .map((m) => [
                  m.id,
                  m.name,
                  m.genericName ?? '',
                  m.category ?? '',
                  m.price,
                  m.stock,
                  m.expiryDate?.toIso8601String() ?? '',
                ])
            .toList();
      },
      headers: const [
        'ID',
        'Name',
        'Generic Name',
        'Category',
        'Price',
        'Stock',
        'Expiry Date'
      ],
    );
  }

  Future<void> _exportSalesToExcel() async {
    await _exportToExcel(
      exportType: 'sales',
      buildRows: (pharmacyId) async {
        final rows = await (appDb.select(appDb.sales)
              ..where((t) => t.pharmacyId.equals(pharmacyId))
              ..orderBy([
                (t) => drift.OrderingTerm(
                    expression: t.createdAt, mode: drift.OrderingMode.desc)
              ]))
            .get();

        return rows
            .map((s) => [s.id, s.totalAmount, s.createdAt.toIso8601String()])
            .toList();
      },
      headers: const ['Sale ID', 'Total Amount', 'Created At'],
    );
  }

  Future<void> _exportInvoicesToExcel() async {
    await _exportToExcel(
      exportType: 'invoices',
      buildRows: (pharmacyId) async {
        final rows = await (appDb.select(appDb.sales)
              ..where((t) => t.pharmacyId.equals(pharmacyId))
              ..orderBy([
                (t) => drift.OrderingTerm(
                    expression: t.createdAt, mode: drift.OrderingMode.desc)
              ]))
            .get();

        final detailedRows = <List<Object?>>[];

        for (final sale in rows) {
          final invoiceNumber = 'INV-${sale.id.toString().padLeft(6, '0')}';
          final createdAt = sale.createdAt.toIso8601String();

          List<Map<String, dynamic>> items = const [];
          if (sale.itemsJson != null && sale.itemsJson!.trim().isNotEmpty) {
            try {
              final decoded = jsonDecode(sale.itemsJson!);
              if (decoded is List) {
                items = decoded
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
              }
            } catch (_) {
              items = const [];
            }
          }

          if (items.isEmpty) {
            detailedRows.add([
              invoiceNumber,
              createdAt,
              'Walk-in Customer',
              '',
              0,
              0,
              0,
              sale.totalAmount,
              'PAID',
              'Cash',
            ]);
            continue;
          }

          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            final unitPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
            final lineTotal = (item['subtotal'] as num?)?.toDouble() ??
                (quantity * unitPrice);

            detailedRows.add([
              i == 0 ? invoiceNumber : '',
              i == 0 ? createdAt : '',
              i == 0 ? 'Walk-in Customer' : '',
              item['name']?.toString() ?? 'Unknown Item',
              quantity,
              unitPrice,
              lineTotal,
              i == 0 ? sale.totalAmount : '',
              i == 0 ? 'PAID' : '',
              i == 0 ? 'Cash' : '',
            ]);
          }
        }

        return detailedRows;
      },
      headers: const [
        'Invoice Number',
        'Created At',
        'Customer',
        'Product Name',
        'Quantity',
        'Unit Price',
        'Line Total',
        'Invoice Total',
        'Status',
        'Payment Method'
      ],
    );
  }

  Future<void> _exportToExcel({
    required String exportType,
    required Future<List<List<Object?>>> Function(String pharmacyId) buildRows,
    required List<String> headers,
  }) async {
    final pharmacyId = await _resolvePharmacyId();
    if (pharmacyId == null) {
      _showError('No active pharmacy session found. Please login again.');
      return;
    }

    try {
      setState(() {
        _isBusy = true;
        _status = 'Preparing $exportType export...';
      });

      final rows = await buildRows(pharmacyId);
      final workbook = Excel.createExcel();
      final sheetName = '${exportType}_data';
      final sheet = workbook[sheetName];

      // Remove the default empty sheet so users don't land on a blank tab.
      if (sheetName != 'Sheet1' && workbook.tables.containsKey('Sheet1')) {
        workbook.delete('Sheet1');
      }

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
      for (final row in rows) {
        sheet.appendRow(
          row.map((value) => TextCellValue(value?.toString() ?? '')).toList(),
        );
      }

      final saveDir = await getApplicationDocumentsDirectory();
      final exportDir =
          Directory(p.join(saveDir.path, 'HealSearch', 'Exports'));
      if (!exportDir.existsSync()) {
        await exportDir.create(recursive: true);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final filePath = p.join(exportDir.path, '${exportType}_$now.xlsx');
      final encoded = workbook.encode();
      if (encoded == null) {
        throw Exception('Unable to generate Excel file.');
      }

      await File(filePath).writeAsBytes(encoded, flush: true);

      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _status =
            '${exportType.toUpperCase()} export complete: ${rows.length} row(s) to $filePath';
      });

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Export Complete',
        text:
            '${exportType.toUpperCase()} exported successfully with ${rows.length} row(s).\n$filePath',
      );
    } catch (e) {
      _showError('Export failed: $e');
      setState(() {
        _isBusy = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Error',
      text: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeProvider.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            elevation: 4,
            title: const Text(
              'Bulk Data Import / Export',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Container(
                  color: themeProvider.scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory Bulk Operations',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Import from CSV/XLSX and export Inventory, Sales, and Invoices as Excel backups.',
                          style: TextStyle(
                            color: themeProvider.textColor.withOpacity(0.7),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 18,
                          runSpacing: 16,
                          children: [
                            _buildOperationButton(
                              context,
                              themeProvider,
                              onPressed:
                                  _isBusy ? null : _pickAndImportInventory,
                              icon: Icons.upload_file,
                              label: 'Import Inventory (Excel/CSV)',
                              isPrimary: true,
                            ),
                            _buildOperationButton(
                              context,
                              themeProvider,
                              onPressed:
                                  _isBusy ? null : _exportInventoryToExcel,
                              icon: Icons.inventory_2,
                              label: 'Export Inventory (Excel)',
                            ),
                            _buildOperationButton(
                              context,
                              themeProvider,
                              onPressed: _isBusy ? null : _exportSalesToExcel,
                              icon: Icons.shopping_bag,
                              label: 'Export Sales (Excel)',
                            ),
                            _buildOperationButton(
                              context,
                              themeProvider,
                              onPressed:
                                  _isBusy ? null : _exportInvoicesToExcel,
                              icon: Icons.receipt_long,
                              label: 'Export Invoices (Excel)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isBusy)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              backgroundColor: themeProvider.gradientColors[0]
                                  .withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                themeProvider.gradientColors[0],
                              ),
                            ),
                          ),
                        if (_status.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: themeProvider.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeProvider.gradientColors[0]
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isBusy
                                      ? Icons.hourglass_bottom
                                      : Icons.check_circle,
                                  color: _isBusy
                                      ? themeProvider.gradientColors[0]
                                      : Colors.green.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _status,
                                    style: TextStyle(
                                      color: themeProvider.textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOperationButton(
    BuildContext context,
    ThemeProvider themeProvider, {
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? themeProvider.gradientColors[0]
            : themeProvider.gradientColors[0].withOpacity(0.7),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        elevation: isPrimary ? 4 : 2,
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
