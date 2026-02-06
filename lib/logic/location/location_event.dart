part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMap extends LocationEvent {}

class SearchDestination extends LocationEvent {
  final String query;
  const SearchDestination(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectLocation extends LocationEvent {
  final Place destination; // Carrying the Place object to have name and latlng
  const SelectLocation(this.destination);

  @override
  List<Object?> get props => [destination];
}

class ConfirmRideDetails extends LocationEvent {}
