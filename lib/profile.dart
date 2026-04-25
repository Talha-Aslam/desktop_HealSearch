import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desktop_search_a_holic/theme_provider.dart';
import 'package:desktop_search_a_holic/sidebar.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _pharmacyNameController = TextEditingController();
  final TextEditingController _pharmacyIdController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyIdController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfile(showLoading: false);
    }
  }

  void _showMessage(
    String message, {
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
      ),
    );
  }

  String _readProfileName(Map<String, dynamic>? profile, String fallback) {
    if (profile == null) return fallback;

    final fullName = profile['full_name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName;
    }

    final name = profile['name'];
    if (name is String && name.trim().isNotEmpty) {
      return name;
    }

    return fallback;
  }

  String _readProfilePhone(Map<String, dynamic>? profile, String fallback) {
    if (profile == null) return fallback;

    final phone = profile['phone'];
    if (phone is String && phone.trim().isNotEmpty) {
      return phone;
    }

    return fallback;
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No logged-in user');
      }

      final profile = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final pharmacyId = profile?['pharmacy_id'] as String?;
      Map<String, dynamic>? pharmacy;

      if (pharmacyId != null) {
        pharmacy = await _supabase
            .from('pharmacies')
            .select('name')
            .eq('id', pharmacyId)
            .maybeSingle();
      }

      if (!mounted) return;

      setState(() {
        _emailController.text = user.email ?? '';
        _fullNameController.text = _readProfileName(
          profile,
          user.userMetadata?['name']?.toString() ??
              user.userMetadata?['full_name']?.toString() ??
              '',
        );
        _roleController.text = (profile?['role'] as String?) ?? 'owner';
        _pharmacyIdController.text = pharmacyId ?? '';
        _pharmacyNameController.text = (pharmacy?['name'] as String?) ?? '';
        _phoneController.text = _readProfilePhone(
          profile,
          user.userMetadata?['phone']?.toString() ?? '',
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showMessage(
        'Failed to load profile: $e',
        color: Colors.red,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Invalid profile session', color: Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final trimmedName = _fullNameController.text.trim();
      final trimmedPhone = _phoneController.text.trim();

      bool nameSaved = false;
      bool phoneSaved = false;

      // Try modern schema first: user_profiles(name, phone)
      try {
        await _supabase.from('user_profiles').update({
          'name': trimmedName,
          'phone': trimmedPhone,
        }).eq('id', user.id);
        nameSaved = true;
        phoneSaved = true;
      } catch (_) {
        // Fall through to granular updates.
      }

      // Legacy/fallback name column handling.
      if (!nameSaved && trimmedName.isNotEmpty) {
        try {
          await _supabase
              .from('user_profiles')
              .update({'name': trimmedName}).eq('id', user.id);
          nameSaved = true;
        } catch (_) {
          try {
            await _supabase
                .from('user_profiles')
                .update({'full_name': trimmedName}).eq('id', user.id);
            nameSaved = true;
          } catch (_) {
            // Ignore and use metadata fallback.
          }
        }
      }

      // User-level phone field handling.
      if (!phoneSaved) {
        try {
          await _supabase
              .from('user_profiles')
              .update({'phone': trimmedPhone}).eq('id', user.id);
          phoneSaved = true;
        } catch (_) {
          // Ignore and use metadata fallback.
        }
      }

      // Always try metadata sync (works even when profile RLS is strict).
      bool metadataUpdated = false;
      try {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'name': trimmedName, 'phone': trimmedPhone}),
        );
        metadataUpdated = true;
      } catch (_) {
        // Ignore metadata sync errors.
      }

      if (!nameSaved && !phoneSaved && !metadataUpdated) {
        throw Exception(
          'Could not update profile data. Check user_profiles columns and RLS policies.',
        );
      }

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if ((!nameSaved || !phoneSaved) && metadataUpdated) {
        _showMessage(
          'Saved to user metadata. To persist in user_profiles table, update RLS/columns.',
          color: Colors.orange,
          duration: const Duration(seconds: 5),
        );
      } else {
        _showMessage('Profile updated successfully', color: Colors.green);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to save profile: $e',
          color: Colors.red, duration: const Duration(seconds: 4));
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
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _isLoading ? null : () => _loadProfile(showLoading: false),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
            tooltip: _isEditing ? 'Cancel' : 'Edit',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Container(
              color: themeProvider.scaffoldBackgroundColor,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: themeProvider.gradientColors[0]),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Card(
                            color: themeProvider.cardBackgroundColor,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildProfileField(
                                    label: 'Full Name',
                                    controller: _fullNameController,
                                    icon: Icons.person,
                                    editable: _isEditing,
                                  ),
                                  const Divider(),
                                  _buildProfileField(
                                    label: 'Email',
                                    controller: _emailController,
                                    icon: Icons.email,
                                    editable: false,
                                  ),
                                  const Divider(),
                                  _buildProfileField(
                                    label: 'Phone',
                                    controller: _phoneController,
                                    icon: Icons.phone,
                                    editable: _isEditing,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const Divider(),
                                  _buildProfileField(
                                    label: 'Role',
                                    controller: _roleController,
                                    icon: Icons.badge,
                                    editable: false,
                                  ),
                                  const Divider(),
                                  _buildProfileField(
                                    label: 'Pharmacy Name',
                                    controller: _pharmacyNameController,
                                    icon: Icons.local_pharmacy,
                                    editable: false,
                                  ),
                                  const Divider(),
                                  _buildProfileField(
                                    label: 'Pharmacy ID',
                                    controller: _pharmacyIdController,
                                    icon: Icons.key,
                                    editable: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_isEditing)
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _saveProfile,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                    _isLoading ? 'Saving...' : 'Save Changes'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      themeProvider.gradientColors[0],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool editable,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: themeProvider.gradientColors[0]),
          const SizedBox(width: 12),
          Expanded(
            child: editable
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: TextStyle(color: themeProvider.textColor),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(
                          color: themeProvider.textColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: themeProvider.isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            color: themeProvider.textColor.withOpacity(0.7),
                            fontSize: 12,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        controller.text.isEmpty ? '-' : controller.text,
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
