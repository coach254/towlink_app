import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../auth/welcome_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key, required this.driverId});

  final int driverId;

  Future<void> _logout(BuildContext context) async {
    await SessionService.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 72,
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Driver Home',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Signed in as driver ID $driverId.\n'
                  'The dashboard will live here in Drop 2.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}