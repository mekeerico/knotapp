import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class CameraViewfinder extends StatefulWidget {
  final String title;
  final String hintText;
  final bool isDocumentMode;
  final Function(String path) onImageCaptured;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final String? selectedDocumentType;
  final ValueChanged<String>? onDocumentTypeSelected;

  const CameraViewfinder({
    super.key,
    required this.title,
    required this.hintText,
    this.isDocumentMode = true,
    required this.onImageCaptured,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.selectedDocumentType,
    this.onDocumentTypeSelected,
  });

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final selectedCamera = widget.isDocumentMode
            ? _cameras!.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.back,
                orElse: () => _cameras!.first,
              )
            : _cameras!.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.front,
                orElse: () => _cameras!.first,
              );

        _controller = CameraController(
          selectedCamera,
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
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      if (_controller != null && _controller!.value.isInitialized) {
        final XFile file = await _controller!.takePicture();
        widget.onImageCaptured(file.path);
      } else {
        // Fallback to gallery/file picker if camera unavailable
        final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
        if (file != null) {
          widget.onImageCaptured(file.path);
        }
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        widget.onImageCaptured(file.path);
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      widget.onImageCaptured(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Camera View or High-Tech Placeholder
        Positioned.fill(
          child: _isInitialized && _controller != null
              ? CameraPreview(_controller!)
              : Container(
                  color: AppColors.obsidianBlack,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isDocumentMode ? Icons.badge_outlined : Icons.face,
                          size: 72,
                          color: AppColors.champagneGold.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ready to Capture',
                          style: AppTypography.headingMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap below to take photo or select from library',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        // Dark Vignette Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.45),
          ),
        ),

        // Responsive Foreground Layout (No Overlap between Header, Pills, Cutout Frame, and Shutter)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                // Top Header Info & Document Type Pills
                Text(
                  widget.title,
                  style: AppTypography.headingLarge.copyWith(color: AppColors.textPure),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.obsidianBlack.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGold, width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        size: 15,
                        color: AppColors.champagneGold,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.hintText,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.champagneGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDocumentTypeSelected != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildDocPill('National ID (NIN)', 'National Identity Card (NIN)'),
                      _buildDocPill("Int'l Passport", "Int'l Passport"),
                      _buildDocPill("Driver's License", "Driver's License"),
                      _buildDocPill('Residence / State ID', 'Residence Permit / State ID'),
                      _buildDocPill("Voter's Card", "Voter's Card (PVC)"),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Document Cutout Frame with Golden Corners (Expanded so it adapts to available height)
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.58, // ID card aspect ratio (85.60 mm × 53.98 mm)
                      child: Container(
                        width: size.width * 0.88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.champagneGold.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            _buildCorner(top: 0, left: 0),
                            _buildCorner(top: 0, right: 0),
                            _buildCorner(bottom: 0, left: 0),
                            _buildCorner(bottom: 0, right: 0),
                            Center(
                              child: Opacity(
                                opacity: 0.15,
                                child: Icon(
                                  Icons.credit_card,
                                  size: 96,
                                  color: AppColors.champagneGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Capture Controls
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardElevated.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.champagneGold.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.file_upload_outlined, color: AppColors.champagneGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Upload ID from Gallery / Files',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.champagneGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Centered Luxury Gold Shutter Trigger
                Center(
                  child: GestureDetector(
                    onTap: _isCapturing ? null : _capturePhoto,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.champagneGold, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.champagneGold.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                          ),
                          child: _isCapturing
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(
                                        AppColors.obsidianBlack,
                                      ),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: AppColors.obsidianBlack,
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Aligned with Didit Sovereign Trust & Security',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: AppColors.champagneGold, width: 3.5)
                : BorderSide.none,
            bottom: bottom != null
                ? const BorderSide(color: AppColors.champagneGold, width: 3.5)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: AppColors.champagneGold, width: 3.5)
                : BorderSide.none,
            right: right != null
                ? const BorderSide(color: AppColors.champagneGold, width: 3.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDocPill(String label, String value) {
    final isSelected = widget.selectedDocumentType == value;
    return GestureDetector(
      onTap: () => widget.onDocumentTypeSelected?.call(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.champagneGold : AppColors.darkSlate.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.champagneGold : AppColors.borderGold,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10.5,
            color: isSelected ? AppColors.obsidianBlack : AppColors.textPure,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
