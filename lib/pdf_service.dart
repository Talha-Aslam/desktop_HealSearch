import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfService {
  static const String _appName = 'HealSearch';

  /// Generate a professional formatted invoice text that can be used for PDF creation
  static String generateInvoiceText(Map<String, dynamic> invoice) {
    final StringBuffer buffer = StringBuffer();

    // Professional Header with company branding
    buffer.writeln(
        '╔════════════════════════════════════════════════════════════════════╗');
    buffer.writeln(
        '║                            HEALSEARCH                             ║');
    buffer.writeln(
        '║                      Digital Inventory System                     ║');
    buffer.writeln(
        '║                                                                    ║');
    buffer.writeln(
        '║  📍 Address: 123 Business Street, Suite 100, City, State 12345   ║');
    buffer.writeln(
        '║  📧 Email: info@healsearch.com                                    ║');
    buffer.writeln(
        '║  📞 Phone: +1 (555) 123-4567                                     ║');
    buffer.writeln(
        '║  🌐 Website: www.healsearch.com                                   ║');
    buffer.writeln(
        '╚════════════════════════════════════════════════════════════════════╝');
    buffer.writeln();

    // Invoice Title
    buffer.writeln('                               📄 INVOICE');
    buffer.writeln(
        '════════════════════════════════════════════════════════════════════');
    buffer.writeln();

    // Invoice Details and Bill To in organized layout
    buffer.writeln(
        '┌─ INVOICE INFORMATION ─────────────────┬─ BILL TO ─────────────────────┐');

    String invoiceId = 'Invoice ID: ${invoice['id'] ?? 'N/A'}';
    String customerName =
        'Customer: ${invoice['customerName'] ?? 'Walk-in Customer'}';
    buffer.writeln(
        '│ ${invoiceId.padRight(38)} │ ${customerName.padRight(29)} │');

    String invoiceDate =
        'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(invoice['date'] ?? DateTime.now())}';
    String address = 'Address: Not provided';
    buffer.writeln('│ ${invoiceDate.padRight(38)} │ ${address.padRight(29)} │');

    String invoiceStatus = 'Status: ${invoice['status'] ?? 'Completed'}';
    String phone = invoice['customerPhone'] != null &&
            invoice['customerPhone'].toString().isNotEmpty
        ? 'Phone: ${invoice['customerPhone']}'
        : 'Phone: Not provided';
    buffer.writeln('│ ${invoiceStatus.padRight(38)} │ ${phone.padRight(29)} │');

    String paymentMethod = 'Payment: ${invoice['paymentMethod'] ?? 'Cash'}';
    String email = 'Email: Not provided';
    buffer.writeln('│ ${paymentMethod.padRight(38)} │ ${email.padRight(29)} │');

    buffer.writeln(
        '└───────────────────────────────────────┴───────────────────────────────┘');
    buffer.writeln();

    // Items table with enhanced formatting
    buffer.writeln('                          📦 ITEMS & SERVICES');
    buffer.writeln(
        '════════════════════════════════════════════════════════════════════');
    buffer.writeln(
        '┌────┬─────────────────────────────┬─────┬───────────┬──────────────┐');
    buffer.writeln(
        '│ #  │ Description                 │ Qty │ Unit Price│ Amount       │');
    buffer.writeln(
        '├────┼─────────────────────────────┼─────┼───────────┼──────────────┤');

    if (invoice['items'] != null) {
      List<dynamic> items = invoice['items'];
      for (int i = 0; i < items.length; i++) {
        var item = items[i];
        String itemNum = '${i + 1}'.padLeft(2);

        String name = (item['name'] ?? 'Unknown').toString();
        if (name.length > 27) name = '${name.substring(0, 24)}...';
        name = name.padRight(27);

        int qty = item['quantity'] ?? 0;
        double price = (item['price'] ?? 0.0).toDouble();
        double total = price * qty;

        String qtyStr = qty.toString().padLeft(3);
        String priceStr = '\$${price.toStringAsFixed(2)}'.padLeft(9);
        String totalStr = '\$${total.toStringAsFixed(2)}'.padLeft(12);

        buffer
            .writeln('│ $itemNum │ $name │ $qtyStr │ $priceStr │ $totalStr │');
      }
    }

    buffer.writeln(
        '└────┴─────────────────────────────┴─────┴───────────┴──────────────┘');
    buffer.writeln();

    // Payment Summary with professional styling
    buffer.writeln('                           💰 PAYMENT SUMMARY');
    buffer.writeln(
        '════════════════════════════════════════════════════════════════════');

    double subtotal = (invoice['subtotal'] ?? 0.0).toDouble();
    double tax = (invoice['tax'] ?? 0.0).toDouble();
    double discount = (invoice['discount'] ?? 0.0).toDouble();
    double total = (invoice['total'] ?? 0.0).toDouble();

    // Calculate additional statistics
    int totalItems = 0;
    int totalQuantity = 0;
    if (invoice['items'] != null) {
      List<dynamic> items = invoice['items'];
      totalItems = items.length;
      totalQuantity =
          items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
    }

    // Left column: Breakdown, Right column: Summary
    buffer.writeln(
        '┌─ COST BREAKDOWN ──────────────────────┬─ ORDER SUMMARY ──────────────┐');
    buffer.writeln(
        '│ Subtotal:              \$${subtotal.toStringAsFixed(2).padLeft(12)} │ Total Items:         ${totalItems.toString().padLeft(8)} │');
    if (discount > 0) {
      buffer.writeln(
          '│ Discount Applied:     -\$${discount.toStringAsFixed(2).padLeft(12)} │ Total Quantity:      ${totalQuantity.toString().padLeft(8)} │');
    } else {
      buffer.writeln(
          '│ Discount Applied:      \$${0.00.toStringAsFixed(2).padLeft(12)} │ Total Quantity:      ${totalQuantity.toString().padLeft(8)} │');
    }
    buffer.writeln(
        '│ Tax (10%):             \$${tax.toStringAsFixed(2).padLeft(12)} │ Payment Method:    ${(invoice['paymentMethod'] ?? 'Cash').toString().padLeft(10)} │');
    buffer.writeln(
        '├───────────────────────────────────────┼───────────────────────────────┤');
    buffer.writeln(
        '│ 💵 TOTAL AMOUNT DUE:   \$${total.toStringAsFixed(2).padLeft(12)} │ Status:              ${(invoice['status'] ?? 'Paid').toString().padLeft(8)} │');
    buffer.writeln(
        '└───────────────────────────────────────┴───────────────────────────────┘');
    buffer.writeln();

    // Additional Information
    buffer.writeln('                        ℹ️  ADDITIONAL INFORMATION');
    buffer.writeln(
        '════════════════════════════════════════════════════════════════════');
    buffer.writeln(
        '┌─ TRANSACTION DETAILS ─────────────────────────────────────────────┐');
    String transactionId = (invoice['id'] ?? '').toString();
    if (transactionId.length > 8) {
      transactionId = transactionId.substring(0, 8).toUpperCase();
    }
    buffer.writeln(
        '│ Transaction ID: ${transactionId.padLeft(20)}                                     │');
    buffer.writeln(
        '│ Generated On: ${DateFormat('EEEE, MMMM dd, yyyy @ hh:mm a').format(DateTime.now()).padLeft(35)}   │');
    String dueDate = DateFormat('MMM dd, yyyy')
        .format(DateTime.now().add(Duration(days: 30)));
    buffer.writeln(
        '│ Due Date: ${dueDate.padLeft(25)} (Net 30)                              │');
    buffer.writeln(
        '└───────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    // Terms and Conditions
    buffer.writeln('                         📋 TERMS & CONDITIONS');
    buffer.writeln(
        '════════════════════════════════════════════════════════════════════');
    buffer.writeln(
        '┌─ IMPORTANT INFORMATION ───────────────────────────────────────────┐');
    buffer.writeln(
        '│ 1. Payment is due within 30 days of invoice date                  │');
    buffer.writeln(
        '│ 2. All sales are final unless otherwise agreed upon               │');
    buffer.writeln(
        '│ 3. Returns accepted within 30 days with original receipt          │');
    buffer.writeln(
        '│ 4. Late payments may incur additional charges                      │');
    buffer.writeln(
        '│ 5. For support or questions: support@healsearch.com               │');
    buffer.writeln(
        '│ 6. Business hours: Monday-Friday 9AM-6PM, Saturday 10AM-4PM       │');
    buffer.writeln(
        '└───────────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    // Professional Footer
    buffer.writeln(
        '╔════════════════════════════════════════════════════════════════════╗');
    buffer.writeln(
        '║                                                                    ║');
    buffer.writeln(
        '║                  🙏 THANK YOU FOR YOUR BUSINESS! 🙏                ║');
    buffer.writeln(
        '║                                                                    ║');
    buffer.writeln(
        '║              Your trust and loyalty mean everything to us          ║');
    buffer.writeln(
        '║                                                                    ║');
    buffer.writeln(
        '║             📧 Questions? Contact us at info@healsearch.com       ║');
    buffer.writeln(
        '║             📞 Phone Support: +1 (555) 123-4567                   ║');
    buffer.writeln(
        '║             🌐 Visit us online: www.healsearch.com                 ║');
    buffer.writeln(
        '║                                                                    ║');
    buffer.writeln(
        '║                    Generated by HealSearch System                 ║');
    buffer.writeln(
        '║                        Professional Invoice v2.0                  ║');
    buffer.writeln(
        '╚════════════════════════════════════════════════════════════════════╝');

    return buffer.toString();
  }

  /// Generate a formatted sales report text
  static String generateSalesReportText(Map<String, dynamic> reportData) {
    final StringBuffer buffer = StringBuffer();

    // Header
    buffer.writeln('=' * 70);
    buffer.writeln('                        SALES REPORT');
    buffer.writeln('                       $_appName');
    buffer.writeln('=' * 70);
    buffer.writeln();

    // Report period
    String period = reportData['period'] ?? 'All Time';
    buffer.writeln('Report Period: $period');
    buffer.writeln(
        'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln();

    // Summary statistics
    buffer.writeln('SUMMARY:');
    buffer.writeln('-' * 30);
    buffer.writeln(
        'Total Sales: \$${(reportData['totalSales'] ?? 0.0).toStringAsFixed(2)}');
    buffer.writeln('Total Orders: ${reportData['totalOrders'] ?? 0}');
    buffer.writeln(
        'Average Order Value: \$${(reportData['averageOrderValue'] ?? 0.0).toStringAsFixed(2)}');
    buffer.writeln();

    // Sales breakdown
    if (reportData['salesByCategory'] != null) {
      buffer.writeln('SALES BY CATEGORY:');
      buffer.writeln('-' * 40);
      Map<String, dynamic> salesByCategory = reportData['salesByCategory'];
      salesByCategory.forEach((category, amount) {
        buffer.writeln(
            '${category.padRight(25)} \$${amount.toStringAsFixed(2).padLeft(10)}');
      });
      buffer.writeln();
    }

    // Top products
    if (reportData['topProducts'] != null) {
      buffer.writeln('TOP SELLING PRODUCTS:');
      buffer.writeln('-' * 50);
      buffer.writeln('Product                      Qty Sold    Revenue');
      buffer.writeln('-' * 50);

      List<dynamic> topProducts = reportData['topProducts'];
      for (var product in topProducts.take(10)) {
        String name = (product['name'] ?? 'Unknown').toString();
        if (name.length > 25) name = '${name.substring(0, 22)}...';

        int qtySold = product['quantitySold'] ?? 0;
        double revenue = (product['revenue'] ?? 0.0).toDouble();

        buffer.writeln('${name.padRight(25)} ${qtySold.toString().padLeft(8)} '
            '\$${revenue.toStringAsFixed(2).padLeft(10)}');
      }
      buffer.writeln();
    }

    // Monthly breakdown
    if (reportData['monthlyData'] != null) {
      buffer.writeln('MONTHLY BREAKDOWN:');
      buffer.writeln('-' * 30);
      Map<String, dynamic> monthlyData = reportData['monthlyData'];
      monthlyData.forEach((month, data) {
        buffer.writeln(
            '$month: \$${data['sales'].toStringAsFixed(2)} (${data['orders']} orders)');
      });
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate inventory report text
  static String generateInventoryReportText(
      List<Map<String, dynamic>> products) {
    final StringBuffer buffer = StringBuffer();

    // Header
    buffer.writeln('=' * 80);
    buffer.writeln('                            INVENTORY REPORT');
    buffer.writeln('                           $_appName');
    buffer.writeln('=' * 80);
    buffer.writeln();

    buffer.writeln(
        'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Total Products: ${products.length}');
    buffer.writeln();

    // Calculate totals
    double totalValue = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;

    for (var product in products) {
      int qty = product['quantity'] ?? 0;
      double price = (product['price'] ?? 0.0).toDouble();
      totalValue += qty * price;

      if (qty == 0) {
        outOfStockCount++;
      } else if (qty < 10) lowStockCount++;
    }

    buffer.writeln('SUMMARY:');
    buffer.writeln('-' * 40);
    buffer.writeln('Total Inventory Value: \$${totalValue.toStringAsFixed(2)}');
    buffer.writeln('Out of Stock Items: $outOfStockCount');
    buffer.writeln('Low Stock Items (< 10): $lowStockCount');
    buffer.writeln();

    // Product list
    buffer.writeln('PRODUCT INVENTORY:');
    buffer.writeln('-' * 80);
    buffer.writeln(
        'Product Name                  Category        Qty    Price     Value');
    buffer.writeln('-' * 80);

    for (var product in products) {
      String name = (product['name'] ?? 'Unknown').toString();
      if (name.length > 25) name = '${name.substring(0, 22)}...';

      String category = (product['category'] ?? 'Other').toString();
      if (category.length > 12) category = '${category.substring(0, 9)}...';

      int qty = product['quantity'] ?? 0;
      double price = (product['price'] ?? 0.0).toDouble();
      double value = qty * price;

      // Add warning indicators
      String qtyStr = qty.toString();
      if (qty == 0) {
        qtyStr += ' (OUT)';
      } else if (qty < 10) qtyStr += ' (LOW)';

      buffer.writeln('${name.padRight(25)} ${category.padRight(12)} '
          '${qtyStr.padLeft(8)} \$${price.toStringAsFixed(2).padLeft(8)} '
          '\$${value.toStringAsFixed(2).padLeft(8)}');
    }

    buffer.writeln('-' * 80);
    buffer
        .writeln('Total Value: \$${totalValue.toStringAsFixed(2)}'.padLeft(75));
    buffer.writeln();

    return buffer.toString();
  }

  /// Save text content to a file in the downloads directory
  static Future<String> saveTextToFile(String content, String fileName) async {
    try {
      Directory? downloadsDir;

      if (Platform.isWindows) {
        downloadsDir =
            Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      } else if (Platform.isLinux) {
        downloadsDir = Directory('${Platform.environment['HOME']}/Downloads');
      } else if (Platform.isMacOS) {
        downloadsDir = Directory('${Platform.environment['HOME']}/Downloads');
      } else {
        // Fallback to documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!downloadsDir.existsSync()) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Ensure unique filename
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String finalFileName = '${fileName}_$timestamp.txt';

      File file = File('${downloadsDir.path}/$finalFileName');
      await file.writeAsString(content);

      return file.path;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  /// Create a simple HTML version of the invoice for better formatting
  static String generateInvoiceHTML(Map<String, dynamic> invoice) {
    final StringBuffer html = StringBuffer();

    html.write('''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoice ${invoice['id'] ?? 'N/A'}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f8f9fa;
            padding: 20px;
        }
        
        .invoice-container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        .company-name {
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .company-subtitle {
            font-size: 1.2em;
            opacity: 0.9;
            margin-bottom: 5px;
        }
        
        .company-contact {
            font-size: 0.9em;
            opacity: 0.8;
        }
        
        .invoice-title {
            font-size: 1.8em;
            font-weight: bold;
            margin-top: 20px;
            letter-spacing: 2px;
        }
        
        .content {
            padding: 40px;
        }
        
        .invoice-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 40px;
        }
        
        .info-section {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .info-section h3 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.1em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .info-section p {
            margin: 8px 0;
            color: #555;
        }
        
        .info-section strong {
            color: #333;
            font-weight: 600;
        }
        
        .section-title {
            font-size: 1.3em;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #667eea;
        }
        
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
        
        .items-table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .items-table th {
            padding: 15px 12px;
            text-align: left;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-size: 0.9em;
        }
        
        .items-table td {
            padding: 15px 12px;
            border-bottom: 1px solid #eee;
        }
        
        .items-table tbody tr:hover {
            background-color: #f8f9fa;
        }
        
        .items-table tbody tr:last-child td {
            border-bottom: none;
        }
        
        .totals {
            background: #f8f9fa;
            padding: 30px;
            border-radius: 8px;
            border: 1px solid #e9ecef;
        }
        
        .total-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #e9ecef;
        }
        
        .total-row:last-child {
            border-bottom: none;
        }
        
        .grand-total {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white !important;
            padding: 15px 20px;
            border-radius: 8px;
            margin-top: 15px;
            font-size: 1.2em;
            font-weight: bold;
        }
        
        .footer {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 30px;
        }
        
        .thank-you {
            font-size: 1.5em;
            font-weight: bold;
            margin-bottom: 15px;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .invoice-container {
                box-shadow: none;
                border-radius: 0;
            }
        }
    </style>
</head>
<body>
    <div class="invoice-container">
        <div class="header">
            <div class="company-name">HEALSEARCH</div>
            <div class="company-subtitle">Digital Inventory System</div>
            <div class="company-contact">
                📧 info@healsearch.com | 📞 +1 (555) 123-4567 | 🌐 www.healsearch.com
            </div>
            <div class="invoice-title">📄 INVOICE</div>
        </div>
        
        <div class="content">
            <div class="invoice-info">
                <div class="info-section">
                    <h3>📋 Invoice Details</h3>
                    <p><strong>Invoice ID:</strong> ${invoice['id'] ?? 'N/A'}</p>
                    <p><strong>Date:</strong> ${DateFormat('MMMM dd, yyyy - hh:mm a').format(invoice['date'] ?? DateTime.now())}</p>
                    <p><strong>Status:</strong> <span style="color: #28a745; font-weight: bold;">${invoice['status'] ?? 'Completed'}</span></p>
                    <p><strong>Payment Method:</strong> ${invoice['paymentMethod'] ?? 'Cash'}</p>
                </div>
                
                <div class="info-section">
                    <h3>👤 Bill To</h3>
                    <p><strong>Customer:</strong> ${invoice['customerName'] ?? 'Walk-in Customer'}</p>''');

    if (invoice['customerPhone'] != null &&
        invoice['customerPhone'].toString().isNotEmpty) {
      html.write(
          '''                    <p><strong>Phone:</strong> ${invoice['customerPhone']}</p>''');
    } else {
      html.write(
          '''                    <p><strong>Phone:</strong> Not provided</p>''');
    }

    html.write('''
                    <p><strong>Email:</strong> Not provided</p>
                </div>
            </div>
            
            <h3 class="section-title">🛒 Items & Services</h3>
            <table class="items-table">
                <thead>
                    <tr>
                        <th style="width: 50%;">Item Description</th>
                        <th style="width: 15%; text-align: center;">Quantity</th>
                        <th style="width: 15%; text-align: right;">Unit Price</th>
                        <th style="width: 20%; text-align: right;">Total</th>
                    </tr>
                </thead>
                <tbody>''');

    if (invoice['items'] != null) {
      for (var item in invoice['items']) {
        int qty = item['quantity'] ?? 0;
        double price = (item['price'] ?? 0.0).toDouble();
        double total = price * qty;

        html.write('''
                    <tr>
                        <td>${item['name'] ?? 'Unknown'}</td>
                        <td style="text-align: center;">$qty</td>
                        <td style="text-align: right;">\$${price.toStringAsFixed(2)}</td>
                        <td style="text-align: right; font-weight: bold;">\$${total.toStringAsFixed(2)}</td>
                    </tr>''');
      }
    }

    double subtotal = (invoice['subtotal'] ?? 0.0).toDouble();
    double tax = (invoice['tax'] ?? 0.0).toDouble();
    double discount = (invoice['discount'] ?? 0.0).toDouble();
    double total = (invoice['total'] ?? 0.0).toDouble();

    html.write('''
                </tbody>
            </table>
            
            <div class="totals">
                <h4 style="color: #667eea; margin-bottom: 20px;">💰 Payment Summary</h4>
                <div class="total-row">
                    <span>Subtotal:</span>
                    <span>\$${subtotal.toStringAsFixed(2)}</span>
                </div>''');

    if (discount > 0) {
      html.write('''
                <div class="total-row">
                    <span>Discount:</span>
                    <span style="color: #dc3545;">-\$${discount.toStringAsFixed(2)}</span>
                </div>''');
    }

    html.write('''
                <div class="total-row">
                    <span>Tax (10%):</span>
                    <span>\$${tax.toStringAsFixed(2)}</span>
                </div>
                
                <div class="total-row grand-total">
                    <span>💵 TOTAL AMOUNT DUE:</span>
                    <span>\$${total.toStringAsFixed(2)}</span>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <div class="thank-you">🙏 Thank You for Your Business! 🙏</div>
            <p>Your trust and loyalty mean everything to us</p>
            <p>Generated by HealSearch Digital Inventory System</p>
            <p style="margin-top: 20px; font-size: 0.9em;">
                Generated on ${DateFormat('EEEE, MMMM dd, yyyy @ hh:mm a').format(DateTime.now())}
            </p>
        </div>
    </div>
</body>
</html>''');

    return html.toString();
  }

  /// Save HTML content to file
  static Future<String> saveHTMLToFile(
      String htmlContent, String fileName) async {
    try {
      Directory? downloadsDir;

      if (Platform.isWindows) {
        downloadsDir =
            Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      } else if (Platform.isLinux) {
        downloadsDir = Directory('${Platform.environment['HOME']}/Downloads');
      } else if (Platform.isMacOS) {
        downloadsDir = Directory('${Platform.environment['HOME']}/Downloads');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!downloadsDir.existsSync()) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String finalFileName = '${fileName}_$timestamp.html';

      File file = File('${downloadsDir.path}/$finalFileName');
      await file.writeAsString(htmlContent);

      return file.path;
    } catch (e) {
      throw Exception('Failed to save HTML file: $e');
    }
  }
}
