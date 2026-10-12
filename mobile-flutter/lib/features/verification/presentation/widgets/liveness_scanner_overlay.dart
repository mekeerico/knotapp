import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class LivenessScannerOverlay extends StatefulWidget {
  final Function(String path) onSelfieCaptured;

  const LivenessScannerOverlay({
    super.key,
    required this.onSelfieCaptured,
  });

  @override
  State<LivenessScannerOverlay> createState() => _LivenessScannerOverlayState();
}

class _LivenessScannerOverlayState extends State<LivenessScannerOverlay>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  late AnimationController _laserController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _initializeFrontCamera();
  }

  Future<void> _initializeFrontCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Front camera init error: $e');
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureSelfie() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    try {
      if (_controller != null && _controller!.value.isInitialized) {
        final XFile file = await _controller!.takePicture();
        widget.onSelfieCaptured(file.path);
      } else {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
        );
        if (file != null) {
          widget.onSelfieCaptured(file.path);
        }
      }
    } catch (e) {
      debugPrint('Selfie capture error: $e');
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        widget.onSelfieCaptured(file.path);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ovalWidth = size.width * 0.72;
    final ovalHeight = ovalWidth * 1.35;

    return Stack(
      children: [
        // Camera Stream
        Positioned.fill(
          child: _isInitialized && _controller != null
              ? CameraPreview(_controller!)
              : Container(
                  color: AppColors.obsidianBlack,
                  child: Center(
                    child: Icon(
                      Icons.face,
                      size: 96,
                      color: AppColors.champagneGold.withOpacity(0.5),
                    ),
                  ),
                ),
        ),

        // Dark Translucent Mask with Cutout
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Container(
                      width: ovalWidth,
                      height: ovalHeight,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.elliptical(150, 200)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Oval Gold Border Guide
        Center(
          child: Container(
            width: ovalWidth,
            height: ovalHeight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.elliptical(150, 200)),
              border: Border.all(
                color: AppColors.champagneGold,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.champagneGold.withOpacity(0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated Vertical Laser Beam
                AnimatedBuilder(
                  animation: _laserController,
                  builder: (context, child) {
                    final topOffset = _laserController.value * (ovalHeight - 20);
                    return Positioned(
                      top: topOffset,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppColors.scannerGlowGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.champagneGold.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Top Status & Instructions
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Text(
                'Biometric Liveness Scan',
                style: AppTypography.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderGold, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppColors.champagneGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Align your face in the oval & hold steady',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPure,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom Capture Trigger
        Positioned(
          bottom: 40,
          left: 24,
          right: 24,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isScanning ? null : _captureSelfie,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.champagneGold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.champagneGold.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                      ),
                      child: _isScanning
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.obsidianBlack,
                                  ),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: AppColors.obsidianBlack,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Didit 1:1 Biometric Liveness Verification',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
