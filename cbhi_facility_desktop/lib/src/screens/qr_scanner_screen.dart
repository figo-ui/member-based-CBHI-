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

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
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

    String? membershipId;
    String? householdCode;
    try {
      final jsonStart = raw.indexOf('{');
      if (jsonStart >= 0) {
        final jsonStr = raw.substring(jsonStart);
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        householdCode = decoded['householdCode']?.toString();
        membershipId = decoded['membershipId']?.toString();
      } else {
        final parts = raw.split('.');
        if (parts.length == 3) {
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

  Future<void> _showManualEntryDialog() async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('enterManually')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: strings.t('manualEntryHint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      Navigator.of(context).pop(QrScanResult(
        raw: result,
        membershipId: result,
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
          // Overlay with scan frame + animated scan line
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kAccent, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  // Animated scan line
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (_, __) => Positioned(
                      top: 8 + (_scanLineAnimation.value * 244),
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: kAccent.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: kAccent.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Instruction text + manual entry button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _showManualEntryDialog,
                  child: Text(
                    strings.t('enterManually'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
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
