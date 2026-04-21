import 'package:desktop_search_a_holic/main.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:desktop_search_a_holic/firebase_service.dart';
import 'package:desktop_search_a_holic/stock_alerts_widget.dart';

class Product extends StatefulWidget {
  const Product({super.key});

  @override
  _ProductState createState() => _ProductState();
}

class _ProductState extends State<Product> {
  List<Map<String, dynamic>> products = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductsFromFirestore();
  }

  Future<void> _loadProductsFromFirestore() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      print('🔄 Loading products from local DB...');
      final localMedicines = await appDb.select(appDb.medicines).get();

      if (!mounted) return;

      List<Map<String, dynamic>> loadedProducts = localMedicines.map((m) {
        return {
          'id': m.id.toString(),
          'name': m.name,
          'price': m.price,
          'quantity': m.stock,
          'category': m.category ?? 'Other',
          'expiry': m.expiryDate != null
              ? DateFormat('yyyy-MM-dd').format(m.expiryDate!)
              : '',
        };
      }).toList();

      setState(() {
        products = loadedProducts;
        if (_searchController.text.isEmpty) {
          filteredProducts = loadedProducts;
        } else {
          _searchProducts(_searchController.text);
        }
        _isLoading = false;
      });

      print('Products state updated - total: ${products.length}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('❌ Error loading products from local DB: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = products;
      });
      return;
    }

    setState(() {
      filteredProducts = products
          .where((product) =>
              product['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _refreshProducts() async {
    if (!mounted) return; // Check mounted before refresh
    print('_refreshProducts called - starting refresh...');

    try {
      setState(() {
        _isLoading = true;
      });

      await _loadProductsFromFirestore();
      print('_refreshProducts completed successfully');
    } catch (e) {
      print('Error in _refreshProducts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              print('Navigating to add product page...');
              final result = await Navigator.pushNamed(context, '/addProduct');
              print('Returned from add product page with result: $result');
              // Refresh products when returning from add product page
              if (result == true && mounted) {
                print('Refreshing products after adding...');
                // Add a small delay to ensure Firebase has processed the addition
                await Future.delayed(const Duration(milliseconds: 100));
                await _refreshProducts();
                // Force a second refresh to ensure we get the latest data
                await Future.delayed(const Duration(milliseconds: 200));
                await _refreshProducts();
              }
            },
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
              child: Column(
                children: [
                  // Search and filter bar
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Search field
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _searchProducts,
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: TextStyle(
                                  color:
                                      themeProvider.textColor.withOpacity(0.6)),
                              prefixIcon: Icon(Icons.search,
                                  color: themeProvider.iconColor),
                              filled: true,
                              fillColor: themeProvider.cardBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filter button
                        Container(
                          decoration: BoxDecoration(
                            color: themeProvider.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Show filter options
                              _showFilterDialog(context);
                            },
                            icon: Icon(
                              Icons.filter_list,
                              color: themeProvider.iconColor,
                            ),
                            tooltip: 'Filter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Products list
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: themeProvider.gradientColors[0],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading products...',
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 64,
                                      color: themeProvider.textColor
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No products found',
                                      style: TextStyle(
                                        color: themeProvider.textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _loadProductsFromFirestore,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            themeProvider.gradientColors[0],
                                      ),
                                      child: const Text(
                                        'Refresh',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _refreshProducts,
                                color: themeProvider.gradientColors[0],
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return Card(
                                      margin:
                                          const EdgeInsets.only(bottom: 16.0),
                                      color: themeProvider.cardBackgroundColor,
                                      elevation: 3.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product['name'],
                                                    style: TextStyle(
                                                      color: themeProvider
                                                          .textColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '\$${product['price']}',
                                                  style: TextStyle(
                                                    color: themeProvider
                                                        .gradientColors[0],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildInfoChip(
                                                  context,
                                                  'Quantity: ${product['quantity']}',
                                                  Icons.inventory_2,
                                                ),
                                                const SizedBox(width: 8),
                                                StockStatusIndicator(
                                                  quantity:
                                                      (product['quantity'] ?? 0)
                                                          .toInt(),
                                                  showLabel: false,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildInfoChip(
                                                  context,
                                                  product['category'],
                                                  Icons.category,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  'Expiry: ${product['expiry']}',
                                                  style: TextStyle(
                                                    color: themeProvider
                                                        .textColor
                                                        .withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Action buttons
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color:
                                                        themeProvider.iconColor,
                                                  ),
                                                  onPressed: () async {
                                                    print(
                                                        'Edit button pressed for product: ${product['name']}');
                                                    final result =
                                                        await Navigator
                                                            .pushNamed(
                                                      context,
                                                      '/editProduct',
                                                      arguments: {
                                                        'productId':
                                                            product['id']
                                                      },
                                                    );
                                                    print(
                                                        'Edit - returned with result: $result');
                                                    // Refresh the product list when returning
                                                    if (mounted) {
                                                      print(
                                                          'Edit - refreshing products...');
                                                      await _refreshProducts();
                                                    }
                                                  },
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    _showDeleteConfirmation(
                                                        context, index);
                                                  },
                                                  tooltip: 'Delete',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print('FloatingActionButton pressed - navigating to add product...');
          final result = await Navigator.pushNamed(context, '/addProduct');
          print('FloatingActionButton - returned with result: $result');
          // Refresh products when returning from add product page
          if (result == true && mounted) {
            print('FloatingActionButton - refreshing products...');
            // Add a small delay to ensure Firebase has processed the addition
            await Future.delayed(const Duration(milliseconds: 100));
            await _refreshProducts();
            // Force a second refresh to ensure we get the latest data
            await Future.delayed(const Duration(milliseconds: 200));
            await _refreshProducts();
          }
        },
        backgroundColor: themeProvider.gradientColors[0],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? Colors.grey.shade800
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: themeProvider.gradientColors[0],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    // Category options
    List<String> categories = [
      'Medicine',
      'Supplements',
      'First Aid',
      'Hygiene',
      'All'
    ];
    String selectedCategory = 'All';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              backgroundColor: themeProvider.cardBackgroundColor,
              title: Text(
                'Filter Products',
                style: TextStyle(color: themeProvider.textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((category) {
                      return ChoiceChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedCategory = category;
                          });
                        },
                        backgroundColor: themeProvider.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        selectedColor: themeProvider.gradientColors[0],
                        labelStyle: TextStyle(
                          color: selectedCategory == category
                              ? Colors.white
                              : themeProvider.textColor,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: themeProvider.textColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Apply the filter
                    if (mounted) {
                      setState(() {
                        if (selectedCategory == 'All') {
                          filteredProducts = products;
                        } else {
                          filteredProducts = products
                              .where((product) =>
                                  product['category'] == selectedCategory)
                              .toList();
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.gradientColors[0],
                  ),
                  child: const Text('Apply',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final product = filteredProducts[index];
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture ScaffoldMessenger

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: themeProvider.cardBackgroundColor,
          title: Text(
            'Delete Product',
            style: TextStyle(color: themeProvider.textColor),
          ),
          content: Text(
            'Are you sure you want to delete ${product['name']}?',
            style: TextStyle(color: themeProvider.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.textColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog first

                try {
                  // Delete from Firestore if product has an ID
                  if (product['id'] != null) {
                    await _firebaseService.deleteProduct(product['id']);
                  }

                  if (!mounted) return; // Check mounted after async operation

                  // Update local state
                  setState(() {
                    products.removeWhere((p) => p['name'] == product['name']);
                    filteredProducts = List.from(products);
                  });

                  // Use captured ScaffoldMessenger instead of context
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${product['name']} deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Use captured ScaffoldMessenger instead of context
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to delete product: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
