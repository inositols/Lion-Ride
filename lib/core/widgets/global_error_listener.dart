import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/ride/ride_bloc.dart';
import '../../logic/wallet/wallet_bloc.dart';
import '../../logic/location/location_bloc.dart';
import '../../logic/verification/verification_bloc.dart';

class GlobalErrorListener extends StatelessWidget {
  final Widget child;
  final Logger _logger = Logger();

  GlobalErrorListener({super.key, required this.child});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              _logger.e("Module Error: ${state.message}");
              _showErrorSnackBar(context, state.message);
            }
          },
        ),
        BlocListener<RideBloc, RideState>(
          listener: (context, state) {
            if (state is RideError) {
              _logger.e("Module Error: ${state.message}");
              _showErrorSnackBar(context, state.message);
            }
          },
        ),
        BlocListener<WalletBloc, WalletState>(
          listener: (context, state) {
            if (state is WalletError) {
              _logger.e("Module Error: ${state.message}");
              _showErrorSnackBar(context, state.message);
            } else if (state is PaymentFailure) {
              _logger.e("Module Error: ${state.message}");
              _showErrorSnackBar(context, state.message);
            }
          },
        ),
        BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            if (state is LocationError) {
              _logger.e("Module Error: ${state.message}");
              _showErrorSnackBar(context, state.message);
            }
          },
        ),
        BlocListener<VerificationBloc, VerificationState>(
          listener: (context, state) {
            if (state is VerificationFailure) {
              _logger.e("Module Error: ${state.error}");
              _showErrorSnackBar(context, state.error);
            }
          },
        ),
      ],
      child: child,
    );
  }
}
