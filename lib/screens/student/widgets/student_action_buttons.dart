import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/location/location_bloc.dart';
import '../../../core/services/safety_service.dart';

class StudentActionButtons extends StatelessWidget {
  const StudentActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
            onPressed: () => context.read<LocationBloc>().add(LoadMap()),
            child: const Icon(
              Icons.my_location,
              color: Color(0xFF004D40),
            ),
          ),
        ],
      ),
    );
  }
}
