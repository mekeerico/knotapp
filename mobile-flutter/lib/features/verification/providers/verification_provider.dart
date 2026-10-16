import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/verification_result.dart';

enum VerificationStep {
  captureId,
  reviewId,
  livenessScan,
  processing,
  success,
  failed,
}

enum ProcessingPhase {
  analyzingDocument,
  validatingLiveness,
  runningFaceMatch,
  completing,
}

class VerificationState {
  final VerificationStep currentStep;
  final ProcessingPhase processingPhase;
  final String? frontImagePath;
  final String? backImagePath;
  final String? selfieImagePath;
  final String selectedDocumentType;
  final VerificationResult? result;
  final String? errorMessage;
  final bool isSubmitting;

  const VerificationState({
    this.currentStep = VerificationStep.captureId,
    this.processingPhase = ProcessingPhase.analyzingDocument,
    this.frontImagePath,
    this.backImagePath,
    this.selfieImagePath,
    this.selectedDocumentType = 'National Identity Card (NIN)',
    this.result,
    this.errorMessage,
    this.isSubmitting = false,
  });

  VerificationState copyWith({
    VerificationStep? currentStep,
    ProcessingPhase? processingPhase,
    String? frontImagePath,
    String? backImagePath,
    String? selfieImagePath,
    String? selectedDocumentType,
    VerificationResult? result,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return VerificationState(
      currentStep: currentStep ?? this.currentStep,
      processingPhase: processingPhase ?? this.processingPhase,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      selfieImagePath: selfieImagePath ?? this.selfieImagePath,
      selectedDocumentType: selectedDocumentType ?? this.selectedDocumentType,
      result: result ?? this.result,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final Dio _dio;
  final Ref _ref;

  VerificationNotifier(this._dio, this._ref) : super(const VerificationState());

  void setSelectedDocumentType(String type) {
    state = state.copyWith(selectedDocumentType: type);
  }

  void setIdImage(String path) {
    state = state.copyWith(
      frontImagePath: path,
      currentStep: VerificationStep.reviewId,
      errorMessage: null,
    );
  }

  void setFrontImage(String path) => setIdImage(path);

  void proceedToLiveness() {
    state = state.copyWith(
      currentStep: VerificationStep.livenessScan,
      errorMessage: null,
    );
  }

  void retakeId() {
    state = state.copyWith(
      frontImagePath: null,
      currentStep: VerificationStep.captureId,
      errorMessage: null,
    );
  }

  void setBackImage(String? path) {
    state = state.copyWith(
      backImagePath: path,
      currentStep: VerificationStep.reviewId,
      errorMessage: null,
    );
  }

  void skipBackImage() {
    state = state.copyWith(
      currentStep: VerificationStep.livenessScan,
      errorMessage: null,
    );
  }

  void setSelfieImage(String path) {
    state = state.copyWith(
      selfieImagePath: path,
      currentStep: VerificationStep.processing,
      isSubmitting: true,
      errorMessage: null,
    );
    submitVerification();
  }

  void reset() {
    state = const VerificationState();
  }

  Future<void> submitVerification() async {
    if (state.frontImagePath == null || state.selfieImagePath == null) {
      state = state.copyWith(
        currentStep: VerificationStep.failed,
        errorMessage: 'Document and selfie images are required.',
        isSubmitting: false,
      );
      return;
    }

    try {
      // Step 1: Document analysis indicator
      state = state.copyWith(processingPhase: ProcessingPhase.analyzingDocument);
      await Future.delayed(const Duration(milliseconds: 900));

      // Step 2: Liveness verification indicator
      state = state.copyWith(processingPhase: ProcessingPhase.validatingLiveness);
      await Future.delayed(const Duration(milliseconds: 900));

      // Step 3: Biometric face match indicator
      state = state.copyWith(processingPhase: ProcessingPhase.runningFaceMatch);

      final formData = FormData();
      formData.fields.add(
        MapEntry('documentType', state.selectedDocumentType),
      );
      formData.files.add(
        MapEntry(
          'idFront',
          await MultipartFile.fromFile(
            state.frontImagePath!,
            filename: 'id_front.jpg',
          ),
        ),
      );

      if (state.backImagePath != null) {
        formData.files.add(
          MapEntry(
            'idBack',
            await MultipartFile.fromFile(
              state.backImagePath!,
              filename: 'id_back.jpg',
            ),
          ),
        );
      }

      formData.files.add(
        MapEntry(
          'selfie',
          await MultipartFile.fromFile(
            state.selfieImagePath!,
            filename: 'selfie.jpg',
          ),
        ),
      );

      final response = await _dio.post(
        ApiEndpoints.verifyIdentity,
        data: formData,
      );

      state = state.copyWith(processingPhase: ProcessingPhase.completing);
      await Future.delayed(const Duration(milliseconds: 600));

      final result = VerificationResult.fromJson(response.data);

      if (result.success) {
        // Update auth state with verified user
        if (result.user != null) {
          _ref.read(authProvider.notifier).setUser(result.user!);
        } else {
          // Refresh profile
          await _ref.read(authProvider.notifier).checkAuth();
        }

        state = state.copyWith(
          currentStep: VerificationStep.success,
          result: result,
          isSubmitting: false,
        );
      } else {
        state = state.copyWith(
          currentStep: VerificationStep.failed,
          errorMessage: result.message,
          isSubmitting: false,
        );
      }
    } catch (e) {
      String message = 'Verification could not be completed';
      if (e is DioException) {
        message = e.response?.data?['message'] ?? e.message ?? message;
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        currentStep: VerificationStep.failed,
        errorMessage: message,
        isSubmitting: false,
      );
    }
  }
}

final verificationProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  final dio = ref.watch(dioProvider);
  return VerificationNotifier(dio, ref);
});
