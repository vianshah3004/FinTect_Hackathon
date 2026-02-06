import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/auth_service.dart';

/// PIN Setup and Local Auth Screen
class LocalAuthScreen extends StatefulWidget {
  final bool isSetup;
  
  const LocalAuthScreen({super.key, this.isSetup = false});

  @override
  State<LocalAuthScreen> createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isConfirming = false;
  String? _errorMessage;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _authService.init();
  }

  Future<void> _setupPin() async {
    final pin = _pinController.text.trim();
    
    if (pin.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits');
      return;
    }
    
    if (!_isConfirming) {
      setState(() {
        _isConfirming = true;
        _errorMessage = null;
      });
      return;
    }
    
    final confirmPin = _confirmPinController.text.trim();
    if (pin != confirmPin) {
      setState(() => _errorMessage = 'PINs do not match');
      return;
    }
    
    setState(() => _isLoading = true);
    
    await _authService.savePin(pin);
    
    if (mounted) {
      context.go('/language');
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    
    if (pin.length < 4) {
      setState(() => _errorMessage = 'Please enter your PIN');
      return;
    }
    
    setState(() => _isLoading = true);
    
    final isValid = await _authService.verifyPin(pin);
    
    if (isValid) {
      await _authService.updateLastAuth();
      if (mounted) {
        context.go('/home');
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetupMode = widget.isSetup;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isSetupMode ? Icons.lock_outline : Icons.lock,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                isSetupMode
                    ? (_isConfirming ? 'Confirm Your PIN' : 'Set Up App Lock')
                    : 'Enter PIN',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSetupMode
                    ? 'Create a 4-6 digit PIN to secure your app'
                    : 'Enter your PIN to continue',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // PIN Input
              TextField(
                controller: _isConfirming ? _confirmPinController : _pinController,
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '● ● ● ●',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textLight,
                    ),
                    onPressed: () {
                      setState(() => _obscurePin = !_obscurePin);
                    },
                  ),
                ),
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Action button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (isSetupMode ? _setupPin : _verifyPin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isSetupMode
                              ? (_isConfirming ? 'Confirm PIN' : 'Continue')
                              : 'Unlock',
                          style: AppTypography.buttonText,
                        ),
                ),
              ),
              
              if (isSetupMode && _isConfirming) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isConfirming = false;
                      _confirmPinController.clear();
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Go Back'),
                ),
              ],
              
              if (!isSetupMode) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    // Use biometric if available
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric authentication coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Fingerprint'),
                ),
              ],
              
              const SizedBox(height: 60),
              
              // Keypad (optional visual enhancement)
              _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (int i = 1; i <= 9; i++)
          _buildKeypadButton(i.toString()),
        _buildKeypadButton('', icon: Icons.fingerprint),
        _buildKeypadButton('0'),
        _buildKeypadButton('', icon: Icons.backspace_outlined, isBackspace: true),
      ],
    );
  }

  Widget _buildKeypadButton(String digit, {IconData? icon, bool isBackspace = false}) {
    return InkWell(
      onTap: () {
        if (isBackspace) {
          final controller = _isConfirming ? _confirmPinController : _pinController;
          if (controller.text.isNotEmpty) {
            controller.text = controller.text.substring(0, controller.text.length - 1);
          }
        } else if (digit.isNotEmpty) {
          final controller = _isConfirming ? _confirmPinController : _pinController;
          if (controller.text.length < 6) {
            controller.text += digit;
          }
        } else if (icon == Icons.fingerprint) {
          // Biometric placeholder
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 28, color: AppColors.primary)
              : Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
