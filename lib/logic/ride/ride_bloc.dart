import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import '../../models/ride_model.dart';
import '../../models/base_user_model.dart';
import '../../models/rider_model.dart';
import '../../repositories/ride_repository.dart';
import '../../repositories/auth_repository.dart';

part 'ride_event.dart';
part 'ride_state.dart';

class RideBloc extends Bloc<RideEvent, RideState> {
  final RideRepository _rideRepository;
  final AuthRepository _authRepository;
  StreamSubscription? _rideSubscription;
  StreamSubscription? _openRidesSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _nearbyRidersSubscription;
  bool _isRiderOnline = false;
  GeoPoint? _currentRiderLocation;

  final logger = Logger();

  RideBloc({
    required RideRepository rideRepository,
    required AuthRepository authRepository,
  }) : _rideRepository = rideRepository,
       _authRepository = authRepository,
       super(RideInitial()) {
    // Student Handlers
    on<RequestRide>(_onRequestRide);
    on<CancelRide>(_onCancelRide);
    on<ListenToRideUpdate>(_onListenToRideUpdate);
    on<RideModelUpdated>(_onRideModelUpdated);

    // Rider Handlers
    on<GoOnline>(_onGoOnline);
    on<GoOffline>(_onGoOffline);
    on<StreamOpenRidesStarted>(_onStreamOpenRidesStarted);
    on<OpenRidesUpdated>(_onOpenRidesUpdated);
    on<AcceptRide>(_onAcceptRide);
    on<CompleteRide>(_onCompleteRide);
    on<UpdateRiderLocation>(_onUpdateRiderLocation);
    on<RiderLocationUpdated>(_onRiderLocationUpdated);

    // Ghost Riders
    on<MonitorNearbyRiders>(_onMonitorNearbyRiders);
    on<NearbyRidersUpdated>(_onNearbyRidersUpdated);
  }

  // --- Student Logic ---

  Future<void> _onRequestRide(
    RequestRide event,
    Emitter<RideState> emit,
  ) async {
    try {
      emit(RideSearching(event.ride, nearbyRiders: state.nearbyRiders));
      await _rideRepository.createRideRequest(event.ride);
      add(ListenToRideUpdate(event.ride.rideId));
    } catch (e) {
      emit(RideError(e.toString(), nearbyRiders: state.nearbyRiders));
    }
  }

  Future<void> _onCancelRide(CancelRide event, Emitter<RideState> emit) async {
    try {
      await _rideRepository.cancelRide(event.rideId);
      _rideSubscription?.cancel();
      emit(RideInitial(nearbyRiders: state.nearbyRiders));
    } catch (e) {
      emit(RideError(e.toString(), nearbyRiders: state.nearbyRiders));
    }
  }

  void _onListenToRideUpdate(
    ListenToRideUpdate event,
    Emitter<RideState> emit,
  ) {
    _rideSubscription?.cancel();
    _rideSubscription = _rideRepository
        .streamRide(event.rideId)
        .listen((ride) => add(RideModelUpdated(ride)));
  }

  void _onRideModelUpdated(RideModelUpdated event, Emitter<RideState> emit) {
    final ride = event.ride;
    logger.d("Ride update received: ${ride?.status}");
    if (ride == null) {
      emit(RideInitial(nearbyRiders: state.nearbyRiders));
      return;
    }

    if (ride.status == 'searching') {
      emit(RideSearching(ride, nearbyRiders: state.nearbyRiders));
    } else if (ride.status == 'ongoing' ||
        ride.status == 'accepted' ||
        ride.status == 'arrived') {
      RiderModel? acceptedRider;
      
      // Try to find the rider in the nearby list first
      try {
        acceptedRider = state.nearbyRiders.firstWhere((r) => r.uid == ride.riderId);
      } catch (_) {
        // Not in nearby list, we'll need to fetch it if we want detailed info
        // For now, we rely on the repository or a separate fetch if needed.
      }

      // Start listening to rider location if not already
      if (ride.riderId != null && _locationSubscription == null) {
        _locationSubscription = _rideRepository
            .streamRiderLocation(ride.riderId!)
            .listen((pos) => add(RiderLocationUpdated(pos)));
      }
      
      emit(RideActive(
        ride,
        riderLocation: _currentRiderLocation,
        acceptedRider: acceptedRider,
        nearbyRiders: state.nearbyRiders,
      ));
    } else if (ride.status == 'completed' || ride.status == 'cancelled') {
      _locationSubscription?.cancel();
      _locationSubscription = null;
      emit(RideInitial(nearbyRiders: state.nearbyRiders));
    }
  }

  // --- Rider Logic ---

  void _onGoOnline(GoOnline event, Emitter<RideState> emit) async {
    _isRiderOnline = true;
    final user = await _authRepository.user.first;
    if (user != null) {
      await _rideRepository.updateOnlineStatus(user.uid, true);
    }
    emit(RiderBrowsing(nearbyRiders: state.nearbyRiders));
    add(StreamOpenRidesStarted());
  }

  void _onGoOffline(GoOffline event, Emitter<RideState> emit) async {
    _isRiderOnline = false;
    final user = await _authRepository.user.first;
    if (user != null) {
      await _rideRepository.updateOnlineStatus(user.uid, false);
    }
    _openRidesSubscription?.cancel();
    emit(RiderOffline(nearbyRiders: state.nearbyRiders));
  }

  void _onStreamOpenRidesStarted(
    StreamOpenRidesStarted event,
    Emitter<RideState> emit,
  ) {
    _openRidesSubscription?.cancel();
    _openRidesSubscription = _rideRepository.streamOpenRides().listen(
      (rides) => add(OpenRidesUpdated(rides)),
    );
  }

  void _onOpenRidesUpdated(OpenRidesUpdated event, Emitter<RideState> emit) {
    logger.d("Open rides updated: ${event.rides.length} items");
    if (_isRiderOnline && state is! RideActive) {
      emit(RiderBrowsing(
          openRides: event.rides, nearbyRiders: state.nearbyRiders));
    }
  }

  Future<void> _onAcceptRide(AcceptRide event, Emitter<RideState> emit) async {
    try {
      final user = await _authRepository.user.first;
      if (user == null) return;

      await _rideRepository.updateRideStatus(
        event.rideId,
        'ongoing',
        riderId: user.uid,
      );
      // Once accepted, the rider becomes "Active" in the trip
      add(ListenToRideUpdate(event.rideId));
    } catch (e) {
      emit(RideError(e.toString(), nearbyRiders: state.nearbyRiders));
    }
  }

  Future<void> _onCompleteRide(
    CompleteRide event,
    Emitter<RideState> emit,
  ) async {
    try {
      await _rideRepository.updateRideStatus(event.rideId, 'completed');
      _rideSubscription?.cancel();
      if (_isRiderOnline) {
        emit(RiderBrowsing(nearbyRiders: state.nearbyRiders));
        add(StreamOpenRidesStarted());
      } else {
        emit(RiderOffline(nearbyRiders: state.nearbyRiders));
      }
    } catch (e) {
      emit(RideError(e.toString(), nearbyRiders: state.nearbyRiders));
    }
  }

  Future<void> _onUpdateRiderLocation(
    UpdateRiderLocation event,
    Emitter<RideState> emit,
  ) async {
    await _rideRepository.updateRiderLocation(event.riderId, event.position);
  }

  void _onRiderLocationUpdated(
    RiderLocationUpdated event,
    Emitter<RideState> emit,
  ) {
    _currentRiderLocation = event.position;
    if (state is RideActive) {
      emit(
        RideActive(
          (state as RideActive).ride,
          riderLocation: _currentRiderLocation,
          nearbyRiders: state.nearbyRiders,
        ),
      );
    }
  }

  // --- Ghost Riders Logic ---

  void _onMonitorNearbyRiders(
    MonitorNearbyRiders event,
    Emitter<RideState> emit,
  ) {
    _nearbyRidersSubscription?.cancel();
    _nearbyRidersSubscription = _rideRepository.streamOnlineRiders().listen(
      (riders) => add(NearbyRidersUpdated(riders)),
    );
  }

  void _onNearbyRidersUpdated(
    NearbyRidersUpdated event,
    Emitter<RideState> emit,
  ) {
    if (state is RideInitial) {
      emit(RideInitial(nearbyRiders: event.riders));
    } else if (state is RideSearching) {
      emit(RideSearching((state as RideSearching).ride, nearbyRiders: event.riders));
    } else if (state is RideActive) {
      final s = state as RideActive;
      emit(RideActive(s.ride, riderLocation: s.riderLocation, nearbyRiders: event.riders));
    } else if (state is RideError) {
      emit(RideError((state as RideError).message, nearbyRiders: event.riders));
    } else if (state is RideLoading) {
      emit(RideLoading(nearbyRiders: event.riders));
    } else if (state is RiderBrowsing) {
      emit(RiderBrowsing(
        openRides: (state as RiderBrowsing).openRides,
        nearbyRiders: event.riders,
      ));
    } else if (state is RiderOffline) {
      emit(RiderOffline(nearbyRiders: event.riders));
    }
  }

  @override
  Future<void> close() {
    _rideSubscription?.cancel();
    _openRidesSubscription?.cancel();
    _locationSubscription?.cancel();
    _nearbyRidersSubscription?.cancel();
    return super.close();
  }
}
