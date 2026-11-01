import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../driver/driver_home_screen.dart';
import 'widgets/google_sign_in_button.dart';
import '../../services/auth_service.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  static const String baseUrl = 'http://10.0.2.2:8765';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController(text: 'Flatbed truck');
  final _registrationController = TextEditingController();

  // THIS WAS MISSING
  final _authService = AuthService();

  bool _loading = false;
  bool _registerMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_registerMode) {
        // Register new driver
        final response = await http
            .post(
          Uri.parse('$baseUrl/drivers'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'vehicle_type': _vehicleTypeController.text.trim(),
            'vehicle_registration': _registrationController.text.trim(),
          }),
        )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 201) {
          final driver = jsonDecode(response.body) as Map<String, dynamic>;
          await _saveAndGo(
            driverId: driver['id'] as int,
            name: driver['full_name'] as String,
            phone: driver['phone'] as String,
          );
        } else {
          _showError(_extractError(response.body));
        }
      } else {
        // Login by phone — look up in drivers list
        final response = await http
            .get(Uri.parse('$baseUrl/drivers'))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          _showError('Could not reach TowLink.');
          return;
        }

        final list = jsonDecode(response.body) as List<dynamic>;
        final phone = _phoneController.text.trim();
        final match = list.firstWhere(
              (d) => d['phone'] == phone,
          orElse: () => null,
        );

        if (match == null) {
          _showError(
            'No driver found with that phone number. '
                'Tap "Create driver account" to register.',
          );
        } else {
          await _saveAndGo(
            driverId: match['id'] as int,
            name: match['full_name'] as String,
            phone: match['phone'] as String,
          );
        }
      }
    } catch (_) {
      _showError('Could not connect. Check the backend is running.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAndGo({
    required int driverId,
    required String name,
    required String phone,
  }) async {
    await SessionService.saveSession(
      role: UserRole.driver,
      phone: phone,
      name: name,
      driverId: driverId,
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DriverHomeScreen(driverId: driverId)),
          (_) => false,
    );
  }

  String _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded['detail']?.toString() ?? 'Something went wrong.';
    } catch (_) {
      return 'Something went wrong.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Login'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.chipEnRoute,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.accentDark,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Sign in to accept towing jobs and manage '
                              'your active trips.',
                          style: TextStyle(
                            color: AppColors.accentDark,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  _registerMode ? 'Create driver account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _registerMode
                      ? 'Register your vehicle and start earning.'
                      : 'Enter your phone number to continue.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_registerMode)
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return 'Please enter your name.';
                      if (text.length < 2) return 'Name is too short.';
                      return null;
                    },
                  ),
                if (_registerMode) const SizedBox(height: AppSpacing.lg),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Please enter your phone number.';
                    }
                    if (text.length < 7) return 'Phone is too short.';
                    return null;
                  },
                ),

                if (_registerMode) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _vehicleTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle type',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _registrationController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle registration (e.g. GR-1234-22)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : Text(_registerMode ? 'Create account' : 'Sign in'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                    setState(() {
                      _registerMode = !_registerMode;
                    });
                  },
                  child: Text(
                    _registerMode
                        ? 'Already registered? Sign in'
                        : 'New driver? Create driver account',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _OrDivider(),
                const SizedBox(height: AppSpacing.lg),
                GoogleSignInButton(
                  role: 'driver',
                  onSuccess: () {
                    // For now, this just logs them in. We'll link it to Firestore next.
                    _saveAndGo(
                      driverId: 1,
                      name: 'Google Driver',
                      phone: _authService.currentUser?.phoneNumber ?? 'Google Phone',
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}