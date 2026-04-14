import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Get recent invoices (from sales data)
  Future<List<Map<String, dynamic>>> getRecentInvoices({int limit = 10}) async {
    try {
      if (_auth.currentUser == null || _auth.currentUser!.email == null) {
        throw Exception('User not logged in');
      }

      // Query without orderBy to avoid composite index requirement
      // We'll sort the results in memory instead
      QuerySnapshot salesSnapshot = await _firestore
          .collection('sales')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      List<Map<String, dynamic>> invoices = [];

      for (var doc in salesSnapshot.docs) {
        Map<String, dynamic> saleData = doc.data() as Map<String, dynamic>;

        // Convert sale to invoice format
        Map<String, dynamic> invoice = {
          'id': doc.id,
          'invoiceNumber': 'INV-${doc.id.substring(0, 8).toUpperCase()}',
          'customerName': saleData['customerName'] ?? 'Walk-in Customer',
          'customerPhone': saleData['customerPhone'] ?? 'N/A',
          'date': saleData['createdAt'] != null
              ? (saleData['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          'items': saleData['items'] ?? [],
          'subtotal': saleData['subtotal']?.toDouble() ?? 0.0,
          'tax': saleData['tax']?.toDouble() ?? 0.0,
          'discount': saleData['discount']?.toDouble() ?? 0.0,
          'total': saleData['total']?.toDouble() ?? 0.0,
          'status': 'PAID', // Assume all sales are paid
          'paymentMethod': saleData['paymentMethod'] ?? 'Cash',
        };

        invoices.add(invoice);
      }

      // Sort by date in memory (most recent first)
      invoices.sort((a, b) => b['date'].compareTo(a['date']));

      // Apply limit after sorting
      if (limit > 0 && invoices.length > limit) {
        invoices = invoices.sublist(0, limit);
      }

      return invoices;
    } catch (e) {
      rethrow;
    }
  }

  // Get a specific invoice by sale ID
  Future<Map<String, dynamic>?> getInvoiceById(String saleId) async {
    try {
      if (_auth.currentUser == null || _auth.currentUser!.email == null) {
        throw Exception('User not logged in');
      }

      DocumentSnapshot doc =
          await _firestore.collection('sales').doc(saleId).get();

      if (!doc.exists) {
        return null;
      }

      Map<String, dynamic> saleData = doc.data() as Map<String, dynamic>;

      // Check if this sale belongs to current user
      if (saleData['userEmail'] != _auth.currentUser!.email) {
        throw Exception('Access denied');
      }

      return {
        'id': doc.id,
        'invoiceNumber': 'INV-${doc.id.substring(0, 8).toUpperCase()}',
        'customerName': saleData['customerName'] ?? 'Walk-in Customer',
        'customerPhone': saleData['customerPhone'] ?? 'N/A',
        'date': saleData['createdAt'] != null
            ? (saleData['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        'items': saleData['items'] ?? [],
        'subtotal': saleData['subtotal']?.toDouble() ?? 0.0,
        'tax': saleData['tax']?.toDouble() ?? 0.0,
        'discount': saleData['discount']?.toDouble() ?? 0.0,
        'total': saleData['total']?.toDouble() ?? 0.0,
        'status': 'PAID',
        'paymentMethod': saleData['paymentMethod'] ?? 'Cash',
      };
    } catch (e) {
      rethrow;
    }
  }

  // Generate professional invoice text for printing/sharing
  String generateInvoiceText(Map<String, dynamic> invoice) {
    StringBuffer buffer = StringBuffer();

    // Professional Header with company info
    buffer.writeln(
        '╔══════════════════════════════════════════════════════════════╗');
    buffer.writeln(
        '║                        HEALSEARCH                           ║');
    buffer.writeln(
        '║                   Digital Inventory System                  ║');
    buffer.writeln(
        '║               📧 info@healsearch.com                        ║');
    buffer.writeln(
        '║               📞 +1 (555) 123-4567                         ║');
    buffer.writeln(
        '║               🌐 www.healsearch.com                         ║');
    buffer.writeln(
        '╚══════════════════════════════════════════════════════════════╝');
    buffer.writeln();

    // Invoice Title and Number
    buffer.writeln('                           📄 INVOICE');
    buffer.writeln(
        '══════════════════════════════════════════════════════════════');
    buffer.writeln();

    // Invoice and Customer Details in two columns
    buffer.writeln(
        '┌─ INVOICE DETAILS ─────────────────┬─ CUSTOMER DETAILS ──────────────┐');

    String invoiceNum = 'Invoice #: ${invoice['invoiceNumber']}';
    String customerName = 'Customer: ${invoice['customerName']}';
    buffer.writeln(
        '│ ${invoiceNum.padRight(34)} │ ${customerName.padRight(32)} │');

    String invoiceDate =
        'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(invoice['date'])}';
    String customerPhone = invoice['customerPhone'] != 'N/A'
        ? 'Phone: ${invoice['customerPhone']}'
        : 'Phone: Not provided';
    buffer.writeln(
        '│ ${invoiceDate.padRight(34)} │ ${customerPhone.padRight(32)} │');

    String invoiceStatus = 'Status: ${invoice['status']}';
    String paymentMethod = 'Payment: ${invoice['paymentMethod']}';
    buffer.writeln(
        '│ ${invoiceStatus.padRight(34)} │ ${paymentMethod.padRight(32)} │');

    buffer.writeln(
        '└───────────────────────────────────┴─────────────────────────────────┘');
    buffer.writeln();

    // Items Table Header
    buffer.writeln('                        📦 ITEMS PURCHASED');
    buffer.writeln(
        '══════════════════════════════════════════════════════════════');
    buffer.writeln(
        '┌──┬─────────────────────────┬─────┬──────────┬─────────────┐');
    buffer.writeln(
        '│#│ Item Name               │ Qty │ Price    │ Total       │');
    buffer.writeln(
        '├──┼─────────────────────────┼─────┼──────────┼─────────────┤');

    // Items
    List<dynamic> items = invoice['items'] as List<dynamic>;
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      String name = item['name']?.toString() ?? 'Unknown Item';
      int quantity = item['quantity']?.toInt() ?? 0;
      double price = item['price']?.toDouble() ?? 0.0;
      double total = quantity * price;

      // Truncate name if too long
      if (name.length > 23) {
        name = '${name.substring(0, 20)}...';
      }

      String itemNum = '${i + 1}'.padLeft(2);
      String itemName = name.padRight(23);
      String itemQty = quantity.toString().padLeft(3);
      String itemPrice = '\$${price.toStringAsFixed(2)}'.padLeft(8);
      String itemTotal = '\$${total.toStringAsFixed(2)}'.padLeft(11);

      buffer.writeln(
          '│$itemNum│ $itemName │ $itemQty │ $itemPrice │ $itemTotal │');
    }

    buffer.writeln(
        '└──┴─────────────────────────┴─────┴──────────┴─────────────┘');
    buffer.writeln();

    // Financial Summary
    buffer.writeln('                       💰 PAYMENT SUMMARY');
    buffer.writeln(
        '══════════════════════════════════════════════════════════════');

    // Create aligned totals section
    String subtotalLabel = 'Subtotal:';
    String subtotalValue = '\$${invoice['subtotal'].toStringAsFixed(2)}';
    buffer
        .writeln('${subtotalLabel.padRight(50)} ${subtotalValue.padLeft(10)}');

    if (invoice['discount'] > 0) {
      String discountLabel = 'Discount Applied:';
      String discountValue = '-\$${invoice['discount'].toStringAsFixed(2)}';
      buffer.writeln(
          '${discountLabel.padRight(50)} ${discountValue.padLeft(10)}');
    }

    if (invoice['tax'] > 0) {
      String taxLabel = 'Tax (10%):';
      String taxValue = '\$${invoice['tax'].toStringAsFixed(2)}';
      buffer.writeln('${taxLabel.padRight(50)} ${taxValue.padLeft(10)}');
    }

    buffer.writeln(
        '──────────────────────────────────────────────────────────────');
    String totalLabel = '💵 TOTAL AMOUNT DUE:';
    String totalValue = '\$${invoice['total'].toStringAsFixed(2)}';
    buffer.writeln('${totalLabel.padRight(50)} ${totalValue.padLeft(10)}');
    buffer.writeln(
        '══════════════════════════════════════════════════════════════');
    buffer.writeln();

    // Terms and Footer
    buffer.writeln(
        '┌─ TERMS & CONDITIONS ──────────────────────────────────────────┐');
    buffer.writeln(
        '│ • All sales are final                                        │');
    buffer.writeln(
        '│ • Returns accepted within 30 days with receipt               │');
    buffer.writeln(
        '│ • For support, contact: support@healsearch.com               │');
    buffer.writeln(
        '└───────────────────────────────────────────────────────────────┘');
    buffer.writeln();

    // Professional Footer
    buffer.writeln(
        '╔══════════════════════════════════════════════════════════════╗');
    buffer.writeln(
        '║              🙏 Thank you for your business! 🙏              ║');
    buffer.writeln(
        '║                                                              ║');
    buffer.writeln(
        '║      Generated by HealSearch Digital Inventory System         ║');
    buffer.writeln(
        '║    ${DateFormat('EEEE, MMMM dd, yyyy - hh:mm a').format(DateTime.now()).padLeft(58)} ║');
    buffer.writeln(
        '╚══════════════════════════════════════════════════════════════╝');

    return buffer.toString();
  }

  // Generate enhanced shareable invoice text with better formatting
  String generateShareableInvoiceText(Map<String, dynamic> invoice) {
    final StringBuffer buffer = StringBuffer();

    // Professional Header with branding
    buffer.writeln('🏪═══════════════════════════════════════════════🏪');
    buffer.writeln('                 HEALSEARCH                     ');
    buffer.writeln('            Digital Inventory System            ');
    buffer.writeln('        📧 info@healsearch.com                  ');
    buffer.writeln('        📞 +1 (555) 123-4567                    ');
    buffer.writeln('🏪═══════════════════════════════════════════════🏪');
    buffer.writeln();

    // Invoice Header
    buffer.writeln('                    📄 INVOICE                   ');
    buffer.writeln('═══════════════════════════════════════════════');
    buffer.writeln();

    // Invoice details in organized format
    buffer.writeln('📋 INVOICE INFORMATION');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('• Invoice No: ${invoice['invoiceNumber']}');
    buffer.writeln(
        '• Date & Time: ${DateFormat('EEEE, MMM dd, yyyy - hh:mm a').format(invoice['date'])}');
    buffer.writeln('• Status: ${invoice['status']} ✅');
    buffer.writeln('• Payment Method: ${invoice['paymentMethod']}');
    buffer.writeln();

    // Customer details with professional formatting
    buffer.writeln('👤 CUSTOMER INFORMATION');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('• Name: ${invoice['customerName']}');
    if (invoice['customerPhone'] != 'N/A') {
      buffer.writeln('• Phone: ${invoice['customerPhone']}');
    } else {
      buffer.writeln('• Phone: Not provided');
    }
    buffer.writeln();

    // Items with enhanced table format
    buffer.writeln('🛒 ITEMS PURCHASED');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    List<dynamic> items = invoice['items'] ?? [];

    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      double itemTotal = (item['quantity'] * item['price']).toDouble();

      buffer.writeln('${i + 1}. ${item['name']}');
      buffer.writeln('   ├─ Quantity: ${item['quantity']} units');
      buffer.writeln('   ├─ Unit Price: \$${item['price'].toStringAsFixed(2)}');
      buffer.writeln('   └─ Line Total: \$${itemTotal.toStringAsFixed(2)}');

      if (i < items.length - 1) {
        buffer.writeln('   ');
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();

    // Enhanced payment summary with visual elements
    buffer.writeln('💰 PAYMENT BREAKDOWN');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Create nice aligned format
    buffer.writeln(
        '├─ Subtotal                    \$${invoice['subtotal'].toStringAsFixed(2)}');

    if (invoice['discount'] > 0) {
      buffer.writeln(
          '├─ Discount Applied           -\$${invoice['discount'].toStringAsFixed(2)}');
    }

    if (invoice['tax'] > 0) {
      buffer.writeln(
          '├─ Tax (10%)                   \$${invoice['tax'].toStringAsFixed(2)}');
    }

    buffer.writeln('┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '└─ 💵 TOTAL AMOUNT            \$${invoice['total'].toStringAsFixed(2)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();

    // Additional information
    buffer.writeln('ℹ️  TRANSACTION DETAILS');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('• Total Items: ${items.length}');
    buffer.writeln(
        '• Total Quantity: ${items.fold(0, (sum, item) => sum + (item['quantity'] as int))}');
    buffer.writeln(
        '• Transaction ID: ${invoice['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}');
    buffer.writeln();

    // Professional footer with terms
    buffer.writeln('📜 TERMS & CONDITIONS');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('• All sales are final unless otherwise specified');
    buffer.writeln('• Returns accepted within 30 days with receipt');
    buffer.writeln('• For questions: support@healsearch.com');
    buffer.writeln();

    // Final footer with appreciation
    buffer.writeln('🏪═══════════════════════════════════════════════🏪');
    buffer.writeln('              🙏 THANK YOU! 🙏                ');
    buffer.writeln('                                               ');
    buffer.writeln('      Your business means the world to us!     ');
    buffer.writeln('                                               ');
    buffer.writeln('   Generated by HealSearch System              ');
    buffer.writeln(
        '   ${DateFormat('MMM dd, yyyy @ hh:mm a').format(DateTime.now())}                      ');
    buffer.writeln('🏪═══════════════════════════════════════════════🏪');

    return buffer.toString();
  }

  // Generate email-friendly invoice text
  String generateEmailInvoiceText(Map<String, dynamic> invoice) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('INVOICE - ${invoice['invoiceNumber']}');
    buffer.writeln('HealSearch Digital Inventory System');
    buffer.writeln('');
    buffer.writeln(
        'Date: ${DateFormat('MMMM dd, yyyy').format(invoice['date'])}');
    buffer.writeln('Customer: ${invoice['customerName']}');
    if (invoice['customerPhone'] != 'N/A') {
      buffer.writeln('Phone: ${invoice['customerPhone']}');
    }
    buffer.writeln('');
    buffer.writeln('ITEMS:');

    List<dynamic> items = invoice['items'] ?? [];
    for (var item in items) {
      buffer.writeln(
          '• ${item['name']} - Qty: ${item['quantity']} × \$${item['price'].toStringAsFixed(2)} = \$${(item['quantity'] * item['price']).toStringAsFixed(2)}');
    }

    buffer.writeln('');
    buffer.writeln('Subtotal: \$${invoice['subtotal'].toStringAsFixed(2)}');
    if (invoice['discount'] > 0) {
      buffer.writeln('Discount: -\$${invoice['discount'].toStringAsFixed(2)}');
    }
    if (invoice['tax'] > 0) {
      buffer.writeln('Tax: \$${invoice['tax'].toStringAsFixed(2)}');
    }
    buffer.writeln('TOTAL: \$${invoice['total'].toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Thank you for your business!');

    return buffer.toString();
  }

  // Get latest invoice for display
  Future<Map<String, dynamic>?> getLatestInvoice() async {
    try {
      List<Map<String, dynamic>> invoices = await getRecentInvoices(limit: 1);
      return invoices.isNotEmpty ? invoices.first : null;
    } catch (e) {
      rethrow;
    }
  }

  // Generate professional printable invoice text (monospace formatting)
  String generatePrintableInvoiceText(Map<String, dynamic> invoice) {
    final StringBuffer buffer = StringBuffer();

    // Professional Header with company details
    buffer.writeln(
        '================================================================');
    buffer.writeln(
        '                        HEALSEARCH                              ');
    buffer.writeln(
        '                   Digital Inventory System                    ');
    buffer.writeln(
        '         Email: info@healsearch.com | Phone: +1-555-123-4567   ');
    buffer.writeln(
        '                    www.healsearch.com                         ');
    buffer.writeln(
        '================================================================');
    buffer.writeln();

    // Invoice title
    buffer.writeln(
        '                            INVOICE                            ');
    buffer.writeln(
        '================================================================');
    buffer.writeln();

    // Invoice and customer details in organized sections
    buffer.writeln(
        'INVOICE DETAILS                    CUSTOMER INFORMATION        ');
    buffer.writeln(
        '--------------------------------   ------------------------------');

    String invoiceNum = 'Invoice #: ${invoice['invoiceNumber']}';
    String customerName = 'Customer: ${invoice['customerName']}';
    buffer.writeln('${invoiceNum.padRight(35)}$customerName');

    String invoiceDate =
        'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(invoice['date'])}';
    String customerPhone = invoice['customerPhone'] != 'N/A'
        ? 'Phone: ${invoice['customerPhone']}'
        : 'Phone: Not provided';
    buffer.writeln('${invoiceDate.padRight(35)}$customerPhone');

    String invoiceStatus = 'Status: ${invoice['status']}';
    String paymentMethod = 'Payment: ${invoice['paymentMethod']}';
    buffer.writeln('${invoiceStatus.padRight(35)}$paymentMethod');

    buffer.writeln();

    // Items table with professional formatting
    buffer.writeln('ITEMS PURCHASED:');
    buffer.writeln(
        '================================================================');
    buffer.writeln(
        'No. Item Name                Qty    Unit Price      Total      ');
    buffer.writeln(
        '----------------------------------------------------------------');

    List<dynamic> items = invoice['items'] ?? [];
    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      String itemNum = '${i + 1}.'.padRight(4);

      String name = item['name'].toString();
      if (name.length > 24) {
        name = '${name.substring(0, 21)}...';
      }
      name = name.padRight(24);

      String qty = item['quantity'].toString().padLeft(6);
      String price = '\$${item['price'].toStringAsFixed(2)}'.padLeft(11);
      String total =
          '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}'
              .padLeft(11);

      buffer.writeln('$itemNum$name $qty $price $total');
    }

    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln();

    // Payment summary with professional alignment
    buffer.writeln('PAYMENT SUMMARY:');
    buffer.writeln(
        '================================================================');

    String subtotalLabel = 'Subtotal:';
    String subtotalValue = '\$${invoice['subtotal'].toStringAsFixed(2)}';
    buffer.writeln('${subtotalLabel.padRight(50)}${subtotalValue.padLeft(14)}');

    if (invoice['discount'] > 0) {
      String discountLabel = 'Discount Applied:';
      String discountValue = '-\$${invoice['discount'].toStringAsFixed(2)}';
      buffer
          .writeln('${discountLabel.padRight(50)}${discountValue.padLeft(14)}');
    }

    if (invoice['tax'] > 0) {
      String taxLabel = 'Tax (10%):';
      String taxValue = '\$${invoice['tax'].toStringAsFixed(2)}';
      buffer.writeln('${taxLabel.padRight(50)}${taxValue.padLeft(14)}');
    }

    buffer.writeln(
        '----------------------------------------------------------------');
    String totalLabel = 'TOTAL AMOUNT DUE:';
    String finalTotal = '\$${invoice['total'].toStringAsFixed(2)}';
    buffer.writeln('${totalLabel.padRight(50)}${finalTotal.padLeft(14)}');
    buffer.writeln(
        '================================================================');
    buffer.writeln();

    // Transaction details
    buffer.writeln('TRANSACTION DETAILS:');
    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln(
        'Transaction ID: ${invoice['id']?.toString().substring(0, 12).toUpperCase() ?? 'N/A'}');
    buffer.writeln('Total Items: ${items.length}');
    buffer.writeln(
        'Total Quantity: ${items.fold(0, (sum, item) => sum + (item['quantity'] as int))}');
    buffer.writeln();

    // Terms and conditions
    buffer.writeln('TERMS & CONDITIONS:');
    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln('• All sales are final unless otherwise specified');
    buffer.writeln('• Returns accepted within 30 days with original receipt');
    buffer.writeln('• For support or inquiries: support@healsearch.com');
    buffer.writeln();

    // Professional footer
    buffer.writeln(
        '================================================================');
    buffer.writeln(
        '                Thank you for choosing HealSearch!            ');
    buffer.writeln(
        '                                                               ');
    buffer.writeln(
        '                Your satisfaction is our top priority            ');
    buffer.writeln(
        '                                                               ');
    buffer.writeln(
        'Generated: ${DateFormat('EEEE, MMMM dd, yyyy - hh:mm a').format(DateTime.now())}');
    buffer.writeln(
        '================================================================');

    return buffer.toString();
  }
}
