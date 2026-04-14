import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:desktop_search_a_holic/firebase_service.dart';
import 'package:quickalert/quickalert.dart';

class UploadData extends StatefulWidget {
  const UploadData({super.key});

  @override
  _UploadDataState createState() => _UploadDataState();
}

class _UploadDataState extends State<UploadData> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isUploading = false;
  String _uploadStatus = '';
  List<Map<String, dynamic>> _previewData = [];

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
          _uploadStatus = 'Reading file...';
        });

        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        String fileContent = await file.readAsString();

        if (fileName.toLowerCase().endsWith('.csv')) {
          await _processCsvFile(fileContent);
        } else if (fileName.toLowerCase().endsWith('.json')) {
          await _processJsonFile(fileContent);
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Error: ${e.toString()}';
      });

      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Upload Failed',
        text: 'Failed to upload file: ${e.toString()}',
      );
    }
  }

  Future<void> _processCsvFile(String csvContent) async {
    setState(() {
      _uploadStatus = 'Processing CSV file...';
    });

    List<String> lines = csvContent.split('\n');
    if (lines.isEmpty || lines.length < 2) {
      throw Exception('CSV file must contain header and at least one data row');
    }

    // Parse header
    List<String> headers = lines[0].split(',').map((h) => h.trim()).toList();

    // Validate required columns for products
    List<String> requiredColumns = ['name', 'price', 'quantity', 'category'];
    for (String required in requiredColumns) {
      if (!headers
          .any((h) => h.toLowerCase().contains(required.toLowerCase()))) {
        throw Exception('CSV must contain column: $required');
      }
    }

    List<Map<String, dynamic>> products = [];

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      List<String> values = lines[i].split(',').map((v) => v.trim()).toList();
      if (values.length != headers.length) continue;

      Map<String, dynamic> product = {};
      for (int j = 0; j < headers.length; j++) {
        String header = headers[j].toLowerCase();
        String value = values[j];

        if (header.contains('name')) {
          product['name'] = value;
        } else if (header.contains('price')) {
          product['price'] = double.tryParse(value) ?? 0.0;
        } else if (header.contains('quantity')) {
          product['quantity'] = int.tryParse(value) ?? 0;
        } else if (header.contains('category')) {
          product['category'] = value;
        } else if (header.contains('expiry')) {
          product['expiry'] = value;
        } else if (header.contains('type')) {
          product['type'] = value;
        }
      }

      // Set defaults
      product['type'] = product['type'] ?? 'Public';
      product['expiry'] = product['expiry'] ?? '2025-12-31';
      product['userEmail'] = _firebaseService.currentUser?.email ?? '';

      if (product['name'] != null && product['name'].toString().isNotEmpty) {
        products.add(product);
      }
    }

    setState(() {
      _previewData = products.take(5).toList(); // Show first 5 for preview
      _uploadStatus =
          'Found ${products.length} products. Review and confirm upload.';
    });

    _showUploadConfirmation(products);
  }

  Future<void> _processJsonFile(String jsonContent) async {
    setState(() {
      _uploadStatus = 'Processing JSON file...';
    });

    Map<String, dynamic> jsonData = json.decode(jsonContent);

    List<Map<String, dynamic>> products = [];

    if (jsonData.containsKey('products')) {
      List<dynamic> productList = jsonData['products'];
      for (var item in productList) {
        if (item is Map<String, dynamic>) {
          // Ensure required fields
          if (item['name'] != null && item['price'] != null) {
            Map<String, dynamic> product = Map<String, dynamic>.from(item);
            product['userEmail'] = _firebaseService.currentUser?.email ?? '';
            product['type'] = product['type'] ?? 'Public';
            product['expiry'] = product['expiry'] ?? '2025-12-31';
            product['quantity'] = product['quantity'] ?? 0;
            product['category'] = product['category'] ?? 'Other';
            products.add(product);
          }
        }
      }
    }

    setState(() {
      _previewData = products.take(5).toList();
      _uploadStatus =
          'Found ${products.length} products. Review and confirm upload.';
    });

    _showUploadConfirmation(products);
  }

  void _showUploadConfirmation(List<Map<String, dynamic>> products) {
    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return AlertDialog(
          backgroundColor: themeProvider.cardBackgroundColor,
          title: Text(
            'Confirm Upload',
            style: TextStyle(color: themeProvider.textColor),
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to upload ${products.length} products.',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preview (first 5 items):',
                  style: TextStyle(color: themeProvider.textColor),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _previewData.length,
                    itemBuilder: (context, index) {
                      final product = _previewData[index];
                      return Card(
                        color: themeProvider.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        child: ListTile(
                          title: Text(
                            product['name'] ?? 'Unknown',
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                          subtitle: Text(
                            'Price: \$${product['price']} | Qty: ${product['quantity']} | Category: ${product['category']}',
                            style: TextStyle(
                              color: themeProvider.textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
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
                Navigator.pop(context);
                setState(() {
                  _isUploading = false;
                  _uploadStatus = '';
                  _previewData.clear();
                });
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.textColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadProducts(products);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.gradientColors[0],
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadProducts(List<Map<String, dynamic>> products) async {
    setState(() {
      _uploadStatus = 'Uploading products to database...';
    });

    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < products.length; i++) {
      try {
        await _firebaseService.addProduct(products[i]);
        successCount++;

        setState(() {
          _uploadStatus =
              'Uploaded $successCount/${products.length} products...';
        });
      } catch (e) {
        errorCount++;
        print('Error uploading product ${products[i]['name']}: $e');
      }
    }

    setState(() {
      _isUploading = false;
      _uploadStatus =
          'Upload complete: $successCount successful, $errorCount failed';
      _previewData.clear();
    });

    QuickAlert.show(
      context: context,
      type: successCount > 0 ? QuickAlertType.success : QuickAlertType.error,
      title: 'Upload Complete',
      text:
          'Successfully uploaded $successCount products. ${errorCount > 0 ? '$errorCount failed.' : ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
        title: const Text(
          'Upload Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: themeProvider.scaffoldBackgroundColor,
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Text(
                    'Import Products from File',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload CSV or JSON files to import products into your inventory',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upload section
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 500,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: themeProvider.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Upload icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: themeProvider.gradientColors[0]
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                Icons.cloud_upload,
                                size: 40,
                                color: themeProvider.gradientColors[0],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              'Upload Product Data',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Description
                            Text(
                              'Select a CSV or JSON file containing your product data',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeProvider.textColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Upload button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isUploading ? null : _pickAndUploadFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      themeProvider.gradientColors[0],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.file_upload),
                                label: Text(
                                  _isUploading ? 'Uploading...' : 'Choose File',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // Status message
                            if (_uploadStatus.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _uploadStatus,
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Format information
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: themeProvider.gradientColors[0]
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: themeProvider.gradientColors[0]
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: themeProvider.gradientColors[0],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Supported File Formats',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: themeProvider.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'CSV: Must include columns for name, price, quantity, category\nJSON: Must have a "products" array with product objects',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: themeProvider.textColor
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
