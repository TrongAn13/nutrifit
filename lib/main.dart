import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/logic/auth_bloc.dart';
import 'features/auth/logic/auth_event.dart';
import 'features/trainee/workout/data/repositories/workout_repository.dart';
import 'features/trainee/workout/logic/active_workout_cubit.dart';
import 'firebase_options.dart';

/// Application entry point.
///
/// Initialization sequence:
/// 1. Ensure Flutter bindings are ready.
/// 2. Initialize Firebase with platform-specific options.
/// 3. Enable Firestore offline persistence.
/// 4. Launch the root widget with AuthBloc.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Locale initialization for intl package ──
  await initializeDateFormatting('vi');

  // ── Firebase ──
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── App Check ──
  // Uses debug provider on debug builds (emulator) and Play Integrity on release.
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // ── Firestore offline persistence ──
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final authRepository = AuthRepository();
  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(const AuthCheckRequested());

  runApp(NutrifitApp(
    authRepository: authRepository,
    authBloc: authBloc,
  ));
}


/// Root widget for the Nutrifit application.
///
/// Wraps the widget tree with [RepositoryProvider] and [BlocProvider]
/// so that [AuthRepository] and [AuthBloc] are available app-wide.
class NutrifitApp extends StatefulWidget {
  final AuthRepository authRepository;
  final AuthBloc authBloc;

  const NutrifitApp({
    super.key,
    required this.authRepository,
    required this.authBloc,
  });

  @override
  State<NutrifitApp> createState() => _NutrifitAppState();
}

class _NutrifitAppState extends State<NutrifitApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.authBloc);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: widget.authRepository,
        ),
        RepositoryProvider<WorkoutRepository>(
          create: (_) => WorkoutRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: widget.authBloc,
          ),
          BlocProvider(
            create: (context) => ActiveWorkoutCubit(
              workoutRepository: context.read<WorkoutRepository>(),
            ),
          ),
          BlocProvider(
            create: (_) => ThemeCubit(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'Nutrifit',
              debugShowCheckedModeBanner: false,

              // ── Theme ──
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,

              // Keep a dark fallback behind routed pages to avoid white flashes
              // during rapid transitions or dropped frames.
              builder: (context, child) {
                return ColoredBox(
                  color: Color(0xFF060708),
                  child: child ?? const SizedBox.shrink(),
                );
              },

              // ── Router ──
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
