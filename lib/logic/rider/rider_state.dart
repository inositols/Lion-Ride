part of 'rider_bloc.dart';

abstract class RiderState extends Equatable {
  const RiderState();
  
  @override
  List<Object?> get props => [];
}

class RiderInitial extends RiderState {}

class RiderStatusUpdating extends RiderState {}

class RiderStatusUpdated extends RiderState {
  final bool isOnline;
  final List<RideModel> requests;

  const RiderStatusUpdated({required this.isOnline, this.requests = const []});

  @override
  List<Object?> get props => [isOnline, requests];
}

class RideAcceptanceInProgress extends RiderState {
  final String rideId;
  const RideAcceptanceInProgress(this.rideId);
}

class RideAcceptanceSuccess extends RiderState {}

class RiderError extends RiderState {
  final String message;
  const RiderError(this.message);

  @override
  List<Object?> get props => [message];
}
