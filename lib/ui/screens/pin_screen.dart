import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import 'main_shell.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isSettingPin = false;
  bool _isConfirming = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _isSettingPin = !auth.isPinSet;
  }

  void _onKeyPress(String key) {
    setState(() {
      _error = '';
      if (key == '<') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < 4) _pin += key;
      }

      if (_pin.length == 4) {
        _processPin();
      }
    });
  }

  void _processPin() {
    final auth = context.read<AuthService>();
    
    if (_isSettingPin) {
      if (!_isConfirming) {
        _confirmPin = _pin;
        _pin = '';
        _isConfirming = true;
      } else {
        if (_pin == _confirmPin) {
          auth.setPin(_pin);
          _goToHome();
        } else {
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
          _error = 'PINs do not match. Try again.';
        }
      }
    } else {
      if (auth.verifyPin(_pin)) {
        _goToHome();
      } else {
        _pin = '';
        _error = 'Incorrect PIN';
      }
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = _isSettingPin 
        ? (_isConfirming ? 'Confirm PIN' : 'Set 4-Digit PIN')
        : 'Enter PIN to Unlock';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.teal, size: 48),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.teal : Colors.transparent,
                    border: Border.all(color: AppColors.teal, width: 2),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.peach, fontSize: 14)),
            const SizedBox(height: 48),
            
            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (int i = 1; i <= 9; i++) _buildKey(i.toString()),
                  const SizedBox(),
                  _buildKey('0'),
                  _buildKey('<'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: val == '<' 
              ? const Icon(Icons.backspace_outlined, color: AppColors.textPrimary)
              : Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
