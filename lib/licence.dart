import 'package:flutter/material.dart';
import 'package:patroltracking/Login/onboarding.dart';
import 'package:patroltracking/constants.dart';
import 'package:network_info_plus/network_info_plus.dart';

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

  Future<void> _submitLicense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate API delay or local verification
      await Future.delayed(const Duration(seconds: 2));

      // ✅ Get MAC address
      final info = NetworkInfo();
      String? mac = await info.getWifiBSSID(); // or getWifiIP(), getWifiName()
      setState(() {
        _macAddress = mac ?? "Unavailable";
        _isLoading = false;
      });

      // TODO: Replace this with actual license validation or storage logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('License validated! MAC ID: $_macAddress')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'License Activation',
          style: AppConstants.headingStyle,
        ),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter serial number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseKeyController,
                decoration: InputDecoration(
                  labelText: 'License Key',
                  labelStyle: AppConstants.boldPurpleFontStyle,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 10) {
                    return 'Enter a valid license key';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitLicense,
                      child: Text(
                        'Activate License',
                        style: AppConstants.selectedButtonFontStyle,
                      ),
                    ),
              if (_macAddress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text('MAC ID: $_macAddress',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
