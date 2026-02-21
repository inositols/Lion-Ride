import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/ride/ride_bloc.dart';
import 'ride_request_item.dart';

class RiderRequestList extends StatelessWidget {
  final RideState state;

  const RiderRequestList({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state is RiderBrowsing) {
      final browsingState = state as RiderBrowsing;
      if (browsingState.openRides.isEmpty) {
        return _buildEmptyState(
          'No active requests nearby.\nCheck back in a moment!',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: browsingState.openRides.length,
        itemBuilder: (context, index) {
          final request = browsingState.openRides[index];
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
