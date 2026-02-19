import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nsuride_mobile/logic/verification/verification_bloc.dart';
import 'package:nsuride_mobile/repositories/verification_repository.dart';
import 'package:nsuride_mobile/screens/verification/verification_wizard.dart';
import '../../logic/location/location_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../repositories/location_repository.dart';
import '../../core/services/safety_service.dart';
import '../../logic/ride/ride_bloc.dart';
import '../../models/ride_model.dart';
import '../../models/base_user_model.dart';
import '../../models/rider_model.dart';
import '../shared/safety_toolkit_widget.dart';
import '../../core/widgets/global_error_listener.dart';
import '../../core/services/map_marker_service.dart';
import 'widgets/student_drawer.dart';
import 'widgets/location_search_bar.dart';
import 'widgets/searching_overlay.dart';
import 'widgets/active_trip_panel.dart';
import 'widgets/nearby_riders_sheet.dart';
import 'widgets/negotiation_sheet.dart';
import 'widgets/driver_found_notification.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  BitmapDescriptor? _bikeIcon;
  LatLng? _lastRiderPosition;
  double _riderBearing = 0;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    context.read<LocationBloc>().add(LoadMap());
    context.read<RideBloc>().add(MonitorNearbyRiders());
  }

  Future<void> _loadIcons() async {
    try {
      final icon = await MapMarkerService.loadBikeIcon();
      if (mounted) {
        setState(() {
          _bikeIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('Error loading marker icons: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;
    _mapController = controller;
  }

  void _showConfirmBottomSheet(BuildContext context, RouteLoaded routeState) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return NegotiationSheet(
          routeState: routeState,
          onConfirm: (finalPrice, notes) {
            final rideId = 'ride_${DateTime.now().millisecondsSinceEpoch}';
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated) {
              final student = authState.user;
              // Add notes to the ride model if necessary, or just use the price
              final ride = RideModel(
                rideId: rideId,
                studentId: student.uid,
                pickupLat: routeState.pickupLocation.latitude,
                pickupLng: routeState.pickupLocation.longitude,
                dropoffLat: routeState.dropoffLocation.latitude,
                dropoffLng: routeState.dropoffLocation.longitude,
                pickupAddress: routeState.pickup,
                dropoffAddress: routeState.dropoff,
                cost: finalPrice,
                status: 'searching',
                timestamp: DateTime.now(),
              );

              context.read<RideBloc>().add(RequestRide(ride));
              Navigator.pop(bottomSheetContext);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final u = authState.user;
      if (!u.isPhoneVerified) {
        return const Scaffold(
          body: VerificationWizard(),
        );
      }
    }

    return GlobalErrorListener(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        drawer: const StudentDrawer(),
        body: Stack(
          children: [
            // Background: Full-screen Google Map
            BlocListener<RideBloc, RideState>(
              listener: (context, state) {
                if (state is RideActive) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => DriverFoundNotification(
                      driverName: state.acceptedRider?.name ?? 'Verified Rider',
                      rating: 4.8, // Static for now, can be dynamic later
                      vehicleInfo: 'UNN Campus Rider',
                      plateNumber: state.acceptedRider?.plateNumber,
                      onTrackTap: () => Navigator.pop(context),
                    ),
                  );

                  if (_mapController != null && state.riderLocation != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            state.ride.pickupLat < state.riderLocation!.latitude
                                ? state.ride.pickupLat
                                : state.riderLocation!.latitude,
                            state.ride.pickupLng <
                                    state.riderLocation!.longitude
                                ? state.ride.pickupLng
                                : state.riderLocation!.longitude,
                          ),
                          northeast: LatLng(
                            state.ride.pickupLat > state.riderLocation!.latitude
                                ? state.ride.pickupLat
                                : state.riderLocation!.latitude,
                            state.ride.pickupLng >
                                    state.riderLocation!.longitude
                                ? state.ride.pickupLng
                                : state.riderLocation!.longitude,
                          ),
                        ),
                        100, // padding
                      ),
                    );
                  }
                }
              },
              child: BlocConsumer<LocationBloc, LocationState>(
                listener: (context, state) {
                  if (state is RouteLoaded) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            state.pickupLocation.latitude <
                                    state.dropoffLocation.latitude
                                ? state.pickupLocation.latitude
                                : state.dropoffLocation.latitude,
                            state.pickupLocation.longitude <
                                    state.dropoffLocation.longitude
                                ? state.pickupLocation.longitude
                                : state.dropoffLocation.longitude,
                          ),
                          northeast: LatLng(
                            state.pickupLocation.latitude >
                                    state.dropoffLocation.latitude
                                ? state.pickupLocation.latitude
                                : state.dropoffLocation.latitude,
                            state.pickupLocation.longitude >
                                    state.dropoffLocation.longitude
                                ? state.pickupLocation.longitude
                                : state.dropoffLocation.longitude,
                          ),
                        ),
                        100,
                      ),
                    );
                    _showConfirmBottomSheet(context, state);
                  }
                },
                builder: (context, state) {
                  if (state is MapLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  LatLng initialPos = LocationRepository.unnMainGate;
                  Set<Marker> markers = {};

                  if (state is MapLoaded) {
                    initialPos = state.currentPosition;
                    markers.add(
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: initialPos,
                      ),
                    );

                    final landmarksToShow = (_searchController.text.isNotEmpty)
                        ? state.searchResults
                        : LocationRepository.mockLandmarks;

                    for (var landmark in landmarksToShow) {
                      markers.add(
                        Marker(
                          markerId: MarkerId('landmark_${landmark.name}'),
                          position: landmark.location,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                          infoWindow: InfoWindow(title: landmark.name),
                          onTap: () {
                            _searchController.text = landmark.name;
                            context.read<LocationBloc>().add(
                                  SelectLocation(landmark),
                                );
                          },
                        ),
                      );
                    }
                  }

                  return BlocBuilder<RideBloc, RideState>(
                    builder: (context, rideState) {
                      Set<Marker> finalMarkers = Set.from(markers);

                      for (var rider in rideState.nearbyRiders) {
                        if (rider.lastLocation != null) {
                          finalMarkers.add(
                            Marker(
                              markerId: MarkerId('nearby_${rider.uid}'),
                              position: LatLng(
                                rider.lastLocation!.latitude,
                                rider.lastLocation!.longitude,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
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
                            position: LatLng(
                              rideState.ride.pickupLat,
                              rideState.ride.pickupLng,
                            ),
                          ),
                        );
                        finalMarkers.add(
                          Marker(
                            markerId: const MarkerId('dropoff'),
                            position: LatLng(
                              rideState.ride.dropoffLat,
                              rideState.ride.dropoffLng,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                            infoWindow: InfoWindow(
                              title: rideState.ride.dropoffAddress,
                            ),
                          ),
                        );
                        if (rideState.riderLocation != null) {
                          final currentPos = LatLng(
                            rideState.riderLocation!.latitude,
                            rideState.riderLocation!.longitude,
                          );

                          if (_lastRiderPosition != null &&
                              _lastRiderPosition != currentPos) {
                            _riderBearing = MapMarkerService.calculateBearing(
                              _lastRiderPosition!,
                              currentPos,
                            );
                          }
                          _lastRiderPosition = currentPos;

                          finalMarkers.add(
                            Marker(
                              markerId: const MarkerId('rider'),
                              position: currentPos,
                              icon:
                                  _bikeIcon ??
                                  BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueBlue,
                                  ),
                              rotation: _riderBearing,
                              flat: true,
                              anchor: const Offset(0.5, 0.5),
                              infoWindow: const InfoWindow(title: 'Your Rider'),
                            ),
                          );
                        }
                      } else if (state is RouteLoaded) {
                        initialPos = state.pickupLocation;
                        finalMarkers.add(
                          Marker(
                            markerId: const MarkerId('pickup'),
                            position: state.pickupLocation,
                          ),
                        );
                        finalMarkers.add(
                          Marker(
                            markerId: const MarkerId('dropoff'),
                            position: state.dropoffLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                            infoWindow: InfoWindow(title: state.dropoff),
                          ),
                        );
                      }

                      return GoogleMap(
                        onMapCreated: _onMapCreated,
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
              ),
            ),

            // Top Search Bar
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, locState) {
                final results = (locState is MapLoaded)
                    ? locState.searchResults
                    : <Place>[];
                return LocationSearchBar(
                  controller: _searchController,
                  onMenuTap: () => Scaffold.of(context).openDrawer(),
                  onChanged: (val) =>
                      context.read<LocationBloc>().add(SearchDestination(val)),
                  onClear: () {
                    _searchController.clear();
                    context.read<LocationBloc>().add(LoadMap());
                  },
                  searchResults: results,
                  onSelectPlace: (place) {
                    _searchController.text = place.name;
                    FocusScope.of(context).unfocus();
                    context.read<LocationBloc>().add(SelectLocation(place));
                  },
                );
              },
            ),

            // Floating Action Buttons
            Positioned(
              right: 20,
              bottom: 120,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'sos_btn',
                    backgroundColor: Colors.red,
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is AuthAuthenticated) {
                        SafetyService.triggerSOS(authState.user.name, null);
                      }
                    },
                    child: const Icon(Icons.warning, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  FloatingActionButton(
                    heroTag: 'location_btn',
                    backgroundColor: Colors.white,
                    onPressed: () =>
                        context.read<LocationBloc>().add(LoadMap()),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ],
              ),
            ),

            // Nearby Riders List Sheet
            BlocBuilder<RideBloc, RideState>(
              builder: (context, rideState) {
                if (rideState is! RideActive && rideState is! RideSearching) {
                  return BlocBuilder<LocationBloc, LocationState>(
                    builder: (context, locState) {
                      LatLng? studentPos;
                      if (locState is MapLoaded) {
                        studentPos = locState.currentPosition;
                      } else if (locState is RouteLoaded) {
                        studentPos = locState.pickupLocation;
                      }

                      if (rideState.nearbyRiders.isNotEmpty &&
                          studentPos != null) {
                        return NearbyRidersSheet(
                          riders: rideState.nearbyRiders,
                          studentPos: studentPos,
                          locState: locState,
                          onRiderTap: (rider) {
                            if (rider.lastLocation != null) {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(
                                    rider.lastLocation!.latitude,
                                    rider.lastLocation!.longitude,
                                  ),
                                ),
                              );
                            }
                          },
                          onRequestTap: (state) {
                            if (state is RouteLoaded) {
                              _showConfirmBottomSheet(context, state);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a destination first',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Searching and Active Trip Overlays
            BlocBuilder<RideBloc, RideState>(
              builder: (context, state) {
                if (state is RideSearching) {
                  return SearchingOverlay(
                    ride: state.ride,
                    onCancel: () => context.read<RideBloc>().add(
                      CancelRide(state.ride.rideId),
                    ),
                  );
                } else if (state is RideActive) {
                  return ActiveTripPanel(
                    ride: state.ride,
                    onCallPressed: () {},
                    onSafetyPressed: () {
                      final BaseUserModel? driver = state.nearbyRiders
                          .firstWhere(
                            (r) => r.uid == state.ride.riderId,
                            orElse: () => throw 'Driver not found',
                          );
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                        ),
                        builder: (context) => SafetyToolkitWidget(
                          ride: state.ride,
                          driver: driver,
                        ).buildSafetySheet(context),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Safety Toolkit Floating Button (only when active)
            BlocBuilder<RideBloc, RideState>(
              builder: (context, rideState) {
                if (rideState is RideActive) {
                  final BaseUserModel? driver = rideState.nearbyRiders
                      .firstWhere(
                        (r) => r.uid == rideState.ride.riderId,
                        orElse: () => throw 'Driver not found',
                      );

                  return Positioned(
                    right: 20,
                    bottom: 240,
                    child: SafetyToolkitWidget(
                      ride: rideState.ride,
                      driver: driver,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
