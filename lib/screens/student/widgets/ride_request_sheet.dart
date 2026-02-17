import 'package:flutter/material.dart';
import 'package:nsuride_mobile/logic/location/location_bloc.dart';

class RideRequestSheet extends StatelessWidget {
  final RouteLoaded routeState;
  final VoidCallback onRequestConfirmed;

  const RideRequestSheet({
    super.key,
    required this.routeState,
    required this.onRequestConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ride Details',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
            onPressed: onRequestConfirmed,
            child: const Text('REQUEST RIDE'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
