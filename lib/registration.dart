import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController =
      TextEditingController(); // Address controller for display only

  Position? _currentPosition;
  String _currentAddress = "No location selected";
  bool _isLocationLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose(); // Dispose address controller
    super.dispose();
  }

  // Check and request location permissions
  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      // Permission already granted
      return;
    } else if (status.isDenied) {
      // Request permission
      await Permission.location.request();
    }
  }

  // Check if location services are enabled
  Future<bool> _checkLocationServicesEnabled() async {
    bool serviceEnabled;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Location services are disabled. Please enable them in your device settings.'),
          duration: Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  // Get current location and convert to address
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Check if running on web - different handling required
      if (kIsWeb) {
        await _handleWebLocation();
        return;
      }

      // Check permission first (for mobile and desktop platforms)
      try {
        final permissionStatus = await Permission.location.status;
        if (!permissionStatus.isGranted) {
          final result = await Permission.location.request();
          if (result != PermissionStatus.granted) {
            // Show dialog to manually enter address if permission denied
            _showManualAddressInputDialog();
            return;
          }
        }
      } catch (e) {
        // On Windows, location permission might not be available through permission_handler
        // Continue with location request and handle errors gracefully
        print('Permission handling not supported on this platform: $e');
      }

      // Check if location services are enabled
      final servicesEnabled = await _checkLocationServicesEnabled();
      if (!servicesEnabled) {
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10), // Add timeout
      );

      // Convert position to address
      await _convertPositionToAddress(position);
    } catch (e) {
      print('Error getting location: $e');
      // Handle geocoding errors
      _handleGeocodingError(e);
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  // Handle web-specific location requests
  Future<void> _handleWebLocation() async {
    try {
      // Check if geolocation is available in browser
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showManualAddressInputDialog();
          return;
        }
      }

      // Try to get position on web
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // For web, we'll try geocoding but gracefully handle failures
      await _convertPositionToAddress(position);
    } catch (e) {
      print('Web location error: $e');
      // Fallback to manual address input for web
      _showManualAddressInputDialog();
    }
  }

  // Convert position to address (separate method for better error handling)
  Future<void> _convertPositionToAddress(Position position) async {
    try {
      // Convert position to address (may not work on web)
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        final address = '${placemark.street ?? ''}, '
            '${placemark.subLocality ?? ''}, '
            '${placemark.locality ?? ''}, '
            '${placemark.administrativeArea ?? ''}, '
            '${placemark.country ?? ''} '
            '${placemark.postalCode ?? ''}';

        // Clean up the address for better readability
        final cleanedAddress = _cleanUpAddress(address);
        setState(() {
          _currentPosition = position;
          _currentAddress = cleanedAddress;
          _addressController.text = cleanedAddress;
        });

        // Show success message for full address
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address successfully retrieved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // If no placemark found, use coordinates but don't show error
        setState(() {
          _currentPosition = position;
          _currentAddress =
              'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _addressController.text = _currentAddress;
        });

        // Show informational message only
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location coordinates set. You may add a descriptive address if needed.'),
            action: SnackBarAction(
              label: 'Add Address',
              onPressed: _showManualAddressInputDialog,
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Geocoding error: $e');
      // If geocoding fails, just use coordinates without showing error
      setState(() {
        _currentPosition = position;
        _currentAddress =
            'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _addressController.text = _currentAddress;
      });

      // Only show gentle suggestion, not an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Location set with coordinates. You may add a descriptive address if needed.'),
          action: SnackBarAction(
            label: 'Add Address',
            onPressed: _showManualAddressInputDialog,
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Handle geocoding errors
  void _handleGeocodingError(dynamic error) {
    String errorMessage;

    if (error is PermissionDeniedException) {
      errorMessage = 'Location permission denied';
    } else if (error is LocationServiceDisabledException) {
      errorMessage = 'Location services are disabled';
    } else if (error.toString().contains('null')) {
      errorMessage = kIsWeb
          ? 'Location services may be limited in web browsers. Please enter your address manually.'
          : 'Location service unavailable. Please enter your address manually.';
    } else if (error.toString().contains('PlatformException')) {
      // Handle Windows-specific platform exceptions
      errorMessage =
          'Location service not available on this device. Please enter your address manually.';
    } else {
      errorMessage = kIsWeb
          ? 'Location services are not fully supported in web browsers. Please enter your address manually.'
          : 'Failed to get location: Please enter your address manually.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        action: SnackBarAction(
          label: 'Enter manually',
          onPressed: _showManualAddressInputDialog,
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Show dialog to manually input address
  void _showManualAddressInputDialog() {
    final TextEditingController manualAddressController =
        TextEditingController();

    setState(() {
      _isLocationLoading = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit_location_alt, color: Colors.blue),
            SizedBox(width: 8),
            Text('Enter Shop Address'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kIsWeb
                  ? 'Location services may be limited in web browsers. Please enter your shop address manually.'
                  : 'Please enter your shop address manually.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Note: Manual address entry will not include exact map coordinates.',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange),
            ),
            SizedBox(height: 16),
            TextField(
              controller: manualAddressController,
              decoration: InputDecoration(
                labelText: 'Shop Address',
                hintText: 'Enter complete address with city and postal code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.cancel),
            label: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text('Save Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (manualAddressController.text.trim().isNotEmpty) {
                setState(() {
                  _addressController.text = manualAddressController.text.trim();
                  // Clear position data as we don't have coordinates for manual address
                  _currentPosition = null;
                });
                Navigator.of(context).pop();

                // Show message about manual address
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Manual address saved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid address'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Generate automatic shop ID
  Future<String> _generateShopId() async {
    try {
      // Get count of existing pharmacies to generate sequential ID
      QuerySnapshot existingPharmacies =
          await _firestore.collection('pharmacies').get();
      int count = existingPharmacies.docs.length + 1;

      // Generate shop ID with format: SHOP + 4-digit number (e.g., SHOP0001)
      String shopId = 'SHOP${count.toString().padLeft(4, '0')}';

      // Check if this shop ID already exists
      QuerySnapshot existingShopId = await _firestore
          .collection('pharmacies')
          .where('shopId', isEqualTo: shopId)
          .get();

      // If shop ID exists, increment until we find unique one
      while (existingShopId.docs.isNotEmpty) {
        count++;
        shopId = 'SHOP${count.toString().padLeft(4, '0')}';
        existingShopId = await _firestore
            .collection('pharmacies')
            .where('shopId', isEqualTo: shopId)
            .get();
      }

      return shopId;
    } catch (e) {
      // Fallback to timestamp-based ID if query fails
      return 'SHOP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  // Register user with Firebase
  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Check if a location has been selected
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your shop location')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Generate automatic shop ID
      String autoShopId = await _generateShopId();

      // Store additional user data in Firestore
      Map<String, dynamic> userData = {
        'name': _nameController.text,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text,
        'shopId': autoShopId, // Store automatically generated shop ID
        'address': _addressController.text, // Store address
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add location coordinates if available
      if (_currentPosition != null) {
        userData['location'] = {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude
        };
      }

      await _firestore
          .collection('pharmacies')
          .doc(userCredential.user!.uid)
          .set(userData);

      // Show success message with generated shop ID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Registration successful! Your Shop ID is: $autoShopId. You can now login.'),
          duration: Duration(seconds: 5),
        ),
      );

      // Navigate to login page
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  double _calculatePasswordStrength() {
    int strength = 0;
    if (_hasMinLength) strength++;
    if (_hasUppercase) strength++;
    if (_hasLowercase) strength++;
    if (_hasDigit) strength++;
    if (_hasSpecialChar) strength++;

    return strength / 5;
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.7) return 'Medium';
    return 'Strong';
  }

  // Clean up address string by removing empty parts and extra commas
  String _cleanUpAddress(String address) {
    // Replace multiple commas with a single comma
    String cleaned = address.replaceAll(RegExp(r',\s*,'), ',');

    // Split by comma and filter out empty parts
    List<String> parts = cleaned
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    // Join parts back with commas
    return parts.join(', ');
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  Widget _buildPasswordCriteriaRow(bool isMet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.check_circle_outline,
            color: isMet ? Colors.green : Colors.white.withOpacity(0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    final double passwordStrength = _calculatePasswordStrength();
    final Color strengthColor = _getStrengthColor(passwordStrength);
    final String strengthText = _getStrengthText(passwordStrength);

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
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: themeProvider.scaffoldBackgroundColor,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: size.width > 600 ? 600 : size.width * 0.9,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  colors: themeProvider.gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Registration icon and title
                    Icon(
                      Icons.app_registration,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Create New Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Please fill in the form to create your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: 'Enter your full name',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: !themeProvider.isDarkMode,
                        fillColor: !themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: 'Enter your email address',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: !themeProvider.isDarkMode,
                        fillColor: !themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16.0),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: 'Enter your phone number',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon:
                            const Icon(Icons.phone, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: !themeProvider.isDarkMode,
                        fillColor: !themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Shop ID information
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your Shop ID will be automatically generated during registration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Address/Location field with automatic location detection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Shop Location (Required)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (!_isLocationLoading) {
                                _getCurrentLocation();
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _addressController.text.isEmpty
                                            ? Icons.add_location_alt
                                            : Icons.check_circle,
                                        color: _addressController.text.isEmpty
                                            ? Colors.white
                                            : Colors.green,
                                        size: 22,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _addressController.text.isEmpty
                                              ? 'Tap to set your shop location'
                                              : 'Location successfully set',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (_isLocationLoading)
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      else if (_addressController
                                          .text.isNotEmpty)
                                        IconButton(
                                          icon: Icon(Icons.refresh,
                                              color: Colors.white),
                                          onPressed: () =>
                                              _getCurrentLocation(),
                                          tooltip: 'Update location',
                                        ),
                                    ],
                                  ),
                                  if (_addressController.text.isNotEmpty) ...[
                                    SizedBox(height: 10),
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _addressController.text,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '⚠️ This address will be permanent and cannot be changed later',
                                            style: TextStyle(
                                              color: Colors.yellow,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white.withOpacity(0.7),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'You can tap the location area or manually enter your address if needed',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_addressController.text.isEmpty)
                              TextButton.icon(
                                onPressed: () =>
                                    _showManualAddressInputDialog(),
                                icon: Icon(Icons.edit_location_alt,
                                    color: Colors.white70, size: 18),
                                label: Text(
                                  'Enter address manually',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Password field with strength indicator
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: 'Enter your password',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: !themeProvider.isDarkMode,
                        fillColor: !themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                    ),

                    // Password strength indicator
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 10.0),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Password Strength: ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  strengthText,
                                  style: TextStyle(
                                    color: strengthColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Progress bar for password strength
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: passwordStrength,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                color: strengthColor,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Password criteria checklist
                            _buildPasswordCriteriaRow(
                                _hasMinLength, 'At least 8 characters'),
                            _buildPasswordCriteriaRow(_hasUppercase,
                                'At least one uppercase letter (A-Z)'),
                            _buildPasswordCriteriaRow(_hasLowercase,
                                'At least one lowercase letter (a-z)'),
                            _buildPasswordCriteriaRow(
                                _hasDigit, 'At least one number (0-9)'),
                            _buildPasswordCriteriaRow(_hasSpecialChar,
                                'At least one special character (!@#\$%^&*...)'),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16.0),

                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: 'Confirm your password',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: !themeProvider.isDarkMode,
                        fillColor: !themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),

                    // Terms and conditions checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: true,
                          onChanged: (value) {},
                          checkColor: themeProvider.gradientColors[0],
                          fillColor: WidgetStateProperty.all(Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    themeProvider.gradientColors[0],
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                              ),
                              onPressed: registerUser,
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16.0),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
