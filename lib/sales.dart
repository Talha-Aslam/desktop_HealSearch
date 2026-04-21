import 'package:desktop_search_a_holic/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:intl/intl.dart';

class Sales extends StatefulWidget {
  const Sales({super.key});

  @override
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  List<Map<String, dynamic>> sales = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final localSales = await appDb.select(appDb.sales).get();
      List<Map<String, dynamic>> loadedSales = localSales.map((s) {
        return {
          'id': s.id.toString(),
          'total': s.totalAmount,
          'date': DateFormat('yyyy-MM-dd HH:mm').format(s.createdAt),
          'customerName': 'Customer', // No customer data in local MVP schema
          'isSynced': s.isSyncedToCloud,
          'items': [], // No line-items tracked locally in MVP schema
        };
      }).toList();

      // Sort by newest first
      loadedSales.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        sales = loadedSales;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sales from local DB: $e');
      setState(() {
        _isLoading = false;
        _loadDummySalesData();
      });
    }
  }

  void _loadDummySalesData() {
    // Dummy data for recent orders
    var dummySalesData = [
      {
        "customerName": "John Smith",
        "customerPhone": "123-456-7890",
        "date": "2023-01-01",
        "total": 100.0,
        "id": "1",
        "items": [
          {"name": "Paracetamol 500mg", "quantity": 2, "price": 50.0}
        ]
      },
      {
        "customerName": "Jane Doe",
        "customerPhone": "987-654-3210",
        "date": "2023-01-02",
        "total": 200.0,
        "id": "2",
        "items": [
          {"name": "Aspirin 300mg", "quantity": 1, "price": 200.0}
        ]
      },
      {
        "customerName": "Walk-in Customer",
        "customerPhone": "555-555-5555",
        "date": "2023-01-03",
        "total": 150.0,
        "id": "3",
        "items": [
          {"name": "Cough Syrup", "quantity": 1, "price": 85.0},
          {"name": "Vitamins C", "quantity": 1, "price": 65.0}
        ]
      },
    ];

    setState(() {
      sales = dummySalesData;
    });
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
          'Sales History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSalesData,
            tooltip: 'Refresh Sales',
          ),
          IconButton(
            icon: const Icon(Icons.point_of_sale, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/pos'),
            tooltip: 'Go to POS',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: themeProvider.scaffoldBackgroundColor,
              ),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: themeProvider.gradientColors[0],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Sales',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.textColor,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/pos'),
                                icon: const Icon(Icons.add),
                                label: const Text('New Sale'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      themeProvider.gradientColors[0],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: sales.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 72,
                                        color: themeProvider.textColor
                                            .withOpacity(0.2),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No sales records found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: themeProvider.textColor
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () => Navigator.pushNamed(
                                            context, '/pos'),
                                        icon: const Icon(Icons.point_of_sale),
                                        label: const Text('Go to POS'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              themeProvider.gradientColors[0],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: sales.length,
                                  itemBuilder: (context, index) {
                                    final sale = sales[index];
                                    DateTime saleDate;
                                    try {
                                      saleDate = DateTime.parse(sale['date']);
                                    } catch (e) {
                                      // If the format is already "yyyy-MM-dd HH:mm" it might throw parse error in some locales, try alternate parsing
                                      try {
                                        saleDate =
                                            DateFormat('yyyy-MM-dd HH:mm')
                                                .parse(sale['date']);
                                      } catch (e2) {
                                        saleDate = DateTime.now();
                                      }
                                    }
                                    String formattedDate =
                                        DateFormat('MMM dd, yyyy - HH:mm')
                                            .format(saleDate);

                                    List<dynamic> items = sale['items'] ?? [];
                                    int itemCount = items.length;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      color: themeProvider.cardBackgroundColor,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.all(16),
                                        childrenPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor: themeProvider
                                              .gradientColors[0]
                                              .withOpacity(0.2),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: themeProvider
                                                  .gradientColors[0],
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          'Sale #${sale['id']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider.textColor,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'Customer: ${sale['customerName'] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    color: themeProvider
                                                        .textColor
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (sale['isSynced'] == true)
                                                  const Icon(Icons.cloud_done,
                                                      size: 14,
                                                      color: Colors.green)
                                                else
                                                  const Icon(Icons.cloud_off,
                                                      size: 14,
                                                      color: Colors.orange),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: themeProvider.textColor
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\$${sale['total']?.toStringAsFixed(2) ?? '0.00'}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: themeProvider
                                                    .gradientColors[0],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: themeProvider.textColor
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          const Divider(),
                                          ...List.generate(items.length,
                                              (itemIndex) {
                                            final item = items[itemIndex];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '${item['quantity']} × ',
                                                    style: TextStyle(
                                                      color: themeProvider
                                                          .textColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      item['name'],
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: themeProvider
                                                          .textColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          const Divider(),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Total:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        themeProvider.textColor,
                                                  ),
                                                ),
                                                Text(
                                                  '\$${sale['total']?.toStringAsFixed(2) ?? '0.00'}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: themeProvider
                                                        .gradientColors[0],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
