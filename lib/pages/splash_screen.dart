import 'package:flutter/material.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/icon/logo-matchafin-v2.png'),
      context,
    );
  }

  @override
  void initState() {
    super.initState();

    // Controller utama dengan durasi 2 detik
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 1. Animasi Fade Logo (Jalan dari awal 0.0 sampai 60% durasi)
    _logoFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    // 2. Animasi Slide Logo & Teks dari Bawah ke Atas
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Animasi Fade Teks (Baru muncul saat durasi mencapai 40% sampai 100%)
    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      _navigateToMain();
      }
    });

    // Jalankan animasi
    _controller.forward();
  }

  void _navigateToMain() async {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sesuaikan latar belakang
      body: Center(
        child: SlideTransition(
          position: _logoSlideAnimation, // Menarik seluruh Column dari bawah ke atas
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- 1. LOGO ---
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: Image.asset(
                  '../../assets/icon/logo-matchafin-v2.png', // Sesuaikan path logo
                  width: 180,
                  height: 180,
                ),
              ),

              // const SizedBox(height: 20), // Jarak antara logo dan teks

              // --- 2. TEKS DI BAWAH LOGO ---
              FadeTransition(
                opacity: _textFadeAnimation,
                child: const Column(
                  children:  [
                    Text(
                      'MatchaFin', // Ganti dengan nama aplikasimu
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D32), // Sesuaikan warna teks
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Track your money, track your investment',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}