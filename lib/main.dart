import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/logic/auth_bloc.dart';
import 'features/auth/logic/auth_event.dart';
import 'features/workout/logic/active_workout_cubit.dart';
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

  runApp(const NutrifitApp());
}

/// Root widget for the Nutrifit application.
///
/// Wraps the widget tree with [RepositoryProvider] and [BlocProvider]
/// so that [AuthRepository] and [AuthBloc] are available app-wide.
class NutrifitApp extends StatefulWidget {
  const NutrifitApp({super.key});

  @override
  State<NutrifitApp> createState() => _NutrifitAppState();
}

class _NutrifitAppState extends State<NutrifitApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AuthRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<AuthRepository>(),
            )..add(const AuthCheckRequested()),
          ),
          BlocProvider(
            create: (_) => ActiveWorkoutCubit(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Nutrifit',
          debugShowCheckedModeBanner: false,

          // ── Theme ──
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // ── Router ──
          routerConfig: _router,
        ),
      ),
    );
  }
}
