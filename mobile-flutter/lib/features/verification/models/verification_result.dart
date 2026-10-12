import '../../auth/models/user_model.dart';

class VerificationResult {
  final bool success;
  final String status;
  final String badge;
  final int confidenceScore;
  final String documentType;
  final Map<String, dynamic> ocrData;
  final Map<String, dynamic> metrics;
  final String message;
  final UserModel? user;

  VerificationResult({
    required this.success,
    this.status = 'VERIFIED',
    this.badge = 'GOLD',
    this.confidenceScore = 95,
    this.documentType = 'PASSPORT',
    this.ocrData = const {},
    this.metrics = const {},
    this.message = 'Verification completed successfully',
    this.user,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      success: json['success'] == true,
      status: json['verificationStatus']?.toString() ?? 'VERIFIED',
      badge: json['verificationBadge']?.toString() ?? 'GOLD',
      confidenceScore: json['confidenceScore'] is num
          ? (json['confidenceScore'] as num).toInt()
          : 90,
      documentType: json['documentType']?.toString() ?? 'GOVERNMENT_ID',
      ocrData: json['ocrData'] is Map ? Map<String, dynamic>.from(json['ocrData']) : {},
      metrics: json['metrics'] is Map ? Map<String, dynamic>.from(json['metrics']) : {},
      message: json['message']?.toString() ?? 'Identity verified successfully',
      user: json['user'] is Map ? UserModel.fromJson(json['user']) : null,
    );
  }
}
