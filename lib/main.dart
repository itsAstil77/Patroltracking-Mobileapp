import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:patroltracking/Login/login.dart';
import 'package:patroltracking/Login/onboarding.dart';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/licence.dart';
import 'package:patroltracking/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

final ThemeData appTheme = ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: AppConstants.primaryColor,
  textTheme: TextTheme(
    bodyLarge: AppConstants.normalFontStyle,
    titleLarge: AppConstants.headingStyle,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrol Tracking',
      debugShowCheckedModeBanner: false,
      theme: appTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    await _determinePosition();

    String deviceId = await _getDeviceId();

    // Check if device is authorized
    final isAuthorized = await ApiService.checkDeviceAuthorization(deviceId);

    // Save first launch flag
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstLaunch', false);

    if (!mounted) return;

    // Navigate based on authorization status
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isAuthorized ? const LoginScreen() : const LicenseScreen(),
      ),
    );
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'UnknownIOSId';
      } else {
        return 'UnsupportedPlatform';
      }
    } catch (e) {
      print("Device ID Error: $e");
      return 'ErrorGettingDeviceId';
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.splashBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.08,
              width: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppConstants.logoImage),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
