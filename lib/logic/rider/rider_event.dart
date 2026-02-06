part of 'rider_bloc.dart';

abstract class RiderEvent extends Equatable {
  const RiderEvent();

  @override
  List<Object?> get props => [];
}

class ToggleOnlineStatus extends RiderEvent {}

class StreamRequestsStarted extends RiderEvent {}

class IncomingRequestsUpdated extends RiderEvent {
  final List<RideModel> requests;
  const IncomingRequestsUpdated(this.requests);

  @override
  List<Object?> get props => [requests];
}

class AcceptRideRequested extends RiderEvent {
  final String rideId;
  const AcceptRideRequested(this.rideId);

  @override
  List<Object?> get props => [rideId];
}
