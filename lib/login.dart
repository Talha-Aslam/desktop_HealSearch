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
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String validateLogin() {
    if (email.text == "") {
      return "emptyEmail"; // Error Message
    } else if (password.text == "") {
      return "emptyPassword"; // Error Message
    } else {
      return "valid"; // Valid Message
    }
  }

  Future<void> checkLogin(BuildContext context) async {
    String validationMessage = validateLogin();
    if (validationMessage == "valid") {
      setState(() {
        _isLoading = true;
      });

      try {
        // Attempt to sign in with Supabase Auth
        final AuthResponse response =
            await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );

        if (response.user != null) {
          // Fetch the user's pharmacy profile to get the Tenant ID
          final profileData = await Supabase.instance.client
              .from('user_profiles')
              .select('pharmacy_id')
              .eq('id', response.user!.id)
              .single();

          final pharmacyId = profileData['pharmacy_id'] as String;

          if (context.mounted) {
            Provider.of<TenantProvider>(context, listen: false)
                .setPharmacyId(pharmacyId);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } on AuthException catch (e) {
        String errorMessage = 'Login failed: ${e.message}';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } catch (e) {
        // Handle other errors
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Show validation error
      String fieldName =
          validationMessage == "emptyEmail" ? "email" : "password";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your $fieldName'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
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
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: Colors.white),
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
                        errorStyle: TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: !themeProvider
                            .isDarkMode, // Only fill background in light mode
                        fillColor: !themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : // Darker background for light mode
                            Colors.transparent, // Keep transparent in dark mode
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
                        filled: !themeProvider
                            .isDarkMode, // Only fill background in light mode
                        fillColor: !themeProvider.isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : // Darker background for light mode
                            Colors.transparent, // Keep transparent in dark mode
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
