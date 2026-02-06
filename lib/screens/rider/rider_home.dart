import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/ride/ride_bloc.dart';
import '../../models/ride_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../wallet/wallet_screen.dart';
import '../shared/ride_history_screen.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  GoogleMapController? _mapController;
  Timer? _locationTimer;

  bool _isOnline(RideState state) {
    return state is RiderBrowsing || state is RideActive;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationStreaming(String riderId) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          context.read<RideBloc>().add(UpdateRiderLocation(
                riderId,
                GeoPoint(position.latitude, position.longitude),
              ));
        }
      } catch (e) {
        // Silently fail or log
      }
    });
  }

  void _stopLocationStreaming() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return BlocConsumer<RideBloc, RideState>(
      listener: (context, state) {
        if (state is RideError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F9),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rider Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Welcome, ${user.name}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: const Color(0xFF004D40),
            foregroundColor: Colors.white,
          ),
          drawer: Drawer(
            child: Column(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Color(0xFF004D40)),
                  child: Center(
                    child: Text(
                      'Nsuride Rider',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('My Wallet'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Ride History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RideHistoryScreen()));
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
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, RideState state) {
    if (state is RideActive) {
      return _buildActiveTripUI(context, state.ride);
    }

    return Column(
      children: [
        _buildStatusHeader(context, state),
        _buildEarningsCard(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.electric_bike, color: Color(0xFF004D40)),
              SizedBox(width: 10),
              Text('Available Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(child: _buildRequestList(context, state)),
      ],
    );
  }

  Widget _buildStatusHeader(BuildContext context, RideState state) {
    final bool isOnline = _isOnline(state);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFE0F2F1) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnline ? const Color(0xFF004D40) : Colors.amber[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOnline ? const Color(0xFF004D40) : Colors.amber[800],
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                isOnline ? 'Searching for trips...' : 'Go online to receive trips',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          Switch.adaptive(
            value: isOnline,
            activeColor: const Color(0xFF004D40),
            onChanged: (val) {
              if (val) {
                context.read<RideBloc>().add(GoOnline());
                final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
                _startLocationStreaming(user.uid);
              } else {
                context.read<RideBloc>().add(GoOffline());
                _stopLocationStreaming();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEarningItem('Total Earnings', '₩0.00', Icons.account_balance_wallet),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildEarningItem('Total Trips', '0', Icons.route),
        ],
      ),
    );
  }

  Widget _buildEarningItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildRequestList(BuildContext context, RideState state) {
    if (state is RiderBrowsing) {
      if (state.openRides.isEmpty) {
        return _buildEmptyState('No active requests nearby.\nCheck back in a moment!');
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.openRides.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(context, state.openRides[index]);
        },
      );
    }

    if (state is RiderOffline) {
      return _buildEmptyState('Go online to see ride requests from students.');
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bike_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RideModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.teal[50], child: const Icon(Icons.person, color: Color(0xFF004D40))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ride Request', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '₦${request.cost.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat.jm().format(request.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Column(
                  children: [
                    Icon(Icons.circle, size: 12, color: Colors.green),
                    SizedBox(height: 4, width: 2, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey))),
                    Icon(Icons.location_on, size: 12, color: Colors.red),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(request.dropoffAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<RideBloc>().add(AcceptRide(request.rideId));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripUI(BuildContext context, RideModel ride) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(ride.pickupLat, ride.pickupLng),
            zoom: 15,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(ride.pickupLat, ride.pickupLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: 'Pickup Location'),
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: LatLng(ride.dropoffLat, ride.dropoffLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: const InfoWindow(title: 'Dropoff Location'),
            ),
          },
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: _buildTripInfoCard(context, ride),
        ),
      ],
    );
  }

  Widget _buildTripInfoCard(BuildContext context, RideModel ride) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFF004D40),
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACTIVE TRIP', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const Text('Pick up Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Earnings: ₦${ride.cost.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildLocationRow(Icons.radio_button_checked, Colors.green, ride.pickupAddress),
            const SizedBox(height: 12),
            _buildLocationRow(Icons.location_on, Colors.red, ride.dropoffAddress),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {}, // Add SOS or Chat logic here
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('SOS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<RideBloc>().add(CompleteRide(ride.rideId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Complete Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
