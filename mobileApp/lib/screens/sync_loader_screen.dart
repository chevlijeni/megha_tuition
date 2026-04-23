import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import 'main_scaffold.dart';
import 'login_screen.dart';

class SyncLoaderScreen extends StatefulWidget {
  const SyncLoaderScreen({super.key});

  @override
  State<SyncLoaderScreen> createState() => _SyncLoaderScreenState();
}

class _SyncLoaderScreenState extends State<SyncLoaderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Initializing environment...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _performSync();
  }

  Future<void> _performSync() async {
    setState(() {
      _statusMessage = 'Fetching your workspace data...';
      _hasError = false;
    });

    try {
      // Small delay for visual polish
      await Future.delayed(const Duration(milliseconds: 800));
      
      final result = await ApiService.getSyncData(forceRefresh: true);

      if (!mounted) return;

      if (result['success']) {
        setState(() => _statusMessage = 'Preparing dashboard...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScaffold(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Stack(
          children: [
            // Background Elements (Subtle Blurs)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Pulse
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SvgPicture.asset(
                      'assets/images/Logo.svg',
                      height: 100,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Loader Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_hasError) ...[
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _statusMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Sync Failed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage ?? 'Unknown error',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _performSync,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('RETRY'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ApiService.clearToken();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                },
                                child: const Text(
                                  'LOGOUT',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
