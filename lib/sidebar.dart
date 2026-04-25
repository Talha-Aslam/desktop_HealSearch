import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/healsearch_branding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with WidgetsBindingObserver {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserData(showLoading: false);
    }
  }

  String _resolveDisplayName(User? user, Map<String, dynamic>? profile) {
    if (profile != null) {
      final name = profile['name'];
      if (name is String && name.trim().isNotEmpty) return name;

      final fullName = profile['full_name'];
      if (fullName is String && fullName.trim().isNotEmpty) return fullName;
    }

    final metadataName = user?.userMetadata?['name']?.toString();
    if (metadataName != null && metadataName.trim().isNotEmpty) {
      return metadataName;
    }

    final metadataFullName = user?.userMetadata?['full_name']?.toString();
    if (metadataFullName != null && metadataFullName.trim().isNotEmpty) {
      return metadataFullName;
    }

    return 'User';
  }

  Future<void> _loadUserData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _profileData = null;
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sidebar user data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      backgroundColor:
          themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 8,
      child: Column(
        children: [
          Container(
            height: 140, // Reduced from 180 to 140
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const HealSearchLogo(
                  width: 80,
                  height: 80,
                  borderRadius: 20,
                ),
                const SizedBox(height: 16),
                const Text(
                  'HealSearch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle button
          Container(
            color: themeProvider.isDarkMode
                ? const Color(0xFF252525)
                : const Color(0xFFF5F5F5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: themeProvider.isDarkMode,
                  activeThumbColor: themeProvider.gradientColors[0],
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: themeProvider.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade300,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildListTile(
                  context: context,
                  icon: Icons.dashboard,
                  text: 'Dashboard',
                  route: '/dashboard',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.person,
                  text: 'Profile',
                  route: '/profile',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.shopping_cart,
                  text: 'Products',
                  route: '/products',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.add_shopping_cart,
                  text: 'Add Product',
                  route: '/addProduct',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.upload_file,
                  text: 'Manage Data',
                  route: '/uploadData',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.inventory_2,
                  text: 'Stock Alerts',
                  route: '/stock-alerts',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.point_of_sale,
                  text: 'Point of Sale',
                  route: '/pos',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.receipt,
                  text: 'Invoices',
                  route: '/invoices',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.report,
                  text: 'Reports',
                  route: '/reports',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.settings,
                  text: 'Settings',
                  route: '/settings',
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.logout,
                  text: 'Logout',
                  route: '/login',
                  isLogout: true,
                  onTap: () async {
                    // Sign out the user before navigating
                    try {
                      await _supabase.auth.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (Route<dynamic> route) => false);
                    } catch (e) {
                      print('Error signing out: $e');
                    }
                  },
                ),
              ],
            ),
          ),
          // User info at bottom of sidebar - Dynamic from Firestore
          Container(
            color: themeProvider.isDarkMode
                ? const Color(0xFF252525)
                : const Color(0xFFF5F5F5),
            padding: const EdgeInsets.all(16),
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeProvider.gradientColors[0],
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resolveDisplayName(
                                _supabase.auth.currentUser,
                                _profileData,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _supabase.auth.currentUser?.email ??
                                  'Not logged in',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String route,
    bool isLogout = false,
    Function()? onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout
            ? Colors.red
            : themeProvider.isDarkMode
                ? Colors.white70
                : themeProvider.gradientColors[0],
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isLogout
              ? Colors.red
              : themeProvider.isDarkMode
                  ? Colors.white
                  : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap ??
          () {
            if (isLogout) {
              Navigator.pushNamedAndRemoveUntil(
                  context, route, (Route<dynamic> route) => false);
            } else {
              Navigator.pushNamed(context, route);
            }
          },
      hoverColor: themeProvider.isDarkMode
          ? Colors.grey.shade800
          : Colors.grey.shade200,
      tileColor:
          themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
    );
  }
}
