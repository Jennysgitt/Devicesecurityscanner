import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/outline_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/qr_scanner_overlay.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/device_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;
  bool _qrScanned = false;
  bool _photoCaptured = false;
  String? _scannedData;
  String? _qrHash;
  Uint8List? _capturedImage;
  DeviceModel? _scannedDevice;
  Map<String, dynamic>? _verificationResult;
  bool _isVerifying = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _qrScanned = false;
      _photoCaptured = false;
      _scannedData = null;
      _qrHash = null;
      _capturedImage = null;
      _scannedDevice = null;
      _verificationResult = null;
    });
    _scannerController.start();
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    _scannerController.stop();
  }

  Future<void> _handleQRCode(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    _stopScanning();

    try {
      final scannedData = barcode.rawValue!;
      // Parse QR data: format is "hash|device_id"
      final parts = scannedData.split('|');
      if (parts.length < 2) {
        throw Exception('Invalid QR code format');
      }

      final qrHash = parts[0];
      final deviceId = parts[1];

      // Fetch device from database
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final devices = await supabaseService.getDevices();
      final device = devices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      setState(() {
        _qrScanned = true;
        _scannedData = scannedData;
        _qrHash = qrHash;
        _scannedDevice = device;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning QR: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        _resetScan();
      }
    }
  }


  Future<void> _capturePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _photoCaptured = true;
            _capturedImage = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _verifyDevice() async {
    if (_scannedDevice == null || _capturedImage == null || _qrHash == null) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Upload captured image
      final imageBytes = _capturedImage!;
      final fileName = 'verify_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final liveImageUrl = await supabaseService.uploadImage(fileName, imageBytes);

      // Verify device with AI
      final verifyResponse = await apiService.verifyDeviceWithAI(
        deviceId: _scannedDevice!.deviceId ?? _scannedDevice!.id,
        qrHash: _qrHash!,
        liveImageUrl: liveImageUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        registeredFeatures: _scannedDevice!.features,
      );

      final status = verifyResponse['status'] as String? ?? 'suspicious';
      final aiScore = (verifyResponse['ai_score'] as num?)?.toDouble() ?? 0.0;
      final imageMatchScore = (verifyResponse['image_match_score'] as num?)?.toDouble() ?? 0.0;
      final qrValidity = verifyResponse['qr_validity'] as bool? ?? false;

      // Create verification log
      await supabaseService.createVerificationLog(
        deviceId: _scannedDevice!.id,
        officerId: authProvider.currentUser?.id,
        status: status,
        aiScore: aiScore,
        imageMatchScore: imageMatchScore,
        qrValidity: qrValidity,
        entryType: 'entry',
      );

      if (mounted) {
        setState(() {
          _verificationResult = {
            'status': status,
            'ai_score': aiScore,
            'image_match_score': imageMatchScore,
            'qr_validity': qrValidity,
            'device_info': {
              'brand': _scannedDevice!.brand,
              'model': _scannedDevice!.model,
              'serial_number': _scannedDevice!.serialNumber,
            },
          };
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying device: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _resetScan() {
    setState(() {
      _isScanning = false;
      _qrScanned = false;
      _photoCaptured = false;
      _scannedData = null;
      _qrHash = null;
      _capturedImage = null;
      _scannedDevice = null;
      _verificationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Scan Device',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_verificationResult != null) {
      return _buildVerificationResult();
    }

    if (_photoCaptured) {
      return _buildVerificationPrompt();
    }

    if (_qrScanned) {
      return _buildPhotoCapturePrompt();
    }

    return _buildScannerView();
  }

  Widget _buildScannerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'QR Code Scanner',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Position the QR code within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 40),
          // Camera Preview Area
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryBlue,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: _isScanning
                  ? Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _handleQRCode,
                        ),
                        // Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: ShapeDecoration(
                              shape: QrScannerOverlayShape(
                                borderColor: AppTheme.primaryBlue,
                                borderRadius: 12,
                                borderLength: 30,
                                borderWidth: 3,
                                cutOutSize: 250,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 80,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Ready to scan',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
          if (!_isScanning)
            GradientButton(
              text: 'Start Scanning',
              icon: Icons.play_arrow,
              onPressed: _startScanning,
            )
          else
            OutlineButton(
              text: 'Stop Scanning',
              icon: Icons.stop,
              onPressed: _stopScanning,
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoCapturePrompt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: 16),
                const Text(
                  'QR Code Scanned!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Device ID: ${_scannedData ?? "N/A"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Capture Device Photo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo of the device to verify',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _capturedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      _capturedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Camera Preview',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          GradientButton(
            text: 'Capture Photo',
            icon: Icons.camera_alt,
            onPressed: _capturePhoto,
          ),
          const SizedBox(height: 16),
          OutlineButton(
            text: 'Scan Again',
            icon: Icons.refresh,
            onPressed: _resetScan,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVerificationPrompt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (_capturedImage != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _capturedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 32),
          const Text(
            'Ready to Verify',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify this device using AI matching',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 40),
          GradientButton(
            text: 'Verify Device',
            icon: Icons.verified_user,
            isLoading: _isVerifying,
            onPressed: _isVerifying ? null : _verifyDevice,
          ),
          const SizedBox(height: 16),
          OutlineButton(
            text: 'Start Over',
            icon: Icons.refresh,
            onPressed: _resetScan,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVerificationResult() {
    final status = _verificationResult!['status'] as String;
    final aiScore = (_verificationResult!['ai_score'] as num?)?.toDouble() ?? 0.0;
    final deviceInfo = _verificationResult!['device_info'] as Map<String, dynamic>;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'verified':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Verified';
        break;
      case 'suspicious':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.warning;
        statusText = 'Suspicious';
        break;
      case 'blocked':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.block;
        statusText = 'Blocked';
        break;
      default:
        statusColor = AppTheme.textMedium;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Status Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              size: 60,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 32),
          // Device Info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Brand', deviceInfo['brand'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Model', deviceInfo['model'] ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Serial Number', deviceInfo['serial_number'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // AI Score
          GlassCard(
            child: Column(
              children: [
                const Text(
                  'AI Confidence Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${aiScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Action Buttons
          if (status == 'verified')
            GradientButton(
              text: 'Allow Entry',
              icon: Icons.check,
              onPressed: () {
                // TODO: Handle allow entry
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry allowed'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
            )
          else
            OutlineButton(
              text: 'Deny Access',
              icon: Icons.close,
              onPressed: () {
                // TODO: Handle deny access
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Access denied'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          OutlineButton(
            text: 'Scan Another Device',
            icon: Icons.qr_code_scanner,
            onPressed: _resetScan,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textMedium,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
