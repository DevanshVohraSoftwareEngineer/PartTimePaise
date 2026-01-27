import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/kyc_service.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// KYC State Management
class KycState {
  final bool isLoading;
  final bool isVerified;
  final KycDocument? document;
  final Map<String, dynamic>? extractedData;
  final String? error;
  final KycVerificationStep currentStep;

  const KycState({
    this.isLoading = false,
    this.isVerified = false,
    this.document,
    this.extractedData,
    this.error,
    this.currentStep = KycVerificationStep.none,
  });

  KycState copyWith({
    bool? isLoading,
    bool? isVerified,
    KycDocument? document,
    Map<String, dynamic>? extractedData,
    String? error,
    KycVerificationStep? currentStep,
  }) {
    return KycState(
      isLoading: isLoading ?? this.isLoading,
      isVerified: isVerified ?? this.isVerified,
      document: document ?? this.document,
      extractedData: extractedData ?? this.extractedData,
      error: error ?? this.error,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

enum KycVerificationStep {
  none,
  methodSelection,
  digiLockerAuth,
  documentUpload,
  verificationPending,
  completed,
  failed,
}

class KycNotifier extends StateNotifier<KycState> {
  final KycService _kycService;
  final SupabaseService _supabaseService;

  KycNotifier(this._kycService, this._supabaseService) : super(const KycState());

  // Check KYC status for a user via Supabase and KycService
  Future<void> checkKycStatus() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final isCompleted = await _kycService.isKycCompleted(userId);
      // Logic to fetch from Supabase 'kyc_records' table
      state = state.copyWith(isLoading: false, isVerified: isCompleted);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<Map<String, dynamic>> getAvailableKycMethods() {
    return [
      {
        'id': 'digilocker',
        'name': 'DigiLocker (Instant)',
        'description': 'Verify using government-issued documents from DigiLocker',
        'estimatedTime': '2-5 minutes',
        'icon': '🔐',
        'isInstant': true,
      },
      {
        'id': 'manual',
        'name': 'Manual Upload',
        'description': 'Upload documents for manual verification',
        'estimatedTime': '24-48 hours',
        'icon': '📄',
        'isInstant': false,
      },
    ];
  }

  void chooseDigiLockerMethod() {
    state = state.copyWith(currentStep: KycVerificationStep.digiLockerAuth);
  }

  void chooseManualUploadMethod() {
    state = state.copyWith(currentStep: KycVerificationStep.documentUpload);
  }

  void resetKyc() {
    state = const KycState();
  }

  Future<void> uploadDocumentForVerification(
    String documentType,
    List<int> documentBytes,
    Map<String, dynamic> userProvidedData,
  ) async {
    state = state.copyWith(isLoading: true);
    // Mimic actual upload delay
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false);
  }
}

// Providers
final kycServiceProvider = Provider<KycService>((ref) => KycService.instance);

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  final kycService = ref.watch(kycServiceProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  return KycNotifier(kycService, supabaseService);
});

// Computed providers
final isKycVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(kycProvider).isVerified;
});