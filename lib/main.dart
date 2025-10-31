import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/activity_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/auth_provider.dart';
import 'screen/activities_screen.dart';
import 'screen/admin_dashboard.dart';
import 'screen/admin_manage_announcements.dart';
import 'screen/admin_manage_reports.dart';
import 'screen/admin_manage_users.dart';
import 'screen/announcements_screen.dart';
import 'screen/dashboard_screen.dart';
import 'screen/login_screen.dart';
import 'screen/payments_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/register_screen.dart';
import 'screen/reports_screen.dart';
import 'screen/splash_screen.dart';
import 'screen/umkm_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
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
          '/admin': (context) => const AdminDashboard(),
          '/admin/announcements': (context) => const AdminManageAnnouncements(),
          '/admin/users': (context) => const AdminManageUsers(),
          '/admin/reports': (context) => const AdminManageReports(),
          '/announcements': (context) => const AnnouncementsScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/payments': (context) => const PaymentsScreen(),
          '/activities': (context) => const ActivitiesScreen(),
          '/umkm': (context) => const UMKMScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
