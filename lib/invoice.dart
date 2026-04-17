import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/invoice_service.dart';
import 'package:desktop_search_a_holic/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class Invoice extends StatefulWidget {
  const Invoice({super.key});

  @override
  _InvoiceState createState() => _InvoiceState();
}

class _InvoiceState extends State<Invoice> with WidgetsBindingObserver {
  final InvoiceService _invoiceService = InvoiceService();
  List<Map<String, dynamic>> allInvoices = [];
  Map<String, dynamic>? currentInvoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllInvoices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh invoice when app comes to foreground
      _loadAllInvoices();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh invoice data when this page becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllInvoices();
      }
    });
  }

  Future<void> _loadAllInvoices() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Loading all invoices...');
      List<Map<String, dynamic>> invoices =
          await _invoiceService.getRecentInvoices(limit: 50);

      setState(() {
        allInvoices = invoices;
        if (allInvoices.isNotEmpty && currentInvoice == null) {
          // Default to latest
          currentInvoice = allInvoices.first;
        } else if (allInvoices.isEmpty) {
          currentInvoice = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading invoices: $e');
      setState(() {
        _isLoading = false;
        allInvoices = [];
        currentInvoice = null;
      });
    }
  }

  Future<void> _printInvoice() async {
    if (currentInvoice == null) return;

    try {
      // Show print options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Print & Export Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Choose how you want to print or export this invoice:'),
              const SizedBox(height: 16),

              // Preview option
              ListTile(
                leading: const Icon(Icons.preview, color: Colors.blue),
                title: const Text('Preview'),
                subtitle: const Text('View formatted invoice text'),
                onTap: () {
                  Navigator.pop(context);
                  _showInvoicePreview();
                },
              ),

              // PDF Text option
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Save as PDF-ready Text'),
                subtitle:
                    const Text('Save formatted text file for PDF conversion'),
                onTap: () {
                  Navigator.pop(context);
                  _savePDFReadyText();
                },
              ),

              // HTML option
              ListTile(
                leading: const Icon(Icons.web, color: Colors.green),
                title: const Text('Save as HTML'),
                subtitle: const Text('Save as HTML file for printing'),
                onTap: () {
                  Navigator.pop(context);
                  _saveAsHTML();
                },
              ),

              // Copy to clipboard option
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.orange),
                title: const Text('Copy to Clipboard'),
                subtitle: const Text('Copy text for pasting elsewhere'),
                onTap: () {
                  Navigator.pop(context);
                  _copyPrintableText();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print options failed: $e')),
      );
    }
  }

  Future<void> _showInvoicePreview() async {
    try {
      String invoiceText =
          _invoiceService.generatePrintableInvoiceText(currentInvoice!);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invoice Preview'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invoiceText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _copyPrintableText();
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview failed: $e')),
      );
    }
  }

  Future<void> _savePDFReadyText() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF-ready file...'),
            ],
          ),
        ),
      );

      // Generate PDF-formatted invoice text
      String pdfText = PdfService.generateInvoiceText(currentInvoice!);

      // Save to file
      String filePath = await PdfService.saveTextToFile(
          pdfText, 'invoice_${currentInvoice!['id'] ?? 'unknown'}');

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF-ready text saved to: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Copy Path',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: filePath));
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAsHTML() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating HTML file...'),
            ],
          ),
        ),
      );

      // Generate HTML invoice
      String htmlContent = PdfService.generateInvoiceHTML(currentInvoice!);

      // Save to file
      String filePath = await PdfService.saveHTMLToFile(
          htmlContent, 'invoice_${currentInvoice!['id'] ?? 'unknown'}');

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('HTML file saved to: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Copy Path',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: filePath));
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save HTML: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyPrintableText() async {
    try {
      final invoiceText =
          _invoiceService.generatePrintableInvoiceText(currentInvoice!);
      await Clipboard.setData(ClipboardData(text: invoiceText));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printable text copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareInvoice() async {
    if (currentInvoice == null) return;

    try {
      // For now, show share options in a dialog with actual functionality
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose sharing method:'),
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareViaEmail();
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Share via Email'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareViaWhatsApp();
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Share via WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _copyToClipboard();
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy to Clipboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareViaEmail() async {
    try {
      final invoiceText =
          _invoiceService.generateEmailInvoiceText(currentInvoice!);
      final subject =
          Uri.encodeComponent('Invoice ${currentInvoice!['invoiceNumber']}');
      final body = Uri.encodeComponent(invoiceText);

      final emailUrl = 'mailto:?subject=$subject&body=$body';

      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening email app...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Fallback: copy to clipboard
        await _copyToClipboard();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email share failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareViaWhatsApp() async {
    try {
      final invoiceText =
          _invoiceService.generateShareableInvoiceText(currentInvoice!);
      final encodedText = Uri.encodeComponent(invoiceText);

      final whatsappUrl = 'whatsapp://send?text=$encodedText';
      final whatsappWebUrl = 'https://wa.me/?text=$encodedText';

      // Try WhatsApp app first
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp...'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (await canLaunchUrl(Uri.parse(whatsappWebUrl))) {
        // Fallback to WhatsApp Web
        await launchUrl(Uri.parse(whatsappWebUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp Web...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Fallback: copy to clipboard
        await _copyToClipboard();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp share failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    try {
      final invoiceText =
          _invoiceService.generateShareableInvoiceText(currentInvoice!);
      await Clipboard.setData(ClipboardData(text: invoiceText));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Invoice',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {
              if (currentInvoice != null) {
                _printInvoice();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No invoice data available')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              if (currentInvoice != null) {
                _shareInvoice();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No invoice data available')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllInvoices,
            tooltip: 'Load Latest Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.white),
            onPressed: () async {
              // Force refresh with debug information
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking for new invoices...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await _loadAllInvoices();
            },
            tooltip: 'Check for New Invoices',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: themeProvider.scaffoldBackgroundColor,
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.gradientColors[0],
                ),
              )
            : allInvoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 64,
                          color: themeProvider.textColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Invoice Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: themeProvider.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a sale in POS to generate an invoice',
                          style: TextStyle(
                            color: themeProvider.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/pos'),
                          icon: const Icon(Icons.point_of_sale),
                          label: const Text('Go to POS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.gradientColors[0],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      // Sidebar List
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: themeProvider.textColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: allInvoices.length,
                          itemBuilder: (context, index) {
                            var inv = allInvoices[index];
                            bool isSelected = currentInvoice != null &&
                                inv['id'] == currentInvoice!['id'];

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: themeProvider.gradientColors[0]
                                  .withOpacity(0.1),
                              title: Text(
                                'INV-${inv['id'].toString().substring(0, 8).toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: themeProvider.textColor,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM dd, yy').format(inv['date'])} - \$${inv['total'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color:
                                      themeProvider.textColor.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  currentInvoice = inv;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      // Main Content
                      Expanded(
                        child: currentInvoice == null
                            ? Center(
                                child: Text(
                                  'Select an invoice to preview',
                                  style: TextStyle(
                                      color: themeProvider.textColor
                                          .withOpacity(0.5)),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Invoice header with summary information
                                    Container(
                                      padding: const EdgeInsets.all(16.0),
                                      margin: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            themeProvider.gradientColors[0]
                                                .withOpacity(0.1),
                                            themeProvider.gradientColors[1]
                                                .withOpacity(0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: themeProvider.gradientColors[0]
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.receipt,
                                                color: themeProvider
                                                    .gradientColors[0],
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Invoice #${currentInvoice!['invoiceNumber']}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      themeProvider.textColor,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                DateFormat('MMM dd, yyyy')
                                                    .format(currentInvoice![
                                                        'date']),
                                                style: TextStyle(
                                                  color: themeProvider.textColor
                                                      .withOpacity(0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Customer:',
                                                    style: TextStyle(
                                                      color: themeProvider
                                                          .textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    currentInvoice![
                                                        'customerName'],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themeProvider
                                                          .textColor,
                                                    ),
                                                  ),
                                                  if (currentInvoice![
                                                          'customerPhone'] !=
                                                      'N/A') ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      currentInvoice![
                                                          'customerPhone'],
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor
                                                            .withOpacity(0.7),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Status:',
                                                    style: TextStyle(
                                                      color: themeProvider
                                                          .textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      currentInvoice!['status'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Invoice items
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      decoration: BoxDecoration(
                                        color:
                                            themeProvider.cardBackgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          // Column headers
                                          Container(
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              color: themeProvider
                                                  .gradientColors[0]
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(12),
                                                topRight: Radius.circular(12),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    'Item',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themeProvider
                                                          .textColor,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Qty',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themeProvider
                                                          .textColor,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Price',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themeProvider
                                                          .textColor,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    'Total',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themeProvider
                                                          .textColor,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Invoice items
                                          ...((currentInvoice!['items'] as List)
                                              .map((item) {
                                            final quantity =
                                                item['quantity']?.toInt() ?? 0;
                                            final price =
                                                item['price']?.toDouble() ??
                                                    0.0;
                                            final total = quantity * price;

                                            return Container(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: themeProvider
                                                        .textColor
                                                        .withOpacity(0.1),
                                                    width: 0.5,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      item['name']
                                                              ?.toString() ??
                                                          'Unknown Item',
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      quantity.toString(),
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor,
                                                        fontSize: 14,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      '\$${price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor,
                                                        fontSize: 14,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      '\$${total.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList()),
                                        ],
                                      ),
                                    ),

                                    // Invoice summary with totals
                                    Container(
                                      padding: const EdgeInsets.all(16.0),
                                      margin: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color:
                                            themeProvider.cardBackgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          _buildSummaryRow(
                                            themeProvider,
                                            'Subtotal',
                                            currentInvoice!['subtotal']
                                                .toStringAsFixed(2),
                                          ),
                                          if (currentInvoice!['discount'] > 0)
                                            _buildSummaryRow(
                                              themeProvider,
                                              'Discount',
                                              currentInvoice!['discount']
                                                  .toStringAsFixed(2),
                                              isDiscount: true,
                                            ),
                                          if (currentInvoice!['tax'] > 0)
                                            _buildSummaryRow(
                                              themeProvider,
                                              'Tax',
                                              currentInvoice!['tax']
                                                  .toStringAsFixed(2),
                                            ),
                                          const Divider(),
                                          _buildSummaryRow(
                                            themeProvider,
                                            'Total',
                                            currentInvoice!['total']
                                                .toStringAsFixed(2),
                                            isTotal: true,
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Text(
                                                'Payment Method: ',
                                                style: TextStyle(
                                                  color: themeProvider.textColor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              Text(
                                                currentInvoice![
                                                    'paymentMethod'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      themeProvider.textColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeProvider themeProvider,
    String label,
    String amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}\$$amount',
            style: TextStyle(
              color: isDiscount ? Colors.red : themeProvider.textColor,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
