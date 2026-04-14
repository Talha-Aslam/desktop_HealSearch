import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/firebase_service.dart';
import 'package:intl/intl.dart';

class EditProduct extends StatefulWidget {
  final String productID;

  const EditProduct({super.key, required this.productID});

  @override
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final TextEditingController _productName = TextEditingController();
  final TextEditingController _productPrice = TextEditingController();
  final TextEditingController _productQty = TextEditingController();
  final TextEditingController _productCategory = TextEditingController();
  final TextEditingController _productExpiry = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  // Define categories list once to avoid duplicates
  static const List<String> _defaultCategories = [
    "Medicine",
    "Supplements",
    "First Aid",
    "Hygiene",
    "Other"
  ];

  // Dynamic categories list that can accommodate existing data
  List<String> _categories = List.from(_defaultCategories);

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasInitialized = false; // Flag to prevent multiple initializations

  @override
  void initState() {
    super.initState();
    // Don't call _loadProductData here - move to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once when dependencies are available
    if (!_hasInitialized) {
      _hasInitialized = true;
      _loadProductData();
    }
  }

  @override
  void dispose() {
    _productName.dispose();
    _productPrice.dispose();
    _productQty.dispose();
    _productCategory.dispose();
    _productExpiry.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    if (!mounted) return; // Safety check before starting

    try {
      setState(() {
        _isLoading = true;
      });

      // Debug logging
      print('Attempting to load product with ID: ${widget.productID}');

      // Check if productID is valid
      if (widget.productID.isEmpty) {
        // Use post-frame callback to navigate back to products page
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/products');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Please select a product to edit from the Products page'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
        return;
      }

      // Check if this is a dummy product
      if (widget.productID.startsWith('dummy_')) {
        throw Exception(
            'This is demonstration data. Please add real products to edit them.');
      }

      Map<String, dynamic>? productData =
          await _firebaseService.getProduct(widget.productID);

      if (!mounted) return; // Check mounted after async operation

      if (productData != null) {
        print('Product data loaded successfully: ${productData['name']}');
        print('Raw product data: $productData');
        print(
            'Quantity from Firebase: ${productData['quantity']} (type: ${productData['quantity'].runtimeType})');

        setState(() {
          _productName.text = productData['name'] ?? '';
          _productPrice.text = productData['price']?.toString() ?? '';
          // Ensure quantity is displayed as integer
          var quantityValue = productData['quantity'];
          if (quantityValue != null) {
            // Convert to int first to remove decimal places, then to string
            if (quantityValue is double) {
              _productQty.text = quantityValue.toInt().toString();
            } else if (quantityValue is int) {
              _productQty.text = quantityValue.toString();
            } else {
              // Try to parse from string
              int? parsed = int.tryParse(quantityValue.toString());
              _productQty.text = (parsed ?? 0).toString();
            }
          } else {
            _productQty.text = '0';
          }

          // Handle category validation - ensure loaded category exists in our categories list
          String loadedCategory = productData['category'] ?? '';
          print('Loaded category from database: "$loadedCategory"');
          print('Current categories list: $_categories');

          if (loadedCategory.isNotEmpty &&
              !_categories.contains(loadedCategory)) {
            // If the loaded category is not in our current list, add it to accommodate existing data
            print(
                'Adding existing category "$loadedCategory" to categories list');
            _categories.add(loadedCategory);
            print('Updated categories list: $_categories');
          }

          // Remove any potential duplicates
          _categories = _categories.toSet().toList();
          print('Categories after deduplication: $_categories');

          _productCategory.text = loadedCategory;
          print('Set _productCategory.text to: "${_productCategory.text}"');

          _productExpiry.text = productData['expiry'] ?? '';
          _isLoading = false;
        });

        print('Quantity field after setting: "${_productQty.text}"');
      } else {
        // Product not found, show error and navigate back
        print('Product not found for ID: ${widget.productID}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Use post-frame callback to avoid calling SnackBar during build
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product not found or access denied'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading product: $e');

      if (!mounted) return; // Check mounted before setState and context usage

      setState(() {
        _isLoading = false;
      });

      // Use post-frame callback to avoid calling SnackBar during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading product: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return; // Safety check

    setState(() {
      _isSaving = true;
    });

    try {
      // Debug logging for quantity
      print('Quantity text before parsing: "${_productQty.text}"');
      print('Quantity text trimmed: "${_productQty.text.trim()}"');

      // More robust quantity parsing
      String quantityText = _productQty.text.trim();
      int parsedQuantity = 0;

      if (quantityText.isNotEmpty) {
        int? temp = int.tryParse(quantityText);
        if (temp != null) {
          parsedQuantity = temp;
        } else {
          print('Failed to parse quantity: $quantityText');
          // Try to extract numbers only
          String numbersOnly = quantityText.replaceAll(RegExp(r'[^0-9]'), '');
          temp = int.tryParse(numbersOnly);
          if (temp != null) {
            parsedQuantity = temp;
            print('After extracting numbers only: $parsedQuantity');
          } else {
            // If parsing still fails, get the current value from Firebase
            try {
              Map<String, dynamic>? currentProductData =
                  await _firebaseService.getProduct(widget.productID);
              var fbQuantity = currentProductData?['quantity'];
              if (fbQuantity is double) {
                parsedQuantity = fbQuantity.toInt();
              } else if (fbQuantity is int) {
                parsedQuantity = fbQuantity;
              } else {
                parsedQuantity = int.tryParse(fbQuantity.toString()) ?? 0;
              }
              print('Using original quantity from Firebase: $parsedQuantity');
            } catch (e) {
              print('Error getting original quantity: $e');
              parsedQuantity = 0;
            }
          }
        }
      } else {
        // If the field is empty, try to get the current value from Firebase
        try {
          Map<String, dynamic>? currentProductData =
              await _firebaseService.getProduct(widget.productID);
          var fbQuantity = currentProductData?['quantity'];
          if (fbQuantity is double) {
            parsedQuantity = fbQuantity.toInt();
          } else if (fbQuantity is int) {
            parsedQuantity = fbQuantity;
          } else {
            parsedQuantity = int.tryParse(fbQuantity.toString()) ?? 0;
          }
          print(
              'Field was empty, using original quantity from Firebase: $parsedQuantity');
        } catch (e) {
          print('Error getting original quantity for empty field: $e');
          parsedQuantity = 0;
        }
      }

      // Ensure quantity is non-negative
      if (parsedQuantity < 0) {
        parsedQuantity = 0;
      }

      // Prepare updated product data
      Map<String, dynamic> updatedProductData = {
        'name': _productName.text.trim(),
        'price': double.tryParse(_productPrice.text) ?? 0.0,
        'quantity': parsedQuantity,
        'category': _productCategory.text.trim(),
        'expiry': _productExpiry.text.trim(),
      };

      print('Final product data to save: $updatedProductData');

      // Update product in Firebase
      await _firebaseService.updateProduct(
          widget.productID, updatedProductData);

      if (!mounted) return; // Check mounted after async operation

      // Show success message using SnackBar
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });

      // Navigate back to previous screen after a short delay to show the SnackBar
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(
              context, true); // Return true to indicate successful update
        }
      });
    } catch (e) {
      if (!mounted) return; // Check mounted before showing error

      // Show error message using SnackBar
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update product: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (!mounted) return; // Safety check

    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return AlertDialog(
          backgroundColor: themeProvider.cardBackgroundColor,
          title: Text(
            'Delete Product',
            style: TextStyle(color: themeProvider.textColor),
          ),
          content: Text(
            'Are you sure you want to delete "${_productName.text}"? This action cannot be undone.',
            style: TextStyle(color: themeProvider.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.textColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      try {
        setState(() {
          _isSaving = true;
        });

        await _firebaseService.deleteProduct(widget.productID);

        if (!mounted) return; // Check mounted after async operation

        // Show success message using SnackBar
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product deleted successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });

        // Navigate back to previous screen after a short delay to show the SnackBar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(
                context, true); // Return true to indicate successful deletion
          }
        });
      } catch (e) {
        if (!mounted) return; // Check mounted before showing error

        // Show error message using SnackBar
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete product: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('EditProduct build called - Quantity: "${_productQty.text}"');
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
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
            'Edit Product',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: themeProvider.scaffoldBackgroundColor,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: themeProvider.gradientColors[0],
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading product data...',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          'Edit Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Delete Product',
            onPressed: _isSaving ? null : _deleteProduct,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: themeProvider.scaffoldBackgroundColor,
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product header card
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeProvider.gradientColors[0].withOpacity(0.1),
                      themeProvider.gradientColors[1].withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.gradientColors[0].withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: themeProvider.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.inventory,
                        size: 30,
                        color: themeProvider.gradientColors[0],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product ID: ${widget.productID}',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _productName.text,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                          ),
                          Text(
                            'Category: ${_productCategory.text}',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Edit product form
              Card(
                color: themeProvider.cardBackgroundColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _productName,
                          labelText: 'Product Name',
                          icon: Icons.shopping_bag,
                          themeProvider: themeProvider,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _productPrice,
                                labelText: 'Price',
                                icon: Icons.attach_money,
                                themeProvider: themeProvider,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(
                                      r'^\d+\.?\d{0,2}')), // Allow numbers with up to 2 decimal places
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _productQty,
                                labelText: 'Quantity',
                                icon: Icons.inventory_2,
                                themeProvider: themeProvider,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      6), // Limit to 6 digits
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter quantity';
                                  }
                                  // Try to parse the quantity
                                  int? quantity = int.tryParse(value.trim());
                                  if (quantity == null) {
                                    return 'Enter a valid number';
                                  }
                                  if (quantity < 0) {
                                    return 'Quantity cannot be negative';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          context,
                          'Product Category',
                          Icons.category,
                          _categories
                              .toSet()
                              .toList(), // Remove duplicates here
                          (value) {
                            setState(() {
                              _productCategory.text = value.toString();
                            });
                          },
                          "Select Category",
                          value: _categories.contains(_productCategory.text)
                              ? _productCategory.text
                              : null,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _productExpiry,
                          labelText: 'Product Expiry Date',
                          icon: Icons.calendar_today,
                          themeProvider: themeProvider,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: themeProvider.isDarkMode
                                        ? ColorScheme.dark(
                                            primary:
                                                themeProvider.gradientColors[0],
                                          )
                                        : ColorScheme.light(
                                            primary:
                                                themeProvider.gradientColors[0],
                                          ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedDate != null) {
                              String formattedDate =
                                  DateFormat('yyyy-MM-dd').format(pickedDate);
                              setState(() {
                                _productExpiry.text = formattedDate;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select the product expiry date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.gradientColors[0],
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'SAVING...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'SAVE CHANGES',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required ThemeProvider themeProvider,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      onTap: onTap,
      readOnly: onTap != null,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: themeProvider.textColor.withOpacity(0.7)),
        prefixIcon: Icon(
          icon,
          color: themeProvider.gradientColors[0],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: themeProvider.gradientColors[0]),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeProvider.isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: themeProvider.gradientColors[0], width: 2),
        ),
        filled: true,
        fillColor: themeProvider.isDarkMode
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
      ),
      style: TextStyle(color: themeProvider.textColor),
      validator: validator,
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    IconData icon,
    List<String> items,
    void Function(dynamic) onChanged,
    String hint, {
    String? Function(dynamic)? validator,
    String? value,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Remove duplicates and debug
    List<String> uniqueItems = items.toSet().toList();
    print('_buildDropdown called with:');
    print('  label: $label');
    print('  items: $items');
    print('  value: $value');

    if (items.length != uniqueItems.length) {
      print(
          'WARNING: Removed ${items.length - uniqueItems.length} duplicate items');
    }

    // Validate value exists in items
    if (value != null && !uniqueItems.contains(value)) {
      print('WARNING: Value "$value" not found in items, setting to null');
      value = null;
    }

    return DropdownButtonFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: themeProvider.textColor),
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
            color: themeProvider.gradientColors[0].withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeProvider.gradientColors[0],
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
      style: TextStyle(color: themeProvider.textColor),
      dropdownColor: themeProvider.cardBackgroundColor,
      items: uniqueItems.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      hint: Text(
        hint,
        style: TextStyle(
          color: themeProvider.textColor.withOpacity(0.7),
        ),
      ),
      icon: Icon(Icons.arrow_drop_down, color: themeProvider.gradientColors[0]),
    );
  }
}
