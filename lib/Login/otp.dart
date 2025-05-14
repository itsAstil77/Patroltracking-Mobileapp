import 'package:flutter/material.dart';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/patrol/patroldashboard.dart';
import 'package:patroltracking/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpScreen extends StatefulWidget {
  final String username;
  const OtpScreen({super.key, required this.username});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpControllers = List.generate(4, (index) => TextEditingController());
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final otpCode = _otpControllers.map((c) => c.text).join();

      final result = await ApiService.verifyOtp(
        username: widget.username,
        otp: otpCode,
      );

      setState(() => _isLoading = false);

      final response = result['body'];

      if (result['status'] == 200 && response['success'] == true) {
        final token = response['token'];
        final user = response['user'];

        // final patrolId = user['id'];
        // final name = user['patrolGuardName'];
        // final mobileNumber = user['mobileNumber'];
        // final email = user['email'];
        // final company = user['companyCode'];
        // final image = user['imageUrl'];
        // final role = user['role'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Login successful!',
              style: AppConstants.normalWhiteFontStyle,
            ),
          ),
        );

        // if ((response['user']['role'] ?? '').toLowerCase() == 'admin') {
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) =>
        //           AdminDashboardScreen(username: widget.username),
        //     ),
        //   );
        // } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => PatrolDashboardScreen(
                    token: token,
                    userdata: user,
                  )),
        );
        // }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'OTP verification failed.',
              style: AppConstants.normalWhiteFontStyle,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('OTP Verification', style: AppConstants.headingStyle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Enter the 4-digit OTP sent to your mobile number',
              style: AppConstants.normalFontStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            Form(
              key: _formKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60.0,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppConstants.normalBoldFontStyle,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? '!' : null,
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24.0),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: AppConstants.fontColorWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text('Verify OTP',
                          style: AppConstants.notSelectedButtonFontStyle),
                    ),
                  ),
            const SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Resend OTP clicked',
                      style: AppConstants.normalWhiteFontStyle,
                    ),
                  ),
                );
              },
              child: Text('Resend OTP',
                  style: AppConstants.selectedButtonFontStyle),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
