import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSuccess,
    required this.role,
  });

  final VoidCallback onSuccess;
  final String role;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            Colors.white, // Google requires a white background for this button
        foregroundColor: Colors.black87,
        side: const BorderSide(color: AppColors.border, width: 1.2),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogoVector(size: 22),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
    );
  }
}

/// A perfectly drawn Google "G" logo that scales infinitely.
class GoogleLogoVector extends StatelessWidget {
  final double size;
  const GoogleLogoVector({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;

    // Official Google Brand Hex Colors
    final red = const Color(0xFFEA4335);
    final blue = const Color(0xFF4285F4);
    final green = const Color(0xFF34A853);
    final yellow = const Color(0xFFFBBC05);

    // Scaling factor based on the SVG's 48x48 viewBox
    final scale = size.width / 48.0;

    // Top Red arc
    paint.color = red;
    canvas.drawPath(
      Path()
        ..moveTo(24.0 * scale, 9.5 * scale)
        ..cubicTo(
          30.5 * scale,
          9.5 * scale,
          35.3 * scale,
          12.3 * scale,
          38.0 * scale,
          14.8 * scale,
        )
        ..lineTo(43.2 * scale, 9.6 * scale)
        ..cubicTo(
          38.5 * scale,
          5.2 * scale,
          31.9 * scale,
          2.5 * scale,
          24.0 * scale,
          2.5 * scale,
        )
        ..cubicTo(
          14.6 * scale,
          2.5 * scale,
          6.5 * scale,
          7.9 * scale,
          2.5 * scale,
          15.8 * scale,
        )
        ..lineTo(8.7 * scale, 20.6 * scale)
        ..cubicTo(
          10.8 * scale,
          14.1 * scale,
          16.8 * scale,
          9.5 * scale,
          24.0 * scale,
          9.5 * scale,
        )
        ..close(),
      paint,
    );

    // Right Blue arc
    paint.color = blue;
    canvas.drawPath(
      Path()
        ..moveTo(46.5 * scale, 24.5 * scale)
        ..cubicTo(
          46.5 * scale,
          22.8 * scale,
          46.4 * scale,
          21.2 * scale,
          46.1 * scale,
          19.6 * scale,
        )
        ..lineTo(24.0 * scale, 19.6 * scale)
        ..lineTo(24.0 * scale, 29.1 * scale)
        ..lineTo(36.7 * scale, 29.1 * scale)
        ..cubicTo(
          36.1 * scale,
          32.4 * scale,
          34.2 * scale,
          35.2 * scale,
          31.4 * scale,
          37.1 * scale,
        )
        ..lineTo(37.3 * scale, 41.7 * scale)
        ..cubicTo(
          42.6 * scale,
          36.8 * scale,
          46.5 * scale,
          30.2 * scale,
          46.5 * scale,
          24.5 * scale,
        )
        ..close(),
      paint,
    );

    // Bottom Green arc
    paint.color = green;
    canvas.drawPath(
      Path()
        ..moveTo(24.0 * scale, 46.5 * scale)
        ..cubicTo(
          31.9 * scale,
          46.5 * scale,
          38.5 * scale,
          43.9 * scale,
          43.2 * scale,
          39.4 * scale,
        )
        ..lineTo(37.3 * scale, 34.8 * scale)
        ..cubicTo(
          34.7 * scale,
          36.6 * scale,
          31.4 * scale,
          37.5 * scale,
          24.0 * scale,
          37.5 * scale,
        )
        ..cubicTo(
          16.8 * scale,
          37.5 * scale,
          10.8 * scale,
          32.9 * scale,
          8.7 * scale,
          26.4 * scale,
        )
        ..lineTo(2.5 * scale, 31.2 * scale)
        ..cubicTo(
          6.5 * scale,
          39.1 * scale,
          14.6 * scale,
          46.5 * scale,
          24.0 * scale,
          46.5 * scale,
        )
        ..close(),
      paint,
    );

    // Left Yellow arc
    paint.color = yellow;
    canvas.drawPath(
      Path()
        ..moveTo(2.5 * scale, 31.2 * scale)
        ..cubicTo(
          1.9 * scale,
          29.3 * scale,
          1.5 * scale,
          26.7 * scale,
          1.5 * scale,
          24.5 * scale,
        )
        ..cubicTo(
          1.5 * scale,
          22.3 * scale,
          1.9 * scale,
          19.7 * scale,
          2.5 * scale,
          17.8 * scale,
        )
        ..lineTo(8.7 * scale, 22.6 * scale)
        ..cubicTo(
          8.5 * scale,
          24.1 * scale,
          8.4 * scale,
          25.6 * scale,
          8.4 * scale,
          27.5 * scale,
        )
        ..cubicTo(
          8.4 * scale,
          28.4 * scale,
          8.5 * scale,
          29.9 * scale,
          8.7 * scale,
          31.4 * scale,
        )
        ..lineTo(2.5 * scale, 31.2 * scale)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
