import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrPairingPage extends StatefulWidget {
  const QrPairingPage({super.key});

  @override
  State<QrPairingPage> createState() => _QrPairingPageState();
}

class _QrPairingPageState extends State<QrPairingPage> {
  final _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handled = false;
  Future<PermissionStatus>? _permissionFuture;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    _permissionFuture = Permission.camera.status;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<PermissionStatus>(
        future: _permissionFuture,
        builder: (context, snapshot) {
          final status = snapshot.data;
          if (status == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!status.isGranted && !_permissionRequested) {
            return _CameraPermissionPrompt(onAllow: _retryPermission);
          }

          if (!status.isGranted) {
            return _CameraDenied(onRetry: _retryPermission);
          }

          return Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _handleDetect,
                placeholderBuilder: (context) {
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error) {
                  return _ScannerError(message: error.toString());
                },
              ),
              const _ScannerOverlay(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton.filledTonal(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    _handled = true;
    Navigator.pop(context, rawValue);
  }

  void _retryPermission() {
    setState(() {
      _permissionFuture = _requestPermission();
    });
  }

  Future<PermissionStatus> _requestPermission() async {
    _permissionRequested = true;
    final status = await Permission.camera.request();
    return status;
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _CameraPermissionPrompt extends StatelessWidget {
  const _CameraPermissionPrompt({required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.camera, color: Colors.white, size: 44),
            const SizedBox(height: 14),
            const Text(
              'Izinkan kamera untuk scan QR TV?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamera hanya dipakai untuk membaca QR pairing dari layar Marlin Cast TV.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAllow,
              icon: const Icon(LucideIcons.camera),
              label: const Text('Izinkan Kamera'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti Saja'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Scan QR Code di layar Marlin Cast TV Anda',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraDenied extends StatelessWidget {
  const _CameraDenied({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.cameraOff, color: Colors.white, size: 40),
            const SizedBox(height: 14),
            const Text(
              'Izin kamera dibutuhkan untuk scan QR TV.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
