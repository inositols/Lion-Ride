import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'repositories/auth_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/wallet_repository.dart';
import 'repositories/ride_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/location/location_bloc.dart';
import 'logic/wallet/wallet_bloc.dart';
import 'logic/ride/ride_bloc.dart';
import 'root_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authRepository = AuthRepository();
  final locationRepository = LocationRepository();
  final walletRepository = WalletRepository();
  final rideRepository = RideRepository();

  runApp(
    MyApp(
      authRepository: authRepository,
      locationRepository: locationRepository,
      walletRepository: walletRepository,
      rideRepository: rideRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final LocationRepository locationRepository;
  final WalletRepository walletRepository;
  final RideRepository rideRepository;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.locationRepository,
    required this.walletRepository,
    required this.rideRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: locationRepository),
        RepositoryProvider.value(value: walletRepository),
        RepositoryProvider.value(value: rideRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: authRepository)
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) =>
                LocationBloc(locationRepository: locationRepository),
          ),
          BlocProvider(
            create: (context) => WalletBloc(
              walletRepository: walletRepository,
              authRepository: authRepository,
            )..add(LoadWallet()),
          ),
          BlocProvider(
            create: (context) => RideBloc(
              rideRepository: rideRepository,
              authRepository: authRepository,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Nsuride',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const RootWrapper(),
        ),
      ),
    );
  }
}
