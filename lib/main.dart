import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/announcement_provider.dart';
import 'providers/auth_provider.dart';
import 'screen admin/admin_dashboard.dart';
import 'screen user/activities_screen.dart';
import 'screen user/announcements_screen.dart';
import 'screen user/dashboard_screen.dart';
import 'screen user/login_screen.dart';
import 'screen user/payments_screen.dart';
import 'screen user/profile_screen.dart';
import 'screen user/register_screen.dart';
import 'screen user/reports_screen.dart';
import 'screen user/splash_screen.dart';
import 'screen user/umkm_screen.dart';

void main() {
  // Route framework errors to the console
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Show a full-screen error widget with stack trace for easier debugging
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final exception = details.exceptionAsString();
    final stack = details.stack?.toString() ?? 'No stack available.';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('App Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            '''Exception:\n$exception\n\nStack trace:\n$stack''',
          ),
        ),
      ),
    );
  };

  // Catch all unhandled errors
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stack) {
      // Ensure the error is visible in console as well
      debugPrint('Uncaught error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
      ],
      child: MaterialApp(
        title: 'Warga Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF3B82F6),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF1F2937)),
            titleTextStyle: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/announcements': (context) => const AnnouncementsScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/payments': (context) => const PaymentsScreen(),
          '/activities': (context) => const ActivitiesScreen(),
          '/umkm': (context) => const UMKMScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/admin-dashboard': (context) => const AdminDashboard(),
        },
      ),
    );
  }
}
