import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'models/doctor.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/quick_login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/medications/medications_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/scanner/scanner_screen.dart';
import 'screens/doctors/doctors_screen.dart';
import 'screens/doctors/doctor_detail_screen.dart';
import 'screens/doctors/appointments_screen.dart';
import 'screens/advisor/advisor_screen.dart';
import 'screens/smartwatch/smartwatch_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';

class MediCoreApp extends StatelessWidget {
  const MediCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final GoRouter router = GoRouter(
      initialLocation: authProvider.isLoggedIn ? '/dashboard' : '/login',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/quick-login';

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }
        if (isLoggedIn && isAuthRoute) {
          return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/quick-login',
          builder: (context, state) => const QuickLoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return ShellScreen(
              location: state.matchedLocation,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/medications',
              builder: (context, state) => const MedicationsScreen(),
            ),
            GoRoute(
              path: '/documents',
              builder: (context, state) => const DocumentsScreen(),
            ),
            GoRoute(
              path: '/scanner',
              builder: (context, state) => const ScannerScreen(),
            ),
            GoRoute(
              path: '/doctors',
              builder: (context, state) => const DoctorsScreen(),
            ),
            GoRoute(
              path: '/doctors/detail',
              builder: (context, state) {
                final doctor = state.extra as Doctor?;
                if (doctor == null) {
                  return const DoctorsScreen();
                }
                return DoctorDetailScreen(doctor: doctor);
              },
            ),
            GoRoute(
              path: '/doctors/appointments',
              builder: (context, state) => const AppointmentsScreen(),
            ),
            GoRoute(
              path: '/advisor',
              builder: (context, state) => const AdvisorScreen(),
            ),
            GoRoute(
              path: '/smartwatch',
              builder: (context, state) => const SmartwatchScreen(),
            ),
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'MediCore AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
