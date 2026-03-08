import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/coach/presentation/screens/chat_screen.dart';
import '../../features/main_nav/screens/main_navigation_screen.dart';
import '../../features/nutrition/data/repositories/nutrition_repository.dart';
import '../../features/nutrition/logic/food_bloc.dart';
import '../../features/nutrition/logic/food_event.dart';
import '../../features/nutrition/logic/nutrition_bloc.dart';
import '../../features/nutrition/logic/nutrition_event.dart';
import '../../features/nutrition/presentation/screens/food_search_screen.dart';
import '../../features/nutrition/presentation/screens/meal_detail_screen.dart';
import '../../features/nutrition/presentation/screens/water_tracking_screen.dart';
import '../../features/nutrition/presentation/screens/food_collection_screen.dart';
import '../../features/nutrition/logic/water_cubit.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/workout/data/models/exercise_model.dart';
import '../../features/workout/data/models/routine_model.dart';
import '../../features/workout/data/models/workout_plan_model.dart';
import '../../features/workout/data/repositories/workout_repository.dart';
import '../../features/workout/logic/active_exercise_cubit.dart';
import '../../features/workout/logic/create_plan_cubit.dart';
import '../../features/workout/logic/exercise_library_bloc.dart';
import '../../features/workout/logic/exercise_library_event.dart';
import '../../features/workout/logic/plan_detail_cubit.dart';
import '../../features/workout/logic/workout_template_bloc.dart';
import '../../features/workout/logic/workout_template_event.dart';
import '../../features/workout/presentation/screens/active_exercise_detail_screen.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';
import '../../features/workout/presentation/screens/create_plan_screen.dart';
import '../../features/workout/presentation/screens/create_routine_screen.dart';
import '../../features/workout/presentation/screens/exercise_library_screen.dart';
import '../../features/workout/presentation/screens/plan_detail_screen.dart';
import '../../features/workout/presentation/screens/routine_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_template_list_screen.dart';

/// Centralized router configuration using [GoRouter].
/// Handles auth-based redirects and declares all application routes.
class AppRouter {
  const AppRouter._();

  // ───────────────────────── Route Paths ─────────────────────────

  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String editProfile = '/edit-profile';
  static const String chat = '/chat';
  static const String foodLibrary = '/food-library';
  static const String mealDetail = '/meal-detail';
  static const String waterTracking = '/water-tracking';
  static const String routineDetail = '/routine-detail';
  static const String activeWorkout = '/active-workout';
  static const String exerciseLibrary = '/exercise-library';
  static const String createPlan = '/create-plan';
  static const String createRoutine = '/create-routine';
  static const String workoutTemplates = '/workout-templates';
  static const String planDetail = '/plan-detail';
  static const String exerciseDetail = '/exercise-detail';
  static const String foodCollection = '/food-collection';

  // ───────────────────────── Router Instance ─────────────────────────

  /// Creates a [GoRouter] that reacts to Firebase auth state changes.
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: login,
      debugLogDiagnostics: true,
      routes: _routes,
      redirect: _guardRedirect,
      refreshListenable: _AuthNotifier(),
      errorBuilder: (context, state) => const _ErrorPage(),
    );
  }

  /// Global redirect logic based on authentication state.
  static String? _guardRedirect(
    BuildContext context,
    GoRouterState state,
  ) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isOnAuthPage =
        state.matchedLocation == login || state.matchedLocation == register;

    // Not logged in → force to login page.
    if (!isLoggedIn && !isOnAuthPage) return login;

    // Logged in but still on auth page → send to main.
    if (isLoggedIn && isOnAuthPage) return main;

    // No redirect needed.
    return null;
  }

  // ───────────────────────── Routes ─────────────────────────

  static final List<RouteBase> _routes = <RouteBase>[
    GoRoute(
      path: login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: main,
      name: 'main',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: editProfile,
      name: 'editProfile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: chat,
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: foodLibrary,
      name: 'foodLibrary',
      builder: (context, state) {
        final mealName = state.uri.queryParameters['mealName'] ?? 'Bữa ăn';
        final dateParam = state.uri.queryParameters['date'];
        final date = dateParam != null
            ? DateTime.tryParse(dateParam) ?? DateTime.now()
            : DateTime.now();
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => FoodBloc(
                nutritionRepository: NutritionRepository(),
              )..add(const FoodLoadRequested()),
            ),
            BlocProvider(
              create: (_) => NutritionBloc(
                nutritionRepository: NutritionRepository(),
              )..add(NutritionLoadRequested(date)),
            ),
          ],
          child: FoodSearchScreen(mealName: mealName, date: date),
        );
      },
    ),
    GoRoute(
      path: mealDetail,
      name: 'mealDetail',
      builder: (context, state) {
        final mealName = state.uri.queryParameters['mealName'] ?? 'Bữa ăn';
        final dateParam = state.uri.queryParameters['date'];
        final date = dateParam != null
            ? DateTime.tryParse(dateParam) ?? DateTime.now()
            : DateTime.now();
        return BlocProvider(
          create: (_) => NutritionBloc(
            nutritionRepository: NutritionRepository(),
          )..add(NutritionLoadRequested(date)),
          child: MealDetailScreen(mealName: mealName, date: date),
        );
      },
    ),
    GoRoute(
      path: waterTracking,
      name: 'waterTracking',
      builder: (context, state) {
        // If the context already has a WaterCubit (e.g., from MainNavigationScreen),
        // we should try to use it or wrap it in a provider.
        // However, GoRouter replaces the widget tree, so context.read might not find it
        // unless it's provided above the MaterialApp or passed as an extra.
        // For simplicity, since WaterCubit syncs via NutritionRepository Firestore,
        // it's acceptable for WaterTrackingScreen to have its own instance. It will
        // read from and write to the same Firestore document.
        // But to make the Dashboard update immediately when we POP back, the Dashboard's
        // WaterCubit needs to reload. A better approach is to reload the Dashboard's
        // WaterCubit when returning.
        return BlocProvider(
          create: (_) => WaterCubit()..load(),
          child: const WaterTrackingScreen(),
        );
      },
    ),
    GoRoute(
      path: foodCollection,
      name: 'foodCollection',
      builder: (context, state) => const FoodCollectionScreen(),
    ),
    GoRoute(
      path: routineDetail,
      name: 'routineDetail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return RoutineDetailScreen(
          routine: extra['routine'] as RoutineModel,
          planName: extra['planName'] as String,
        );
      },
    ),
    GoRoute(
      path: activeWorkout,
      name: 'activeWorkout',
      builder: (context, state) {
        return const ActiveWorkoutScreen();
      },
    ),
    GoRoute(
      path: exerciseLibrary,
      name: 'exerciseLibrary',
      builder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final isSelection =
            state.uri.queryParameters['mode'] == 'selection';
        return BlocProvider(
          create: (_) => ExerciseLibraryBloc(
            workoutRepository: WorkoutRepository(),
            userId: userId,
          )..add(const ExerciseLibraryLoadRequested()),
          child: ExerciseLibraryScreen(isSelectionMode: isSelection),
        );
      },
    ),
    GoRoute(
      path: createPlan,
      name: 'createPlan',
      builder: (context, state) => const CreatePlanScreen(),
    ),
    GoRoute(
      path: createRoutine,
      name: 'createRoutine',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final userId = FirebaseAuth.instance.currentUser!.uid;
        return BlocProvider(
          create: (_) => CreatePlanCubit(
            workoutRepository: WorkoutRepository(),
            userId: userId,
          ),
          child: CreateRoutineScreen(
            planName: extra['name'] as String,
            planDescription: extra['description'] as String,
            totalWeeks: extra['totalWeeks'] as int,
            trainingDays: (extra['trainingDays'] as List<dynamic>).cast<int>(),
          ),
        );
      },
    ),
    GoRoute(
      path: workoutTemplates,
      name: 'workoutTemplates',
      builder: (context, state) => BlocProvider(
        create: (_) => WorkoutTemplateBloc(
          workoutRepository: WorkoutRepository(),
        )..add(const WorkoutTemplateLoadRequested()),
        child: const WorkoutTemplateListScreen(),
      ),
    ),
    GoRoute(
      path: planDetail,
      name: 'planDetail',
      builder: (context, state) {
        final plan = state.extra as WorkoutPlanModel;
        return BlocProvider(
          create: (_) => PlanDetailCubit(
            workoutRepository: WorkoutRepository(),
            initialPlan: plan,
          ),
          child: const PlanDetailScreen(),
        );
      },
    ),
    GoRoute(
      path: exerciseDetail,
      name: 'exerciseDetail',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        final exercise = args['exercise'] as ExerciseModel;
        final entry = args['entry'] as ExerciseEntry;
        return BlocProvider(
          create: (_) => ActiveExerciseCubit(
            targetSets: entry.sets,
            targetReps: entry.reps,
            restTimeSeconds: entry.restTime,
          ),
          child: ActiveExerciseDetailScreen(
            exercise: exercise,
            entry: entry,
          ),
        );
      },
    ),
  ];
}

/// Notifies [GoRouter] whenever the Firebase auth state changes
/// so that [redirect] re-evaluates.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;

  _AuthNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Fallback page shown when navigation encounters an unknown route.
class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Trang không tồn tại',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.login),
              child: const Text('Quay về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
