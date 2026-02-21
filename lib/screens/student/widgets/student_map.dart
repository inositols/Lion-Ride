import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/location/location_bloc.dart';
import '../../../logic/ride/ride_bloc.dart';
import '../../../repositories/location_repository.dart';
import '../../../core/services/map_marker_service.dart';

class StudentMap extends StatelessWidget {
  final Function(GoogleMapController) onMapCreated;
  final BitmapDescriptor? bikeIcon;
  final LatLng? lastRiderPosition;
  final double riderBearing;
  final String searchQuery;

  const StudentMap({
    super.key,
    required this.onMapCreated,
    this.bikeIcon,
    this.lastRiderPosition,
    this.riderBearing = 0,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, locState) {
        if (locState is MapLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        LatLng initialPos = LocationRepository.unnMainGate;
        Set<Marker> markers = {};

        if (locState is MapLoaded) {
          initialPos = locState.currentPosition;
          markers.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: initialPos,
            ),
          );

          final landmarksToShow = (searchQuery.isNotEmpty)
              ? locState.searchResults
              : LocationRepository.mockLandmarks;

          for (var landmark in landmarksToShow) {
            markers.add(
              Marker(
                markerId: MarkerId('landmark_${landmark.name}'),
                position: landmark.location,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: InfoWindow(title: landmark.name),
                onTap: () {
                  context.read<LocationBloc>().add(SelectLocation(landmark));
                },
              ),
            );
          }
        }

        return BlocBuilder<RideBloc, RideState>(
          builder: (context, rideState) {
            Set<Marker> finalMarkers = Set.from(markers);

            // Filter and sort nearby riders (top 20 closest)
            final sortedRiders = List.from(rideState.nearbyRiders)
              ..sort((a, b) {
                if (a.lastLocation == null || b.lastLocation == null) return 0;
                final distA = Geolocator.distanceBetween(
                  initialPos.latitude,
                  initialPos.longitude,
                  a.lastLocation!.latitude,
                  a.lastLocation!.longitude,
                );
                final distB = Geolocator.distanceBetween(
                  initialPos.latitude,
                  initialPos.longitude,
                  b.lastLocation!.latitude,
                  b.lastLocation!.longitude,
                );
                return distA.compareTo(distB);
              });

            final topRiders = sortedRiders.take(20);

            for (var rider in topRiders) {
              if (rider.lastLocation != null) {
                finalMarkers.add(
                  Marker(
                    markerId: MarkerId('nearby_${rider.uid}'),
                    position: LatLng(
                      rider.lastLocation!.latitude,
                      rider.lastLocation!.longitude,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: InfoWindow(
                      title: 'Available Rider',
                      snippet: rider.name,
                    ),
                  ),
                );
              }
            }

            if (rideState is RideActive) {
              finalMarkers.add(
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(rideState.ride.pickupLat, rideState.ride.pickupLng),
                ),
              );
              finalMarkers.add(
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: LatLng(rideState.ride.dropoffLat, rideState.ride.dropoffLng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  infoWindow: InfoWindow(title: rideState.ride.dropoffAddress),
                ),
              );

              if (rideState.riderLocation != null) {
                final currentPos = LatLng(
                  rideState.riderLocation!.latitude,
                  rideState.riderLocation!.longitude,
                );

                finalMarkers.add(
                  Marker(
                    markerId: const MarkerId('rider'),
                    position: currentPos,
                    icon: bikeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    rotation: riderBearing,
                    flat: true,
                    anchor: const Offset(0.5, 0.5),
                    infoWindow: const InfoWindow(title: 'Your Rider'),
                  ),
                );
              }
            } else if (locState is RouteLoaded) {
              initialPos = locState.pickupLocation;
              finalMarkers.add(
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: locState.pickupLocation,
                ),
              );
              finalMarkers.add(
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: locState.dropoffLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  infoWindow: InfoWindow(title: locState.dropoff),
                ),
              );
            }

            return GoogleMap(
              onMapCreated: onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initialPos,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: finalMarkers,
              zoomControlsEnabled: false,
            );
          },
        );
      },
    );
  }
}
