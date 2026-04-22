import 'dart:async';

import 'package:desktop_search_a_holic/main.dart';
import 'package:desktop_search_a_holic/data/database.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:desktop_search_a_holic/stock_alerts_widget.dart';
import 'package:desktop_search_a_holic/tenant_provider.dart';
import 'package:drift/drift.dart' as drift;

class Product extends StatefulWidget {
  const Product({super.key});

  @override
  _ProductState createState() => _ProductState();
}

class _ProductState extends State<Product> {
  List<Map<String, dynamic>> products = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> filteredProducts = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 120;
  int _offset = 0;
  String _activeSearch = '';
  String _activeCategory = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProductsFromFirestore(reset: true);
  }

  Future<void> _loadProductsFromFirestore({bool reset = false}) async {
    try {
      if (!mounted) return;

      if (reset) {
        setState(() {
          _isLoading = true;
          _hasMore = true;
          _offset = 0;
        });
      } else {
        if (_isFetchingMore || !_hasMore) return;
        setState(() {
          _isFetchingMore = true;
        });
      }

      print('🔄 Loading products from local DB...');
      final pharmacyId =
          Provider.of<TenantProvider>(context, listen: false).pharmacyId;

      if (pharmacyId == null) {
        throw Exception('No active pharmacy session');
      }

      final query = appDb.select(appDb.medicines)
        ..where((t) => t.pharmacyId.equals(pharmacyId));

      if (_activeSearch.trim().isNotEmpty) {
        query.where((t) => t.name.like('%${_activeSearch.trim()}%'));
      }

      if (_activeCategory != 'All') {
        query.where((t) => t.category.equals(_activeCategory));
      }

      final localMedicines = await (query
            ..orderBy([
              (t) => drift.OrderingTerm(
                    expression: t.id,
                    mode: drift.OrderingMode.desc,
                  )
            ])
            ..limit(_pageSize, offset: _offset))
          .get();

      if (!mounted) return;

      final loadedProducts = localMedicines.map((m) {
        return {
          'id': m.id.toString(),
          'pharmacyId': m.pharmacyId,
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
        if (reset) {
          products = loadedProducts;
        } else {
          products.addAll(loadedProducts);
        }
        filteredProducts = products;
        _offset += loadedProducts.length;
        _hasMore = loadedProducts.length == _pageSize;
        _isLoading = false;
        _isFetchingMore = false;
      });

      print('Products state updated - total: ${products.length}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      _activeSearch = query;
      _loadProductsFromFirestore(reset: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isFetchingMore) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold && _hasMore) {
      _loadProductsFromFirestore(reset: false);
    }
  }

  Future<void> _refreshProducts() async {
    if (!mounted) return; // Check mounted before refresh
    print('_refreshProducts called - starting refresh...');

    try {
      setState(() {
        _isLoading = true;
      });

      await _loadProductsFromFirestore(reset: true);
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
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: filteredProducts.length +
                                      (_isFetchingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= filteredProducts.length) {
                                      return const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
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
                          _activeCategory = 'All';
                        } else {
                          _activeCategory = selectedCategory;
                        }
                      });
                      _loadProductsFromFirestore(reset: true);
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
                  final productId = int.tryParse(product['id'].toString());
                  if (productId == null) {
                    throw Exception('Invalid product ID');
                  }

                  final pharmacyId =
                      Provider.of<TenantProvider>(context, listen: false)
                          .pharmacyId;
                  if (pharmacyId == null) {
                    throw Exception('No active pharmacy session');
                  }

                  final deleted = await (appDb.delete(appDb.medicines)
                        ..where((t) => t.id.equals(productId))
                        ..where((t) => t.pharmacyId.equals(pharmacyId)))
                      .go();

                  if (deleted == 0) {
                    throw Exception('Product not found');
                  }

                  if (!mounted) return; // Check mounted after async operation

                  // Update local state
                  setState(() {
                    products.removeWhere((p) => p['id'] == product['id']);
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
