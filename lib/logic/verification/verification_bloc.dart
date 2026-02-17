import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/verification_repository.dart';
import '../auth/auth_bloc.dart';

// --- EVENTS ---

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();
  @override
  List<Object?> get props => [];
}

class StartPhoneVerification extends VerificationEvent {
  final String phoneNumber;
  const StartPhoneVerification(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class CheckVerificationStatus extends VerificationEvent {}

class SubmitOtp extends VerificationEvent {
  final String verificationId;
  final String smsCode;
  const SubmitOtp(this.verificationId, this.smsCode);
  @override
  List<Object?> get props => [verificationId, smsCode];
}

class FaceVerifiedSuccess extends VerificationEvent {}

class DocumentStepCompleted extends VerificationEvent {}

class UploadDocRequested extends VerificationEvent {
  final String filePath;
  final String type; // 'nin' or 'bike_papers'
  const UploadDocRequested(this.filePath, this.type);
  @override
  List<Object?> get props => [filePath, type];
}

class SubmitGuarantorRequested extends VerificationEvent {
  final String name;
  final String phone;
  const SubmitGuarantorRequested(this.name, this.phone);
  @override
  List<Object?> get props => [name, phone];
}

// Internal Events
class _InternalOtpSent extends VerificationEvent {
  final String verificationId;
  const _InternalOtpSent(this.verificationId);
  @override
  List<Object?> get props => [verificationId];
}

class _InternalError extends VerificationEvent {
  final String message;
  const _InternalError(this.message);
  @override
  List<Object?> get props => [message];
}

class _InternalStepCompleted extends VerificationEvent {
  final int step;
  const _InternalStepCompleted(this.step);
  @override
  List<Object?> get props => [step];
}

// --- STATES ---

abstract class VerificationState extends Equatable {
  const VerificationState();
  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {}

class VerificationLoading extends VerificationState {}

class VerificationStep1Phone extends VerificationState {}

class VerificationOtpSent extends VerificationState {
  final String verificationId;
  const VerificationOtpSent(this.verificationId);
  @override
  List<Object?> get props => [verificationId];
}

class VerificationStep2Face extends VerificationState {}

class VerificationStep3Docs extends VerificationState {}

class VerificationStep4Guarantor extends VerificationState {}

class VerificationPendingApproval extends VerificationState {}

class VerificationFailure extends VerificationState {
  final String error;
  const VerificationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// --- BLOC ---

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _repository;
  final AuthBloc _authBloc;

  VerificationBloc({
    required VerificationRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(VerificationInitial()) {
    on<StartPhoneVerification>(_onStartPhoneVerification);
    on<CheckVerificationStatus>(_onCheckVerificationStatus);
    on<SubmitOtp>(_onSubmitOtp);
    on<FaceVerifiedSuccess>(_onFaceVerifiedSuccess);
    on<DocumentStepCompleted>(_onDocumentStepCompleted);
    on<UploadDocRequested>(_onUploadDocRequested);
    on<SubmitGuarantorRequested>(_onSubmitGuarantorRequested);
    
    // Internal Event Handlers
    on<_InternalOtpSent>((event, emit) => emit(VerificationOtpSent(event.verificationId)));
    on<_InternalError>((event, emit) => emit(VerificationFailure(event.message)));
    on<_InternalStepCompleted>(_onInternalStepCompleted);
  }

  Future<void> _onStartPhoneVerification(
    StartPhoneVerification event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      await _repository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        onCodeSent: (verificationId, _) {
          add(_InternalOtpSent(verificationId));
        },
        onVerificationFailed: (e) {
          add(_InternalError(e.message ?? 'Verification Failed'));
        },
        onVerificationCompleted: (credential) async {
          await _repository.linkPhoneToAccount(credential);
          _authBloc.add(AuthProfileUpdateRequested());
          add(const _InternalStepCompleted(2));
        },
      );
    } catch (e) {
      emit(VerificationFailure(e.toString()));
    }
  }

  Future<void> _onSubmitOtp(
    SubmitOtp event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      await _repository.linkPhoneToAccount(credential);
      _authBloc.add(AuthProfileUpdateRequested());
      
      final authState = _authBloc.state;
      if (authState is AuthAuthenticated && authState.user.role == 'rider') {
        emit(VerificationStep2Face());
      } else {
        // Students are done
        // The RootWrapper or StudentHome will handle the redirection since u.isPhoneVerified is now true
      }
    } catch (e) {
      emit(VerificationFailure(e.toString()));
    }
  }

  Future<void> _onFaceVerifiedSuccess(
    FaceVerifiedSuccess event,
    Emitter<VerificationState> emit,
  ) async {
    await _repository.markFaceVerified();
    _authBloc.add(AuthProfileUpdateRequested());
    emit(VerificationStep3Docs());
  }

  void _onDocumentStepCompleted(
    DocumentStepCompleted event,
    Emitter<VerificationState> emit,
  ) {
    emit(VerificationStep4Guarantor());
  }

  Future<void> _onUploadDocRequested(
    UploadDocRequested event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      await _repository.uploadVerificationDoc(File(event.filePath), event.type);
      _authBloc.add(AuthProfileUpdateRequested());
      emit(VerificationStep3Docs()); 
    } catch (e) {
      emit(VerificationFailure(e.toString()));
    }
  }

  Future<void> _onSubmitGuarantorRequested(
    SubmitGuarantorRequested event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      await _repository.submitGuarantorDetails(event.name, event.phone);
      await _repository.finalizeDocumentUpload(); 
      _authBloc.add(AuthProfileUpdateRequested());
      emit(VerificationPendingApproval());
    } catch (e) {
      emit(VerificationFailure(e.toString()));
    }
  }

  void _onCheckVerificationStatus(
    CheckVerificationStatus event,
    Emitter<VerificationState> emit,
  ) {
    final state = _authBloc.state;
    if (state is AuthAuthenticated) {
      final u = state.user;
      if (!u.isPhoneVerified) {
        emit(VerificationStep1Phone());
      } else {
        // Students only need phone verification
        if (u.role == 'student') {
          // If they reach here and phone is verified, they are good
          // We can emit a final state or just let the home screen take over
          return; 
        }

        // Riders need full verification
        if (!u.isFaceVerified) {
          emit(VerificationStep2Face());
        } else if (!u.documentsUploaded) {
          emit(VerificationStep3Docs());
        } else if (u.guarantorName == null) {
          emit(VerificationStep4Guarantor());
        } else {
          emit(VerificationPendingApproval());
        }
      }
    }
  }

  void _onInternalStepCompleted(
    _InternalStepCompleted event,
    Emitter<VerificationState> emit,
  ) {
    final authState = _authBloc.state;
    final isRider = authState is AuthAuthenticated && authState.user.role == 'rider';

    if (event.step == 2) {
      if (isRider) {
        emit(VerificationStep2Face());
      } else {
        // Students are done after phone verification (Step 1 -> Step 2 transition means phone is verified)
      }
    }
    if (event.step == 3) emit(VerificationStep3Docs());
    if (event.step == 4) emit(VerificationStep4Guarantor());
  }
}
