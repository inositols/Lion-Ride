part of 'location_bloc.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class MapLoading extends LocationState {}

class MapLoaded extends LocationState {
  final LatLng currentPosition;
  final List<Place> searchResults;

  const MapLoaded({required this.currentPosition, this.searchResults = const []});

  @override
  List<Object?> get props => [currentPosition, searchResults];
}

class RouteCalculating extends LocationState {}

class RouteLoaded extends LocationState {
  final List<LatLng> polyline;
  final double distance;
  final int price;
  final String pickup;
  final String dropoff;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;

  const RouteLoaded({
    required this.polyline,
    required this.distance,
    required this.price,
    required this.pickup,
    required this.dropoff,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  List<Object?> get props => [polyline, distance, price, pickup, dropoff, pickupLocation, dropoffLocation];
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}
