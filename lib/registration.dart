import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final _supabase = Supabase.instance.client;

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
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Generate automatic shop ID
  Future<String> _generateShopId() async {
    try {
      final response = await _supabase
          .from('pharmacies')
          .select('id')
          .limit(1)
          .order('created_at', ascending: false);
      int count = (response as List).length + 1; // Just a rough estimate

      return 'SHOP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    } catch (e) {
      return 'SHOP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  // Register user with Supabase
  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Sign up user
      final AuthResponse res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = res.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      // Generate automatic shop ID and insert pharmacy
      String autoShopId = await _generateShopId();

      final pharmacyData = {
        'name': _nameController.text.trim() + ' Pharmacy', // or let them pick
        'address': '',
        'contact_number': _phoneController.text,
        // user could change this
      };

      final pharmacyRes = await _supabase
          .from('pharmacies')
          .insert(pharmacyData)
          .select('id')
          .single();

      final pharmacyId = pharmacyRes['id'] as String;

      // 3. Link user profile to pharmacy
      final profileData = {
        'id': user.id,
        'pharmacy_id': pharmacyId,
        'role': 'owner',
        'full_name': _nameController.text.trim(),
      };

      await _supabase.from('user_profiles').insert(profileData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Shop ID: $autoShopId.'),
          duration: const Duration(seconds: 5),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.message}')),
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
