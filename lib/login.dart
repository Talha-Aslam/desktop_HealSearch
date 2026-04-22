import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desktop_search_a_holic/tenant_provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final _supabase = Supabase.instance.client;
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    ThemeProvider themeProvider, {
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final filled = !themeProvider.isDarkMode;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      errorStyle: const TextStyle(
        color: Colors.yellow,
        fontWeight: FontWeight.bold,
      ),
      filled: filled,
      fillColor: filled ? Colors.black.withOpacity(0.3) : Colors.transparent,
    );
  }

  Future<void> checkLogin(BuildContext context) async {
    if (_isLoading) return;

    final enteredEmail = email.text.trim();
    final enteredPassword = password.text;

    if (enteredEmail.isEmpty) {
      _showMessage('Please enter your email', backgroundColor: Colors.orange);
      return;
    }
    if (!_emailRegex.hasMatch(enteredEmail)) {
      _showMessage('Please enter a valid email address',
          backgroundColor: Colors.orange);
      return;
    }
    if (enteredPassword.isEmpty) {
      _showMessage('Please enter your password',
          backgroundColor: Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to sign in with Supabase Auth
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: enteredEmail,
        password: enteredPassword,
      );

      if (response.user != null) {
        // Fetch the user's pharmacy profile to get the Tenant ID
        final profileData = await _supabase
            .from('user_profiles')
            .select('pharmacy_id')
            .eq('id', response.user!.id)
            .single();

        final pharmacyId = profileData['pharmacy_id'] as String;

        if (!context.mounted) return;

        Provider.of<TenantProvider>(context, listen: false)
            .setPharmacyId(pharmacyId);

        _showMessage('Login successful!', backgroundColor: Colors.green);
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on AuthException catch (e) {
      _showMessage(
        'Login failed: ${e.message}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _showMessage(
        'Login error: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
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
    final size = MediaQuery.of(context).size;

    // Define text colors based on the current theme
    final textColor = Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: themeProvider.scaffoldBackgroundColor,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: size.width > 600 ? 500 : size.width * 0.9,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: LinearGradient(
                  colors: themeProvider.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.5),
                    spreadRadius: 4,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Login logo or icon
                    Icon(
                      Icons.local_pharmacy,
                      size: 96,
                      color: textColor,
                    ),
                    const SizedBox(height: 16.0),
                    // Login title
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Sign in to manage your pharmacy',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    // Email field
                    TextFormField(
                      controller: email,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _passwordFocusNode.requestFocus(),
                      decoration: _buildInputDecoration(
                        themeProvider,
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        icon: Icons.email,
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                    // Password field
                    TextFormField(
                      controller: password,
                      focusNode: _passwordFocusNode,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => checkLogin(context),
                      decoration: _buildInputDecoration(
                        themeProvider,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock,
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
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12.0),
                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          try {
                            await Navigator.pushNamed(
                                context, '/forgetPassword');
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error navigating to password reset: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // Login Button
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
                              onPressed: () => checkLogin(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login,
                                      color: themeProvider.gradientColors[0]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Secure Login',
                                    style: TextStyle(
                                      color: themeProvider.gradientColors[0],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 24.0),
                    // Theme toggler built into login bottom
                    TextButton.icon(
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: Colors.white,
                      ),
                      label: Text(
                        themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(height: 8.0),
                    // Registration Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account? ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/registration');
                          },
                          child: const Text(
                            'Register Now',
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
