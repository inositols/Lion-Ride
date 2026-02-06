import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/ride_model.dart';
import '../../repositories/rider_repository.dart';
import '../../repositories/auth_repository.dart';

part 'rider_event.dart';
part 'rider_state.dart';

class RiderBloc extends Bloc<RiderEvent, RiderState> {
  final RiderRepository _riderRepository;
  final AuthRepository _authRepository;
  StreamSubscription? _requestsSubscription;
  bool _isOnline = false;

  RiderBloc({
    required RiderRepository riderRepository,
    required AuthRepository authRepository,
  })  : _riderRepository = riderRepository,
        _authRepository = authRepository,
        super(RiderInitial()) {
    on<ToggleOnlineStatus>(_onToggleOnlineStatus);
    on<StreamRequestsStarted>(_onStreamRequestsStarted);
    on<IncomingRequestsUpdated>(_onIncomingRequestsUpdated);
    on<AcceptRideRequested>(_onAcceptRideRequested);
  }

  Future<void> _onToggleOnlineStatus(
    ToggleOnlineStatus event,
    Emitter<RiderState> emit,
  ) async {
    final user = await _authRepository.user.first;
    if (user == null) return;

    emit(RiderStatusUpdating());
    try {
      _isOnline = !_isOnline;
      await _riderRepository.updateOnlineStatus(user.uid, _isOnline);
      
      if (_isOnline) {
        add(StreamRequestsStarted());
      } else {
        await _requestsSubscription?.cancel();
        emit(RiderStatusUpdated(isOnline: false));
      }
    } catch (e) {
      emit(RiderError(e.toString()));
    }
  }

  void _onStreamRequestsStarted(
    StreamRequestsStarted event,
    Emitter<RiderState> emit,
  ) {
    _requestsSubscription?.cancel();
    _requestsSubscription = _riderRepository.getIncomingRequests().listen(
      (requests) => add(IncomingRequestsUpdated(requests)),
      onError: (e) => add(IncomingRequestsUpdated([])), // Log error maybe
    );
  }

  void _onIncomingRequestsUpdated(
    IncomingRequestsUpdated event,
    Emitter<RiderState> emit,
  ) {
    emit(RiderStatusUpdated(isOnline: _isOnline, requests: event.requests));
  }

  Future<void> _onAcceptRideRequested(
    AcceptRideRequested event,
    Emitter<RiderState> emit,
  ) async {
    final user = await _authRepository.user.first;
    if (user == null) return;

    emit(RideAcceptanceInProgress(event.rideId));
    try {
      await _riderRepository.acceptRide(event.rideId, user.uid);
      emit(RideAcceptanceSuccess());
      // After success, stay in online state
      emit(RiderStatusUpdated(isOnline: _isOnline, requests: (state as RiderStatusUpdated).requests));
    } catch (e) {
      emit(RiderError(e.toString()));
      // Emit back the status to restore the UI
      emit(RiderStatusUpdated(isOnline: _isOnline));
    }
  }

  @override
  Future<void> close() {
    _requestsSubscription?.cancel();
    return super.close();
  }
}
