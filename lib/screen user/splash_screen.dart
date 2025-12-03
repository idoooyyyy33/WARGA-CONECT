import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _particlesController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _particlesAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Scale animation with bounce
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );

    // Particles animation
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..repeat();
    _particlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_particlesController);

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  print('🚀 SPLASH: Starting auth check...'); // DEBUG
  await authProvider.checkAuthStatus();
  print('🚀 SPLASH: Auth check complete'); // DEBUG
  print('🚀 SPLASH: isAuthenticated = ${authProvider.isAuthenticated}'); // DEBUG
  print('🚀 SPLASH: isAdmin = ${authProvider.isAdmin}'); // DEBUG
  print('🚀 SPLASH: userRole = ${authProvider.userRole}'); // DEBUG

  await Future.delayed(const Duration(milliseconds: 3000));

  if (!mounted) return;

  if (authProvider.isAuthenticated) {
    // 🔥 PERBAIKAN: Gunakan getter isAdmin dari provider
    if (authProvider.isAdmin) {
      print('🚀 SPLASH: Navigating to ADMIN dashboard'); // DEBUG
      Navigator.of(context).pushReplacementNamed('/admin-dashboard');
    } else {
      print('🚀 SPLASH: Navigating to USER dashboard'); // DEBUG
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  } else {
    print('🚀 SPLASH: Not authenticated, navigating to login'); // DEBUG
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _particlesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A202C),
              Color(0xFF2D3748),
              Color(0xFF1A202C),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            AnimatedBuilder(
              animation: _particlesAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlesPainter(_particlesAnimation.value),
                  child: Container(),
                );
              },
            ),

            // Animated gradient overlay with shimmer
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: [
                        (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                        _shimmerAnimation.value.clamp(0.0, 1.0),
                        (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Geometric shapes background
            Positioned.fill(
              child: CustomPaint(
                painter: GeometricShapesPainter(),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      
                      // Animated logo with pulse effect
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: _buildLogo(),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // App name with gradient text
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFE5E7EB),
                            Colors.white,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Warga Connect',
                          style: GoogleFonts.poppins(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle with elegant border
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sistem Informasi RT/RW',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 2),
                      
                      // Modern loading indicator with text
                      Column(
                        children: [
                          // Animated dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final delay = index * 0.2;
                                  final value = (_pulseController.value + delay) % 1.0;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.3 + (value * 0.5)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.2 + (value * 0.3)),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mempersiapkan aplikasi...',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
            
            // Version text at bottom
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Powered by Arek Arek comel',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      child: Lottie.asset('asset/logo splash screen.json'),
    );
  }
}

// Particles painter for background
class ParticlesPainter extends CustomPainter {
  final double animation;

  ParticlesPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Generate particles
    for (int i = 0; i < 50; i++) {
      final seed = i * 0.1;
      final x = (size.width * ((seed + animation) % 1.0));
      final y = (size.height * ((seed * 1.3 + animation * 0.5) % 1.0));
      final radius = 1.0 + (i % 3);
      final opacity = 0.1 + ((i % 5) * 0.02);

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

// Geometric shapes painter
class GeometricShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw elegant circles
    paint.color = Colors.white.withOpacity(0.03);
    
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      80,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      100,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      60,
      paint,
    );

    // Draw elegant lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = Colors.white.withOpacity(0.02);
    
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.25,
      size.width,
      size.height * 0.35,
    );
    canvas.drawPath(path1, paint);
    
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.65,
      size.width,
      size.height * 0.75,
    );
    canvas.drawPath(path2, paint);

    // Corner decorations
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white.withOpacity(0.02);
    
    final cornerPath = Path();
    cornerPath.moveTo(0, 80);
    cornerPath.quadraticBezierTo(40, 40, 80, 0);
    cornerPath.lineTo(0, 0);
    cornerPath.close();
    canvas.drawPath(cornerPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}