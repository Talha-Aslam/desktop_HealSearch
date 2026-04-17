import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';
import 'package:desktop_search_a_holic/firebase_service.dart';
import 'package:desktop_search_a_holic/sales_service.dart';
import 'package:desktop_search_a_holic/invoice_service.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class POS extends StatefulWidget {
  const POS({super.key});

  @override
  _POSState createState() => _POSState();
}

class _POSState extends State<POS> {
  final FirebaseService _firebaseService = FirebaseService();
  final SalesService _salesService = SalesService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> cart = [];

  bool _isLoading = false;
  bool _advancedSearchVisible = false;
  bool _onlyInStock = false;
  double _subtotal = 0;
  double _discount = 0;
  double _tax = 0;
  double _total = 0;
  double _minPrice = 0;
  double _maxPrice = double.infinity;
  String _selectedCategory = 'All';
  String _sortBy = 'name_asc'; // Default sort by name ascending
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _discountController.text = '0';
  }

  void _extractCategories() {
    Set<String> categoriesSet = {'All'};
    for (var product in products) {
      if (product['category'] != null) {
        categoriesSet.add(product['category'].toString());
      }
    }
    setState(() {
      _categories = categoriesSet.toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double subtotal = 0;
    for (var item in cart) {
      subtotal += (item['price'] as num).toDouble() *
          (item['quantity'] as num).toDouble();
    }

    double discount = double.tryParse(_discountController.text) ?? 0;
    double tax = subtotal * 0.10; // 10% tax

    setState(() {
      _subtotal = subtotal;
      _discount = discount;
      _tax = tax;
      _total = subtotal + tax - discount;
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> loadedProducts =
          await _firebaseService.getProducts();

      setState(() {
        products = loadedProducts;
        filteredProducts = loadedProducts;
        _isLoading = false;
      });

      _extractCategories();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        // Load dummy data as fallback
        _loadDummyProducts();
      }
    }
  }

  void _loadDummyProducts() {
    // Get current user email for dummy data
    String? userEmail = _firebaseService.currentUser?.email;

    // Dummy data for products with more details
    var dummyProducts = [
      {
        "id": "1",
        "name": "Paracetamol 500mg",
        "price": 100,
        "quantity": 100,
        "category": "Medicine",
        "expiry": "2025-12-31",
        "userEmail": userEmail,
      },
      {
        "id": "2",
        "name": "Aspirin 300mg",
        "price": 200,
        "quantity": 50,
        "category": "Medicine",
        "expiry": "2026-05-15",
        "userEmail": userEmail,
      },
      {
        "id": "3",
        "name": "Vitamins C",
        "price": 150,
        "quantity": 200,
        "category": "Supplements",
        "expiry": "2027-08-22",
        "userEmail": userEmail,
      },
      {
        "id": "4",
        "name": "Cough Syrup",
        "price": 85,
        "quantity": 30,
        "category": "Medicine",
        "expiry": "2025-10-30",
        "userEmail": userEmail,
      },
      {
        "id": "5",
        "name": "Bandages",
        "price": 50,
        "quantity": 100,
        "category": "First Aid",
        "expiry": "2028-01-01",
        "userEmail": userEmail,
      },
    ];

    setState(() {
      products = dummyProducts;
      filteredProducts = dummyProducts;
    });

    _extractCategories();
  }

  // Enhanced search with multiple filters
  void _searchProducts(String searchTerm) {
    if (searchTerm.isEmpty &&
        _selectedCategory == 'All' &&
        _minPrice == 0 &&
        _maxPrice == double.infinity) {
      setState(() {
        filteredProducts = List.from(products);
      });
      return;
    }

    final lowerCaseQuery = searchTerm.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        // Text search
        final name = product['name'].toString().toLowerCase();
        final category = product['category'].toString().toLowerCase();
        final textMatch =
            name.contains(lowerCaseQuery) || category.contains(lowerCaseQuery);

        // Category filter
        final categoryMatch = _selectedCategory == 'All' ||
            product['category'] == _selectedCategory;

        // Price range filter
        final price = product['price'] is int
            ? product['price'].toDouble()
            : product['price'];
        final priceMatch = price >= _minPrice && price <= _maxPrice;

        // Availability filter
        final quantityMatch = !_onlyInStock || (product['quantity'] > 0);

        return textMatch && categoryMatch && priceMatch && quantityMatch;
      }).toList();

      // Apply sorting if needed
      if (_sortBy == 'name_asc') {
        filteredProducts.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()));
      } else if (_sortBy == 'name_desc') {
        filteredProducts.sort(
            (a, b) => b['name'].toString().compareTo(a['name'].toString()));
      } else if (_sortBy == 'price_asc') {
        filteredProducts.sort((a, b) => a['price'].compareTo(b['price']));
      } else if (_sortBy == 'price_desc') {
        filteredProducts.sort((a, b) => b['price'].compareTo(a['price']));
      }
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    // Check if product is already in cart
    int index = cart.indexWhere((item) => item['id'] == product['id']);

    if (index != -1) {
      // Product already in cart, increase quantity
      setState(() {
        cart[index]['quantity'] = cart[index]['quantity'] + 1;
      });
    } else {
      // Add new product to cart with quantity 1
      Map<String, dynamic> cartItem = Map<String, dynamic>.from(product);
      cartItem['quantity'] = 1;
      setState(() {
        cart.add(cartItem);
      });
    }

    _calculateTotal();

    // Display success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateCartItemQuantity(int index, int quantity) {
    if (quantity < 1) {
      return;
    }

    setState(() {
      cart[index]['quantity'] = quantity;
    });

    _calculateTotal();
  }

  void _removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });

    _calculateTotal();
  }

  Future<void> _processOrder({bool generateInvoice = false}) async {
    // Validate order
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Please add products.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create order data
      Map<String, dynamic> orderData = {
        'customerName': _customerNameController.text.isEmpty
            ? 'Walk-in Customer'
            : _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'items': cart
            .map((item) => {
                  'productId': item['id'],
                  'name': item['name'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                  'subtotal': (item['price'] as num).toDouble() *
                      (item['quantity'] as num).toDouble(),
                })
            .toList(),
        'subtotal': _subtotal,
        'discount': _discount,
        'tax': _tax,
        'total': _total,
        'date': DateTime.now(),
        'userEmail': _firebaseService.currentUser?.email ?? '',
      };

      // Save to Firestore using SalesService
      String saleId = await _salesService.addSale(orderData);
      orderData['id'] = saleId; // Add ID for the invoice screen

      // Update product quantities in inventory
      for (var item in cart) {
        // Get the current product from inventory
        String productId = item['id'];
        int soldQuantity = item['quantity'];

        try {
          // Update product quantity using SalesService
          await _salesService.updateProductInventory(productId, soldQuantity);
        } catch (e) {
          // Continue with the next item even if this one fails
        }
      }

      // Show success message
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: "Order Complete",
        text: "Sale has been processed successfully!",
      );

      // Clear the cart and customer info
      setState(() {
        cart.clear();
        _customerNameController.clear();
        _customerPhoneController.clear();
        _discountController.text = '0';
        _subtotal = 0;
        _discount = 0;
        _tax = 0;
        _total = 0;
      });

      // Reload products to update stock quantities on the POS screen
      await _loadProducts();

      // Provide invoice display if requested
      if (generateInvoice) {
        Map<String, dynamic> invoiceData = {
          'id': saleId,
          'invoiceNumber': saleId.length > 8
              ? 'INV-${saleId.substring(0, 8).toUpperCase()}'
              : 'INV-$saleId',
          'customerName': orderData['customerName'] ?? 'Walk-in Customer',
          'customerPhone': orderData['customerPhone'] ?? 'N/A',
          'date': orderData['date'] ?? DateTime.now(),
          'items': orderData['items'] ?? [],
          'subtotal': orderData['subtotal']?.toDouble() ?? 0.0,
          'tax': orderData['tax']?.toDouble() ?? 0.0,
          'discount': orderData['discount']?.toDouble() ?? 0.0,
          'total': orderData['total']?.toDouble() ?? 0.0,
          'status': 'PAID',
          'paymentMethod': orderData['paymentMethod'] ?? 'Cash',
        };
        _showInvoicePreviewDialog(invoiceData);
      }
    } catch (e) {
      // Show error message
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: "Error",
        text: "Failed to process order: ${e.toString()}",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInvoicePreviewDialog(Map<String, dynamic> invoiceData) {
    if (!mounted) return;
    final invoiceService = InvoiceService();
    String invoiceText =
        invoiceService.generatePrintableInvoiceText(invoiceData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invoice Dialog'),
        content: SizedBox(
          width: 500,
          height: 600,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
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
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text("Copy Printer Text"),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invoiceText));
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Invoice copied to clipboard!')));
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Advanced search panel with filters
  Widget _buildAdvancedSearchPanel(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      color: themeProvider.cardBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Search Options',
            style: themeProvider.titleTextStyle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Category filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: themeProvider.bodyTextStyle,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: themeProvider.borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        underline: Container(),
                        dropdownColor: themeProvider.cardBackgroundColor,
                        style: TextStyle(color: themeProvider.textColor),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                            _searchProducts(_searchController.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Price range filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: themeProvider.textColor),
                            decoration: InputDecoration(
                              hintText: 'Min',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              hintStyle: TextStyle(
                                  color:
                                      themeProvider.textColor.withOpacity(0.5)),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _minPrice = double.tryParse(value) ?? 0;
                              });
                              _searchProducts(_searchController.text);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(' - '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: themeProvider.textColor),
                            decoration: InputDecoration(
                              hintText: 'Max',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              hintStyle: TextStyle(
                                  color:
                                      themeProvider.textColor.withOpacity(0.5)),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _maxPrice = value.isEmpty
                                    ? double.infinity
                                    : (double.tryParse(value) ??
                                        double.infinity);
                              });
                              _searchProducts(_searchController.text);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Sorting options
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: themeProvider.borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        underline: Container(),
                        dropdownColor: themeProvider.cardBackgroundColor,
                        style: TextStyle(color: themeProvider.textColor),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'name_asc',
                            child: Text('Name (A-Z)'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'name_desc',
                            child: Text('Name (Z-A)'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'price_asc',
                            child: Text('Price (Low-High)'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'price_desc',
                            child: Text('Price (High-Low)'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _sortBy = newValue;
                            });
                            _searchProducts(_searchController.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // In-stock filter
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _onlyInStock,
                      activeColor: themeProvider.gradientColors[0],
                      onChanged: (bool? value) {
                        setState(() {
                          _onlyInStock = value ?? false;
                        });
                        _searchProducts(_searchController.text);
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Show in-stock items only',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Reset filters button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _minPrice = 0;
                    _maxPrice = double.infinity;
                    _sortBy = 'name_asc';
                    _onlyInStock = false;
                    _searchController.clear();
                  });
                  _searchProducts('');
                },
                icon:
                    Icon(Icons.refresh, color: themeProvider.gradientColors[0]),
                label: Text(
                  'Reset Filters',
                  style: TextStyle(
                    color: themeProvider.gradientColors[0],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          'Point of Sale',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _advancedSearchVisible
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _advancedSearchVisible = !_advancedSearchVisible;
              });
            },
            tooltip: 'Advanced Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProducts,
            tooltip: 'Refresh Products',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220, // Reduced from default ~280px to 220px
            child: const Sidebar(),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: themeProvider.scaffoldBackgroundColor,
              ),
              child: Column(
                children: [
                  // Advanced Search Panel
                  if (_advancedSearchVisible)
                    _buildAdvancedSearchPanel(themeProvider),

                  // Main Content
                  Expanded(
                    child: Row(
                      children: [
                        // Left side: Products list
                        Expanded(
                          flex: 3,
                          child: Card(
                            margin: const EdgeInsets.all(16),
                            color: themeProvider.cardBackgroundColor,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: themeProvider.gradientColors[0],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      // Search Bar moved from AppBar
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 16, 16, 8),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: themeProvider.isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: _searchProducts,
                                            style: themeProvider.bodyTextStyle,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search medicines and products...',
                                              hintStyle: themeProvider
                                                  .subtitleTextStyle,
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 15),
                                              prefixIcon: Icon(
                                                Icons.search,
                                                color: themeProvider.iconColor,
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _advancedSearchVisible
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                  color:
                                                      themeProvider.iconColor,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _advancedSearchVisible =
                                                        !_advancedSearchVisible;
                                                  });
                                                },
                                                tooltip: 'Advanced Search',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Products Header
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 8, 16, 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2,
                                              color: themeProvider.iconColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Available Products',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: themeProvider.textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: themeProvider
                                                    .gradientColors[0],
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                '${filteredProducts.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: filteredProducts.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No products found',
                                                  style: themeProvider
                                                      .bodyTextStyle,
                                                ),
                                              )
                                            : GridView.builder(
                                                padding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                                .size
                                                                .width >
                                                            1400
                                                        ? 16
                                                        : 12),
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      2, // Fixed to 2 columns for better readability
                                                  childAspectRatio:
                                                      1.2, // Adjusted for better card proportions
                                                  crossAxisSpacing: 12,
                                                  mainAxisSpacing: 12,
                                                ),
                                                itemCount:
                                                    filteredProducts.length,
                                                itemBuilder: (context, index) {
                                                  final product =
                                                      filteredProducts[index];
                                                  return _buildProductCard(
                                                      product, themeProvider);
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        // Right side: Cart and checkout
                        Expanded(
                          flex: 2,
                          child: Card(
                            margin: const EdgeInsets.all(16),
                            color: themeProvider.cardBackgroundColor,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                // Customer info
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Customer Information',
                                        style: themeProvider.titleTextStyle,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _customerNameController,
                                        labelText: 'Customer Name (Optional)',
                                        icon: Icons.person,
                                        themeProvider: themeProvider,
                                      ),
                                      const SizedBox(height: 6),
                                      _buildTextField(
                                        controller: _customerPhoneController,
                                        labelText: 'Phone Number (Optional)',
                                        icon: Icons.phone,
                                        themeProvider: themeProvider,
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(height: 1),

                                // Cart items
                                Expanded(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.shopping_cart,
                                              color: themeProvider.iconColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Cart Items',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: themeProvider.textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: themeProvider
                                                    .gradientColors[0],
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                '${cart.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            if (cart.isNotEmpty)
                                              TextButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    cart.clear();
                                                    _calculateTotal();
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.remove_shopping_cart,
                                                    size: 16),
                                                label: const Text('Clear'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: cart.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .shopping_cart_outlined,
                                                      size: 64,
                                                      color: themeProvider
                                                          .textColor
                                                          .withOpacity(0.3),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Cart is empty',
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Add products from the left panel',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: themeProvider
                                                            .textColor
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                itemCount: cart.length,
                                                separatorBuilder: (context,
                                                        index) =>
                                                    const Divider(height: 8),
                                                itemBuilder: (context, index) {
                                                  return _buildCartItem(
                                                      index, themeProvider);
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Order summary and checkout
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Discount field
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _discountController,
                                              labelText: 'Discount Amount',
                                              icon: Icons.discount,
                                              themeProvider: themeProvider,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                _calculateTotal();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Apply 10% discount
                                              double discount = _subtotal * 0.1;
                                              _discountController.text =
                                                  discount.toStringAsFixed(2);
                                              _calculateTotal();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: themeProvider
                                                  .gradientColors[0],
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('10% Off'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Order summary
                                      _buildSummaryRow(
                                          'Subtotal',
                                          _subtotal.toStringAsFixed(2),
                                          themeProvider),
                                      _buildSummaryRow(
                                          'Tax (10%)',
                                          _tax.toStringAsFixed(2),
                                          themeProvider),
                                      _buildSummaryRow(
                                          'Discount',
                                          _discount.toStringAsFixed(2),
                                          themeProvider,
                                          isDiscount: true),
                                      const Divider(thickness: 1),
                                      _buildSummaryRow(
                                          'Total',
                                          _total.toStringAsFixed(2),
                                          themeProvider,
                                          isTotal: true),

                                      const SizedBox(height: 12),

                                      // Checkout buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 50,
                                              child: ElevatedButton(
                                                onPressed: cart.isEmpty ||
                                                        _isLoading
                                                    ? null
                                                    : () => _processOrder(
                                                        generateInvoice: false),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.grey[
                                                      700], // distinct subtle color
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      Colors.grey,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white)))
                                                    : const Text(
                                                        'Process Order',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: SizedBox(
                                              height: 50,
                                              child: ElevatedButton(
                                                onPressed: cart.isEmpty ||
                                                        _isLoading
                                                    ? null
                                                    : () => _processOrder(
                                                        generateInvoice: true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: themeProvider
                                                      .gradientColors[0],
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      Colors.grey,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white)))
                                                    : const Text(
                                                        'Process & Invoice',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                              ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> product, ThemeProvider themeProvider) {
    return Card(
      color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top content: Category badge, name, price and stock
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge and icon in a row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          _getCategoryIcon(product['category']),
                          size: 24,
                          color: themeProvider.gradientColors[0],
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(product['category']),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product['category'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Product name
                    Text(
                      product['name'],
                      style: themeProvider.titleTextStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Price and stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '\$${product['price']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.gradientColors[0],
                              fontSize: themeProvider.fontSize + 4,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStockColor(product['quantity']),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stock: ${product['quantity']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Add to cart button - positioned at the bottom
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: (product['quantity'] > 0)
                      ? () => _addToCart(product)
                      : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label:
                      const Text('Add to Cart', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.gradientColors[0],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(int index, ThemeProvider themeProvider) {
    final item = cart[index];
    final double itemTotal =
        (item['price'] is int ? item['price'].toDouble() : item['price']) *
            (item['quantity'] is int
                ? item['quantity'].toDouble()
                : item['quantity']);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 14),
                  onPressed: () =>
                      _updateCartItemQuantity(index, item['quantity'] - 1),
                  splashRadius: 14,
                  tooltip: 'Decrease quantity',
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item['quantity'].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  onPressed: () =>
                      _updateCartItemQuantity(index, item['quantity'] + 1),
                  splashRadius: 14,
                  tooltip: 'Increase quantity',
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: themeProvider.textColor,
                    fontSize: themeProvider.fontSize - 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '\$${item['price']} × ${item['quantity']} = \$${itemTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: themeProvider.textColor.withOpacity(0.7),
                    fontSize: themeProvider.fontSize - 3,
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
            onPressed: () => _removeFromCart(index),
            splashRadius: 14,
            tooltip: 'Remove item',
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required ThemeProvider themeProvider,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: themeProvider.bodyTextStyle,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: themeProvider.subtitleTextStyle,
        prefixIcon: Icon(icon, color: themeProvider.gradientColors[0]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor:
            themeProvider.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeProvider.gradientColors[0].withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeProvider.gradientColors[0],
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, ThemeProvider themeProvider,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? themeProvider.titleTextStyle
                : themeProvider.bodyTextStyle,
          ),
          Text(
            isDiscount ? '-\$$value' : '\$$value',
            style: TextStyle(
              fontSize:
                  isTotal ? themeProvider.fontSize + 2 : themeProvider.fontSize,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount
                  ? Colors.red
                  : (isTotal
                      ? themeProvider.gradientColors[0]
                      : themeProvider.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medicine':
        return Colors.blue;
      case 'supplements':
        return Colors.green;
      case 'first aid':
        return Colors.red;
      case 'hygiene':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medicine':
        return Icons.medication;
      case 'supplements':
        return Icons.fitness_center;
      case 'first aid':
        return Icons.healing;
      case 'hygiene':
        return Icons.cleaning_services;
      default:
        return Icons.category;
    }
  }

  Color _getStockColor(int quantity) {
    if (quantity <= 0) {
      return Colors.red;
    } else if (quantity < 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
