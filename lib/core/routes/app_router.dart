import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/logic/auth_bloc.dart';
import '../../features/auth/logic/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/profile_setup/profile_setup_screen.dart';
import '../../features/auth/profile_setup/goal_selection_screen.dart';
import '../../features/auth/profile_setup/welcome_success_screen.dart';
import '../../features/onboarding/get_started_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/user/user_coach/chat_screen.dart';
import '../../features/chat/presentation/chat_room_screen.dart';
import '../../features/coach/main_nav/coach_main_screen.dart';
import '../../features/coach/client_detail/client_detail_screen.dart';
import '../../features/user/user_coach/coach_screen.dart';
import '../../features/user/user_coach/presentation/notification_screen.dart';
import '../../features/user/main_nav/screens/main_navigation_screen.dart';
import '../../features/user/nutrition/data/repositories/nutrition_repository.dart';
import '../../features/user/nutrition/logic/food_bloc.dart';
import '../../features/user/nutrition/logic/food_event.dart';
import '../../features/user/nutrition/logic/nutrition_bloc.dart';
import '../../features/user/nutrition/logic/nutrition_event.dart';
import '../../features/user/nutrition/logic/water_cubit.dart';
import '../../features/user/nutrition/presentation/screens/food_collection_screen.dart';
import '../../features/user/nutrition/presentation/screens/food_search_screen.dart';
import '../../features/user/nutrition/presentation/screens/meal_detail_screen.dart';
import '../../features/user/nutrition/presentation/screens/water_tracking_screen.dart';
import '../../features/user/workout/data/models/exercise_model.dart';
import '../../features/user/workout/data/models/routine_model.dart';
import '../../features/user/workout/data/models/workout_plan_model.dart';
import '../../features/user/workout/data/repositories/workout_repository.dart';
import '../../features/user/workout/logic/active_exercise_cubit.dart';
import '../../features/user/workout/logic/exercise_library_bloc.dart';
import '../../features/user/workout/logic/exercise_library_event.dart';
import '../../features/user/workout/logic/plan_detail_cubit.dart';
import '../../features/user/workout/logic/workout_template_bloc.dart';
import '../../features/user/workout/logic/workout_template_event.dart';
import '../../features/user/workout/presentation/screens/active_exercise_detail_screen.dart';
import '../../features/user/workout/presentation/screens/active_workout_screen.dart';
import '../../features/user/workout/presentation/screens/create_plan_screen.dart';
import '../../features/user/workout/presentation/screens/exercise_library_screen.dart';
import '../../features/user/workout/presentation/screens/plan_detail_screen.dart';
import '../../features/user/workout/presentation/screens/routine_detail_screen.dart';
import '../../features/user/workout/presentation/screens/workout_template_list_screen.dart';


/// Centralized router configuration using [GoRouter].
/// Handles auth-based redirects and declares all application routes.
class AppRouter {
  const AppRouter._();

  // ───────────────────────── Route Paths ─────────────────────────

  static const String getStarted = '/get-started';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String chat = '/chat';
  static const String foodLibrary = '/food-library';
  static const String mealDetail = '/meal-detail';
  static const String waterTracking = '/water-tracking';
  static const String routineDetail = '/routine-detail';
  static const String activeWorkout = '/active-workout';
  static const String exerciseLibrary = '/exercise-library';
  static const String createPlan = '/create-plan';
  // --- Mới: Templates cho HLV ---
  static const String createTemplate = '/create-template';
  static const String workoutTemplates = '/workout-templates';
  static const String planDetail = '/plan-detail';
  static const String exerciseDetail = '/exercise-detail';
  static const String foodCollection = '/food-collection';
  static const String coachMain = '/coach-main';
  static const String clientDetail = '/client-detail';
  static const String notifications = '/notifications';
  static const String coach = '/coach';
  static const String chatRoom = '/chat-room';
  static const String profileSetup = '/profile-setup';
  static const String goalSelection = '/goal-selection';
  static const String welcomeSuccess = '/welcome-success';

  // ───────────────────────── Router Instance ─────────────────────────

  /// Creates a [GoRouter] that reacts to [AuthBloc] state changes.
  ///
  /// [hasSeenOnboarding] controls the initial route:
  /// - `false` → `/get-started` (first launch)
  /// - `true`  → `/login`
  static GoRouter createRouter(
    AuthBloc authBloc, {
    bool hasSeenOnboarding = true,
  }) {
    return GoRouter(
      initialLocation: hasSeenOnboarding ? login : getStarted,
      debugLogDiagnostics: true,
      routes: _routes,
      redirect: (context, state) => _guardRedirect(context, state, authBloc),
      refreshListenable: _AppRouterNotifier(authBloc.stream),
      errorBuilder: (context, state) => const _ErrorPage(),
    );
  }

  /// Global redirect logic based on [AuthBloc] state and user roles.
  static String? _guardRedirect(
    BuildContext context,
    GoRouterState state,
    AuthBloc authBloc,
  ) {
    final authState = authBloc.state;
    final String loc = state.matchedLocation;

    final bool isOnAuthPage = loc == login || loc == register;
    final bool isOnOnboarding = loc == getStarted || loc == onboarding;
    final bool isOnProfileSetup =
        loc == profileSetup || loc == goalSelection || loc == welcomeSuccess;

    // 1. Unauthenticated users may freely view onboarding / auth pages.
    if (authState is AuthUnauthenticated) {
      if (!isOnAuthPage && !isOnOnboarding) return login;
      return null;
    }

    // 2. Newly registered user → allow profile-setup pages only.
    if (authState is AuthNewlyRegistered) {
      if (isOnProfileSetup) return null;
      if (isOnAuthPage || isOnOnboarding) return profileSetup;
      return profileSetup;
    }

    // 3. Authenticated users should never see onboarding or auth pages.
    if (authState is AuthAuthenticated) {
      final isCoach = authState.user.role == 'coach';

      if (isOnAuthPage || isOnOnboarding || isOnProfileSetup) {
        return isCoach ? coachMain : main;
      }
      if (isCoach && loc == main) return coachMain;
      if (!isCoach && loc == coachMain) return main;
    }

    // No redirect needed.
    return null;
  }

  // ───────────────────────── Routes ─────────────────────────

  static final List<RouteBase> _routes = <RouteBase>[
    GoRoute(
      path: getStarted,
      name: 'getStarted',
      builder: (context, state) => const GetStartedScreen(),
    ),
    GoRoute(
      path: onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
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
      path: profileSetup,
      name: 'profileSetup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: goalSelection,
      name: 'goalSelection',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return GoalSelectionScreen(
          gender: data['gender'] as String? ?? '',
          birthDate: data['birthDate'] as DateTime?,
          weight: data['weight'] as double? ?? 0,
          height: data['height'] as double? ?? 0,
        );
      },
    ),
    GoRoute(
      path: welcomeSuccess,
      name: 'welcomeSuccess',
      builder: (context, state) => const WelcomeSuccessScreen(),
    ),
    GoRoute(
      path: main,
      name: 'main',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: coachMain,
      name: 'coachMain',
      builder: (context, state) => const CoachMainScreen(),
    ),
    GoRoute(
      path: '$clientDetail/:id',
      name: 'clientDetail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ClientDetailScreen(
          clientId: state.pathParameters['id'] ?? '',
          clientName: extra['clientName'] as String? ?? 'Học viên',
          clientGoal: extra['clientGoal'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: notifications,
      name: 'notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: coach,
      name: 'coach',
      builder: (context, state) => const CoachScreen(),
    ),
    GoRoute(
      path: chat,
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: chatRoom,
      name: 'chatRoom',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ChatRoomScreen(
          peerId: extra['peerId'] as String? ?? '',
          peerName: extra['peerName'] as String? ?? 'Chat',
          peerAvatarUrl: extra['peerAvatarUrl'] as String?,
        );
      },
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
          planId: extra['planId'] as String?,
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

/// Notifies [GoRouter] whenever the [AuthBloc] state changes
/// so that [redirect] re-evaluates.
class _AppRouterNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AppRouterNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) {
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
