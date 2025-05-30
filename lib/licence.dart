import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:patroltracking/Login/onboarding.dart';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/services/api_service.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _licenseKeyController = TextEditingController();

  bool _isLoading = false;
  String? _macAddress;
  String? _uniqueKey;

  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique per device
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'Unknown'; // Unique per app install
    } else {
      return 'Unsupported';
    }
  }

  Future<void> _generateLicense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final deviceId = await getDeviceId();
      final serial = _serialController.text.trim();

      final uniqueKey = await ApiService.registerLicense(
        serialNumber: serial,
        deviceId: deviceId,
      );

      setState(() => _isLoading = false);

      if (uniqueKey != null) {
        setState(() {
          _macAddress = deviceId;
          _uniqueKey = uniqueKey;
          _licenseKeyController.text = uniqueKey;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ License registered successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ License registration failed')),
        );
      }
    }
  }

  Future<void> _activateLicense() async {
    if (_formKey.currentState!.validate() && _uniqueKey != null) {
      setState(() => _isLoading = true);

      final deviceId = await getDeviceId();
      final serial = _serialController.text.trim();

      final isAuthorized = await ApiService.validateLicense(
        serialNumber: serial,
        deviceId: deviceId,
        uniqueKey: _uniqueKey!,
      );

      setState(() => _isLoading = false);

      if (isAuthorized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ License validated successfully')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ License validation failed')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please generate a license key first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('License Activation', style: AppConstants.headingStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _serialController,
                decoration: InputDecoration(
                  labelText: 'Serial Number',
                  labelStyle: AppConstants.boldPurpleFontStyle,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter serial number'
                    : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _generateLicense,
                      child: Text(
                        'Generate License Key',
                        style: AppConstants.selectedButtonFontStyle,
                      ),
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseKeyController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'License Key (Auto-filled)',
                  labelStyle: AppConstants.boldPurpleFontStyle,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _activateLicense,
                      child: Text(
                        'Activate License',
                        style: AppConstants.selectedButtonFontStyle,
                      ),
                    ),
              if (_macAddress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'MAC ID: $_macAddress',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
