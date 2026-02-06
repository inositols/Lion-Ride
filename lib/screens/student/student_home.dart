import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../logic/location/location_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../repositories/location_repository.dart';
import '../wallet/wallet_screen.dart';
import '../shared/ride_history_screen.dart';
import '../../core/services/safety_service.dart';
import '../../logic/ride/ride_bloc.dart';
import '../../models/ride_model.dart';
import 'package:intl/intl.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(LoadMap());
    context.read<RideBloc>().add(MonitorNearbyRiders());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
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
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ride Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('From:'),
                  Text(
                    routeState.pickup,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('To:'),
                  Text(
                    routeState.dropoff,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Distance:'),
                  Text('${routeState.distance.toStringAsFixed(1)} km'),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Fare:', style: TextStyle(fontSize: 18)),
                  Text(
                    '₦${routeState.price}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final rideId =
                      'ride_${DateTime.now().millisecondsSinceEpoch}';
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    final student = authState.user;
                    final ride = RideModel(
                      rideId: rideId,
                      studentId: student.uid,
                      pickupLat: routeState.pickupLocation.latitude,
                      pickupLng: routeState.pickupLocation.longitude,
                      dropoffLat: routeState.dropoffLocation.latitude,
                      dropoffLng: routeState.dropoffLocation.longitude,
                      pickupAddress: routeState.pickup,
                      dropoffAddress: routeState.dropoff,
                      cost: routeState.price.toDouble(),
                      status: 'searching',
                      timestamp: DateTime.now(),
                    );

                    context.read<RideBloc>().add(RequestRide(ride));
                    Navigator.pop(bottomSheetContext);
                  }
                },
                child: const Text('REQUEST RIDE'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF004D40)),
              child: Center(
                child: Text(
                  'Nsuride',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('My Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Ride History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RideHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background: Full-screen Google Map
          BlocListener<RideBloc, RideState>(
            listener: (context, state) {
              if (state is RideSearching) {
                _showSearchingDialog(context);
              } else if (state is RideActive) {
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Driver Found! Your ride is on the way.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is RideError) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: BlocConsumer<LocationBloc, LocationState>(
              listener: (context, state) {
                if (state is LocationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
                Set<Polyline> polylines = {};

                if (state is MapLoaded) {
                  initialPos = state.currentPosition;
                  markers.add(
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: initialPos,
                    ),
                  );

                  for (var landmark in LocationRepository.mockLandmarks) {
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
                    // Create a fresh set of markers starting with the base markers
                    Set<Marker> finalMarkers = Set.from(markers);

                    debugPrint(
                        'Ghost Riders: Received ${rideState.nearbyRiders.length} riders');

                    // Add nearby riders ("Ghost Riders")
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
                              BitmapDescriptor.hueBlue, // Rider Blue
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
                        finalMarkers.add(
                          Marker(
                            markerId: const MarkerId('rider'),
                            position: LatLng(
                              rideState.riderLocation!.latitude,
                              rideState.riderLocation!.longitude,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue,
                            ),
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
                      polylines: polylines,
                      zoomControlsEnabled: false,
                    );
                  },
                );
              },
            ),
          ),

          // Overlay: Floating "Where to?" search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        return Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Where to?',
                                prefixIcon: IconButton(
                                  icon: const Icon(Icons.menu),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          context.read<LocationBloc>().add(
                                                LoadMap(),
                                              );
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (val) {
                                context.read<LocationBloc>().add(
                                      SearchDestination(val),
                                    );
                              },
                            ),
                            // Search Results List
                            BlocBuilder<LocationBloc, LocationState>(
                              builder: (context, state) {
                                if (state is MapLoaded &&
                                    state.searchResults.isNotEmpty) {
                                  return Material(
                                    elevation: 5,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 300,
                                      ),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: state.searchResults.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final place =
                                              state.searchResults[index];
                                          return ListTile(
                                            leading: const Icon(
                                              Icons.location_on,
                                              color: Color(0xFFFFC107),
                                            ),
                                            title: Text(place.name),
                                            onTap: () {
                                              _searchController.text =
                                                  place.name;
                                              FocusScope.of(context).unfocus();
                                              context.read<LocationBloc>().add(
                                                    SelectLocation(place),
                                                  );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Action Buttons (SOS and My Location)
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
                      SafetyService.triggerSOS(authState.user.name,null);
                    }
                  },
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
                const SizedBox(height: 15),
                FloatingActionButton(
                  heroTag: 'location_btn',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    context.read<LocationBloc>().add(LoadMap());
                  },
                  child: const Icon(Icons.my_location, color: Color(0xFF004D40)),
                ),
              ],
            ),
          ),

          // Searching or Trip Overlays
          BlocBuilder<RideBloc, RideState>(
            builder: (context, state) {
              if (state is RideSearching) {
                return _buildSearchingOverlay(context, state.ride);
              } else if (state is RideActive) {
                return _buildActiveTripPanel(context, state.ride);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _showSearchingDialog(BuildContext context) {
    // We handle the searching view with the overlay instead of a dialog
  }

  Widget _buildSearchingOverlay(BuildContext context, RideModel ride) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 30),
          const Text(
            'Searching for Drivers...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Offer: ₦${ride.cost.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              context.read<RideBloc>().add(CancelRide(ride.rideId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('CANCEL REQUEST'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripPanel(BuildContext context, RideModel ride) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF004D40),
                  child: Icon(Icons.person, color: Colors.white, size: 35),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR RIDER IS ON THE WAY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Verified Rider',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () {},
                ),
              ],
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trip Cost',
                        style: TextStyle(color: Colors.grey)),
                    Text('₦${ride.cost}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Safety check or details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Safety Toolkit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
