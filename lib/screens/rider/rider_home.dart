import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../models/rider_model.dart';
import '../../logic/ride/ride_bloc.dart';
import '../../logic/wallet/wallet_bloc.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../wallet/wallet_screen.dart';
import '../shared/ride_history_screen.dart';
import '../verification/verification_wizard.dart';
import '../../core/widgets/global_error_listener.dart';
import 'widgets/rider_status_card.dart';
import 'widgets/rider_earnings_card.dart';
import 'widgets/ride_request_item.dart';
import 'widgets/active_trip_view.dart';
import 'widgets/ride_request_alert.dart';

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
    _mapController?.dispose();
    super.dispose();
  }

  void _startLocationStreaming(String riderId) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          context.read<RideBloc>().add(
            UpdateRiderLocation(
              riderId,
              GeoPoint(position.latitude, position.longitude),
            ),
          );
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
    return GlobalErrorListener(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = authState.user;
          // Ensure wallet is loaded
          context.read<WalletBloc>().add(LoadWallet());

          // Security Check: Enforce Verification Flow
          if (user is RiderModel && !user.isVerified) {
            return const VerificationWizard();
          }

          return BlocListener<RideBloc, RideState>(
            listenWhen: (previous, current) {
              if (current is RiderBrowsing && current.openRides.isNotEmpty) {
                if (previous is! RiderBrowsing ||
                    previous.openRides.length < current.openRides.length) {
                  return true;
                }
              }
              return false;
            },
            listener: (context, rideState) {
              if (rideState is RiderBrowsing &&
                  rideState.openRides.isNotEmpty) {
                final latestRide = rideState.openRides.last;
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isDismissible: true,
                  isScrollControlled: true,
                  builder: (context) => RideRequestAlert(
                    ride: latestRide,
                    onAccept: () {
                      context.read<RideBloc>().add(
                        AcceptRide(latestRide.rideId),
                      );
                      Navigator.pop(context);
                    },
                    onDecline: () => Navigator.pop(context),
                  ),
                );
              }
            },
            child: BlocBuilder<RideBloc, RideState>(
              builder: (context, rideState) {
                return Scaffold(
                  backgroundColor: const Color(0xFFF5F7F9),
                  appBar: AppBar(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rider Dashboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Welcome, ${user.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                  ),
                  drawer: _buildDrawer(context),
                  body: _buildBody(context, rideState, user.uid),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF004D40)),
            child: Center(
              child: Text(
                'Nsuride Rider',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
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
                  builder: (context) => const RideHistoryScreen(),
                ),
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
    );
  }

  Widget _buildBody(BuildContext context, RideState state, String riderId) {
    if (state is RideActive) {
      return ActiveTripView(
        ride: state.ride,
        onComplete: () {
          context.read<RideBloc>().add(CompleteRide(state.ride.rideId));
        },
        onSOS: () {
          // SOS logic already handled in safety toolkit or similar
        },
        onMapCreated: (controller) => _mapController = controller,
      );
    }

    final bool isOnline = _isOnline(state);

    return Column(
      children: [
        RiderStatusCard(
          isOnline: isOnline,
          onToggle: (val) {
            if (val) {
              context.read<RideBloc>().add(GoOnline());
              _startLocationStreaming(riderId);
            } else {
              context.read<RideBloc>().add(GoOffline());
              _stopLocationStreaming();
            }
          },
        ),
        BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            String earnings = '₦ 0.00';
            String trips = '0';
            
            if (state is WalletLoaded) {
              earnings = '₦ ${state.balance.toStringAsFixed(2)}';
              trips = state.transactions.length.toString();
            }
            
            return RiderEarningsCard(
              totalEarnings: earnings,
              totalTrips: trips,
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.electric_bike, color: Color(0xFF004D40)),
              SizedBox(width: 10),
              Text(
                'Available Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(child: _buildRequestList(context, state)),
      ],
    );
  }

  Widget _buildRequestList(BuildContext context, RideState state) {
    if (state is RiderBrowsing) {
      if (state.openRides.isEmpty) {
        return _buildEmptyState(
          'No active requests nearby.\nCheck back in a moment!',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.openRides.length,
        itemBuilder: (context, index) {
          final request = state.openRides[index];
          return RideRequestItem(
            request: request,
            onAccept: () {
              context.read<RideBloc>().add(AcceptRide(request.rideId));
            },
          );
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
          Icon(
            Icons.directions_bike_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
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
}
