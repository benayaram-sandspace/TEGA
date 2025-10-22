import 'package:flutter/material.dart';
import '../services/fingerprint_login_service.dart';

/// Fingerprint Login Button Widget
/// Provides fingerprint authentication for login
class FingerprintLoginButton extends StatefulWidget {
  final Function(String email, String password)? onLoginSuccess;
  final bool isMobile;

  const FingerprintLoginButton({
    super.key,
    this.onLoginSuccess,
    this.isMobile = true,
  });

  @override
  State<FingerprintLoginButton> createState() => _FingerprintLoginButtonState();
}

class _FingerprintLoginButtonState extends State<FingerprintLoginButton>
    with TickerProviderStateMixin {
  final FingerprintLoginService _fingerprintService = FingerprintLoginService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkAvailability();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    try {
      final isAvailable = await _fingerprintService.isFingerprintAvailable();
      final hasCredentials = await _fingerprintService.hasSavedCredentials();

      setState(() {
        _isAvailable = isAvailable && hasCredentials;
      });
    } catch (e) {}
  }

  Future<void> _handleFingerprintLogin() async {
    if (_isLoading) return;

    // Guard: require saved credentials before attempting fingerprint login
    final hasCreds = await _fingerprintService.hasSavedCredentials();
    if (!hasCreds) {
      _showErrorMessage('No saved credentials available for fingerprint login');
      // Also refresh availability to hide the button if needed
      await _checkAvailability();
      return;
    }

    setState(() => _isLoading = true);
    _animationController.forward();

    try {
      final credential = await _fingerprintService.loginWithFingerprint();

      if (credential != null) {
        widget.onLoginSuccess?.call(credential.email, credential.password);
        _showSuccessMessage('Login successful with fingerprint!');
      } else {
        _showErrorMessage('Fingerprint authentication failed');
      }
    } catch (e) {
      _showErrorMessage('Error during fingerprint login: $e');
    } finally {
      setState(() => _isLoading = false);
      _animationController.reverse();
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: widget.isMobile ? 56 : 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _handleFingerprintLogin,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.fingerprint,
                          color: Colors.white,
                          size: 24,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _isLoading
                            ? 'Authenticating...'
                            : 'Login with Fingerprint',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
