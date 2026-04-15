import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app.dart';
import '../i18n/app_localizations.dart';

/// QR code scanner that reads a member's digital CBHI card.
/// Extracts the householdCode / membershipId from the QR payload
/// and returns it to the caller so the verify or claim screens
/// can be pre-populated automatically.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _scanned = true);
    _controller.stop();

    // FIX QW-2: Use proper jsonDecode instead of fragile regex extraction.
    // The QR payload is a signed token whose body is base64url-encoded JSON.
    // Format: header.body.signature  — body contains the card payload JSON.
    String? membershipId;
    String? householdCode;
    try {
      // Try direct JSON parse first (plain JSON QR codes)
      final jsonStart = raw.indexOf('{');
      if (jsonStart >= 0) {
        final jsonStr = raw.substring(jsonStart);
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        householdCode = decoded['householdCode']?.toString();
        membershipId = decoded['membershipId']?.toString();
      } else {
        // JWT-style token: header.body.signature
        final parts = raw.split('.');
        if (parts.length == 3) {
          // Pad base64url to valid base64
          String padded = parts[1];
          while (padded.length % 4 != 0) {
            padded += '=';
          }
          final bodyJson = utf8.decode(
            base64Url.decode(padded.replaceAll('-', '+').replaceAll('_', '/')),
          );
          final decoded = jsonDecode(bodyJson) as Map<String, dynamic>;
          householdCode = decoded['householdCode']?.toString();
          membershipId = decoded['membershipId']?.toString();
        }
      }
    } catch (_) {
      // Parsing failed — return raw value so caller can handle gracefully
    }

    if (mounted) {
      Navigator.of(context).pop(QrScanResult(
        raw: raw,
        householdCode: householdCode,
        membershipId: membershipId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('scanMemberCard')),
        backgroundColor: kSidebarBg,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, state, __) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: _controller.toggleTorch,
            tooltip: strings.t('toggleFlash'),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with scan frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: kAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Instruction text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  strings.t('pointCameraAtCard'),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (_scanned)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: kAccent),
              ),
            ),
        ],
      ),
    );
  }
}

class QrScanResult {
  const QrScanResult({
    required this.raw,
    this.householdCode,
    this.membershipId,
  });

  final String raw;
  final String? householdCode;
  final String? membershipId;
}
