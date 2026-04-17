import 'package:flutter/material.dart';
import 'package:desktop_search_a_holic/healsearch_branding.dart';
import 'package:desktop_search_a_holic/auto_backup_service.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      // Small delay to ensure the widget tree is fully built
      await Future.delayed(const Duration(milliseconds: 1500));

      // Initialize auto backup service after the app is properly mounted
      if (mounted) {
        await AutoBackupService().initialize();
      }
    } catch (e) {
      print('Failed to initialize auto backup service: $e');
      // Continue with app initialization even if backup service fails
    } finally {
      // Navigate to next screen regardless of initialization success
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2), () {});
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HealSearchBranding(
              logoSize: 180,
              titleSize: 36,
              subtitleSize: 18,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 40,
              height: 40,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
