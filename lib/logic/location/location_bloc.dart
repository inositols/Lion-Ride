import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../repositories/location_repository.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _locationRepository;

  LocationBloc({required LocationRepository locationRepository})
      : _locationRepository = locationRepository,
        super(LocationInitial()) {
    on<LoadMap>(_onLoadMap);
    on<SearchDestination>(_onSearchDestination);
    on<SelectLocation>(_onSelectLocation);
  }

  Future<void> _onLoadMap(LoadMap event, Emitter<LocationState> emit) async {
    emit(MapLoading());
    try {
      final position = await _locationRepository.getCurrentPosition();
      emit(MapLoaded(currentPosition: LatLng(position.latitude, position.longitude)));
    } catch (e) {
      // Fallback to UNN Main Gate if GPS fails as requested
      emit(MapLoaded(currentPosition: LocationRepository.unnMainGate));
    }
  }

  void _onSearchDestination(SearchDestination event, Emitter<LocationState> emit) {
    LatLng currentPos;
    if (state is MapLoaded) {
      currentPos = (state as MapLoaded).currentPosition;
    } else if (state is RouteLoaded) {
      currentPos = (state as RouteLoaded).pickupLocation;
    } else {
      // Default fallback
      currentPos = LocationRepository.unnMainGate;
    }

    final results = _locationRepository.searchLandmarks(event.query);
    emit(MapLoaded(currentPosition: currentPos, searchResults: results));
  }

  Future<void> _onSelectLocation(SelectLocation event, Emitter<LocationState> emit) async {
    LatLng? currentPos;
    if (state is MapLoaded) {
      currentPos = (state as MapLoaded).currentPosition;
    } else if (state is RouteLoaded) {
      currentPos = (state as RouteLoaded).pickupLocation;
    }

    if (currentPos != null) {
      emit(RouteCalculating());
      
      final polyline = _locationRepository.getRoutePolyline(currentPos, event.destination.location);
      final distance = _locationRepository.calculateDistance(currentPos, event.destination.location);
      
      // Pricing Formula: ₦100 base + ₦50 per km, Min ₦200
      double calculatedPrice = 100 + (distance * 50);
      int finalPrice = calculatedPrice < 200 ? 200 : calculatedPrice.round();

      emit(RouteLoaded(
        polyline: polyline,
        distance: distance,
        price: finalPrice,
        pickup: "Current Location",
        dropoff: event.destination.name,
        pickupLocation: currentPos,
        dropoffLocation: event.destination.location,
      ));
    }
  }
}
