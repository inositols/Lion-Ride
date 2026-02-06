part of 'ride_bloc.dart';

abstract class RideState extends Equatable {
  final List<UserModel> nearbyRiders;
  const RideState({this.nearbyRiders = const []});
  
  @override
  List<Object?> get props => [nearbyRiders];
}

class RideInitial extends RideState {
  const RideInitial({super.nearbyRiders});
}

// Student States
class RideSearching extends RideState {
  final RideModel ride;
  const RideSearching(this.ride, {super.nearbyRiders});

  @override
  List<Object?> get props => [ride, nearbyRiders];
}

class RideActive extends RideState {
  final RideModel ride;
  final GeoPoint? riderLocation;
  const RideActive(this.ride, {this.riderLocation, super.nearbyRiders});

  @override
  List<Object?> get props => [ride, riderLocation, nearbyRiders];
}

class RideLoading extends RideState {
  const RideLoading({super.nearbyRiders});
}

// Rider States
class RiderOffline extends RideState {
  const RiderOffline({super.nearbyRiders});
}
class RiderBrowsing extends RideState {
  final List<RideModel> openRides;
  const RiderBrowsing({this.openRides = const [], super.nearbyRiders});

  @override
  List<Object?> get props => [openRides, nearbyRiders];
}

class RideError extends RideState {
  final String message;
  const RideError(this.message, {super.nearbyRiders});

  @override
  List<Object?> get props => [message, nearbyRiders];
}
