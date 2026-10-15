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

  Future<void> _pickSelfieFromNative() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file != null) {
        widget.onSelfieCaptured(file.path);
        return;
      }
      final XFile? galleryFile = await _picker.pickImage(source: ImageSource.gallery);
      if (galleryFile != null) {
        widget.onSelfieCaptured(galleryFile.path);
      }
    } catch (e) {
      debugPrint('Native selfie picker error: $e');
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
          child: _isInitialized && _controller != null && _controller!.value.isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize?.height ?? size.width,
                      height: _controller!.value.previewSize?.width ?? size.height,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                )
              : Container(
                  color: AppColors.obsidianBlack,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(AppColors.champagneGold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Starting front camera...',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        // Dark Translucent Mask with True Oval Cutout Hole & Gold Border
        Positioned.fill(
          child: CustomPaint(
            painter: _OvalCutoutPainter(
              ovalWidth: ovalWidth,
              ovalHeight: ovalHeight,
              overlayColor: Colors.black.withValues(alpha: 0.65),
              borderColor: AppColors.champagneGold,
            ),
          ),
        ),

        // Animated Laser Beam Clipped Inside Oval Aperture
        Center(
          child: ClipOval(
            child: SizedBox(
              width: ovalWidth,
              height: ovalHeight,
              child: Stack(
                children: [
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
                                color: AppColors.champagneGold.withValues(alpha: 0.8),
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
          bottom: 30,
          left: 20,
          right: 20,
          child: Column(
            children: [
              // Phone Camera / Gallery Fallback Button
              GestureDetector(
                onTap: _pickSelfieFromNative,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardElevated.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.champagneGold.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_front_outlined, color: AppColors.champagneGold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Take Selfie via Phone Camera / Gallery',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.champagneGold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _isScanning ? null : _captureSelfie,
                child: Container(
                  width: 80,
                  height: 80,
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
              const SizedBox(height: 12),
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

class _OvalCutoutPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final Color overlayColor;
  final Color borderColor;

  _OvalCutoutPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.overlayColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // 1. Dark overlay outside the oval aperture
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final ovalPath = Path()..addOval(ovalRect);

    // Cutout hole: difference ensures the inside is completely transparent
    final cutoutPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      ovalPath,
    );

    final overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(cutoutPath, overlayPaint);

    // 2. Gold border around the oval aperture
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _OvalCutoutPainter oldDelegate) {
    return oldDelegate.ovalWidth != ovalWidth ||
        oldDelegate.ovalHeight != ovalHeight ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderColor != borderColor;
  }
}
