import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:patroltracking/constants.dart' as constants;
import 'package:patroltracking/services/api_service.dart';

enum ScanMode { qr, barcode, nfc }

class PatrolChecklistScanScreen extends StatefulWidget {
  final String checklistId;
  final String scannerlocation;
  final Map<String, dynamic> user;
  final String token;

  const PatrolChecklistScanScreen({
    super.key,
    required this.checklistId,
    required this.scannerlocation,
    required this.user,
    required this.token,
  });

  @override
  _PatrolChecklistScanScreenState createState() =>
      _PatrolChecklistScanScreenState();
}

class _PatrolChecklistScanScreenState extends State<PatrolChecklistScanScreen> {
  String? scanResult;
  ScanMode selectedScanMode = ScanMode.qr;
  final MobileScannerController scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _startScannerIfNeeded();
  }

  void _startScannerIfNeeded() {
    if (selectedScanMode == ScanMode.qr) {
      scannerController.start();
    } else {
      scannerController.stop();
    }

    if (selectedScanMode == ScanMode.nfc) {
      _startNfcScan();
    }
  }

  void _processScanResult(String result) async {
    if (scanResult != null) return;

    setState(() => scanResult = result);
    scannerController.stop();

    if (result.trim() == widget.scannerlocation.trim()) {
      try {
        final response = await ApiService.submitScan(
          scanType: selectedScanMode.name.toUpperCase(),
          checklistId: widget.checklistId,
          token: widget.token,
        );

        if (response['message'] ==
            "Scan recorded and checklist updated successfully") {
          Navigator.pop(context);
        } else {
          throw Exception("Scan failed: ${response['message']}");
        }
      } catch (e) {
        _showError(e.toString());
        scannerController.start();
        setState(() => scanResult = null);
      }
    } else {
      _showError("Invalid scan: Location mismatch.");
      scannerController.start();
      setState(() => scanResult = null);
    }
  }

  void _startNfcScan() async {
    if (scanResult != null) return;

    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      _showError("NFC not available on this device.");
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || ndef.cachedMessage == null) {
            throw Exception("Invalid or empty NFC tag.");
          }

          final record = ndef.cachedMessage!.records.first;
          final payload = record.payload;
          final languageCodeLength = payload[0] & 0x3F;
          final tagValue =
              utf8.decode(payload.sublist(1 + languageCodeLength)).trim();

          if (tagValue == widget.scannerlocation.trim()) {
            setState(() => scanResult = tagValue);
            await NfcManager.instance.stopSession();

            final response = await ApiService.submitScan(
              scanType: "NFC",
              checklistId: widget.checklistId,
              token: widget.token,
            );

            if (response['message'] ==
                "Scan recorded and checklist updated successfully") {
              if (mounted) Navigator.pop(context);
            } else {
              throw Exception("Scan failed: ${response['message']}");
            }
          } else {
            _showError("Invalid scan: Location mismatch.");
            await Future.delayed(Duration(seconds: 2));
            setState(() => scanResult = null);
          }
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: e.toString());
          _showError("Error: ${e.toString()}");
          setState(() => scanResult = null);
        }
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Widget _buildScanner() {
    switch (selectedScanMode) {
      case ScanMode.qr:
      case ScanMode.barcode:
        return MobileScanner(
          controller: scannerController,
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              if (barcode.rawValue != null) {
                _processScanResult(barcode.rawValue!);
                break;
              }
            }
          },
        );
      case ScanMode.nfc:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nfc,
                  size: 100, color: constants.AppConstants.primaryColor),
              Text("Bring device near an NFC tag",
                  style: constants.AppConstants.headingStyle),
            ],
          ),
        );
    }
  }

  Widget _buildScanOptions() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        children: [
          ChoiceChip(
            label: Text("Scanner",
                style: constants.AppConstants.boldPurpleFontStyle),
            selected: selectedScanMode == ScanMode.qr,
            onSelected: (val) {
              setState(() {
                selectedScanMode = ScanMode.qr;
                scanResult = null;
                _startScannerIfNeeded();
              });
            },
          ),
          ChoiceChip(
            label:
                Text("NFC", style: constants.AppConstants.boldPurpleFontStyle),
            selected: selectedScanMode == ScanMode.nfc,
            onSelected: (val) {
              setState(() {
                selectedScanMode = ScanMode.nfc;
                scanResult = null;
                _startScannerIfNeeded();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Scan Task", style: constants.AppConstants.headingStyle),
      ),
      body: Column(
        children: [
          _buildScanOptions(),
          Expanded(
            child: Stack(
              children: [
                _buildScanner(),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Scan / Tag against the task: ${widget.checklistId}",
                      style: constants.AppConstants.normalWhiteFontStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (scanResult != null)
                  Positioned(
                    bottom: 50,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Scanned: $scanResult",
                        style: constants.AppConstants.normalWhiteBoldFontStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
