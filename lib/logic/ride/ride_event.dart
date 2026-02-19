part of 'ride_bloc.dart';

abstract class RideEvent extends Equatable {
  const RideEvent();

  @override
  List<Object?> get props => [];
}

// Student Events
class RequestRide extends RideEvent {
  final RideModel ride;
  const RequestRide(this.ride);

  @override
  List<Object?> get props => [ride];
}

class CancelRide extends RideEvent {
  final String rideId;
  const CancelRide(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class ListenToRideUpdate extends RideEvent {
  final String rideId;
  const ListenToRideUpdate(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class MonitorNearbyRiders extends RideEvent {}

class NearbyRidersUpdated extends RideEvent {
  final List<RiderModel> riders;
  const NearbyRidersUpdated(this.riders);

  @override
  List<Object?> get props => [riders];
}

// Rider Events
class GoOnline extends RideEvent {}
class GoOffline extends RideEvent {}

class StreamOpenRidesStarted extends RideEvent {}

class OpenRidesUpdated extends RideEvent {
  final List<RideModel> rides;
  const OpenRidesUpdated(this.rides);

  @override
  List<Object?> get props => [rides];
}

class AcceptRide extends RideEvent {
  final String rideId;
  const AcceptRide(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class CompleteRide extends RideEvent {
  final String rideId;
  const CompleteRide(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

// Internal
class RideModelUpdated extends RideEvent {
  final RideModel? ride;
  const RideModelUpdated(this.ride);

  @override
  List<Object?> get props => [ride];
}

class UpdateRiderLocation extends RideEvent {
  final String riderId;
  final GeoPoint position;
  const UpdateRiderLocation(this.riderId, this.position);
}

class RiderLocationUpdated extends RideEvent {
  final GeoPoint? position;
  const RiderLocationUpdated(this.position);
}
