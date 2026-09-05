import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import 'package:obscura/Components/PasswordField.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  Future<void> setPasscode(String code) async {
    await _storage.write(key: 'unlock_code', value: code);
  }

  Future<bool> hasPasscode() async {
    final v = await _storage.read(key: 'unlock_code');
    return v != null && v.isNotEmpty;
  }

  Future<bool> verifyPasscode(String code) async {
    final storedCode = await _storage.read(key: 'unlock_code');
    if (storedCode == null) return false;
    return storedCode == code;
  }

  // Try biometric auth first; if not available or authentication fails,
  // fall back to passcode entry UI (requires BuildContext).
  Future<bool> authenticate(BuildContext context) async {
    try {
      final bioOk = await _authenticateBiometrics();
      if (bioOk) return true;
    } catch (e, st) {
      developer.log('Biometric attempt failed: $e\n$st');
      // continue to passcode fallback
    }

    // biometric not available or failed -> prompt passcode
    final pcOk = await _promptPasscode(context);
    return pcOk;
  }

  // Try biometric authentication, return true if success, false otherwise.
  Future<bool> _authenticateBiometrics() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      bool canCheckBiometrics = false;
      try {
        canCheckBiometrics = await _auth.canCheckBiometrics;
      } catch (e) {
        developer.log('canCheckBiometrics error: $e');
        canCheckBiometrics = false;
      }

      // if neither supported nor biometrics available, shortcut false
      if (!isDeviceSupported && !canCheckBiometrics) return false;

      final res = await _auth.authenticate(localizedReason: 'Authenticate to unlock');
      return res;
    } catch (e, st) {
      developer.log('Biometric auth exception: $e\n$st');
      return false;
    }
  }

  // Prompt user for passcode. If no passcode exists, allow user to set one.
  // Returns true if passcode verified (or newly set), false otherwise.
  Future<bool> _promptPasscode(BuildContext context) async {
    final hasPc = await hasPasscode();

    if (!hasPc) {
      // Ask user to set a passcode (optional)
      final controller = TextEditingController();
      final confirmedController = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final set = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set a passcode'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PasswordField(
                    controller: controller,
                    label: 'New passcode',
                    allowEmpty: false),
                const SizedBox(height: 8),
                PasswordField(
                    controller: confirmedController,
                    label: 'Confirm passcode',
                    allowEmpty: false),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Skip')),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (controller.text != confirmedController.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Passcodes do not match')));
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Set'),
            ),
          ],
        ),
      );

      if (set == true) {
        await setPasscode(controller.text);
        return true;
      }
      return false;
    }

    // Has passcode -> prompt to enter
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final entered = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter passcode'),
        content: Form(
          key: formKey,
          child: PasswordField(
              controller: ctrl, label: 'Passcode', allowEmpty: false),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop(ctrl.text);
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (entered == null) return false;
    final ok = await verifyPasscode(entered);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Incorrect passcode')));
    }
    return ok;
  }
}
