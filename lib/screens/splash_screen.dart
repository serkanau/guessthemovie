import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/route_transitions.dart';
import 'user_entry_screen.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String? _error;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade-in için
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Progress bar için hafif yukarıdan aşağıya kayma
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _boot();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      // İnternet kontrolü
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.none) {
        setState(() => _error = 'İnternet bağlantısı bulunamadı.');
        return;
      }

      // Splash ekranını daha uzun göster
      await Future.delayed(const Duration(seconds: 2));

      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user != null) {
        Navigator.of(context).pushReplacement(fadeRoute(const MainMenuScreen()));
      } else {
        Navigator.of(context).pushReplacement(fadeRoute(const UserEntryScreen()));
      }
    } catch (e) {
      debugPrint("SplashScreen hata: $e");
      setState(() => _error = 'Beklenmedik bir hata oluştu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E0266), Color(0xFF15162C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_movies_outlined, size: 96, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Guess The Movie',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (_error == null)
                  SlideTransition(
                    position: _slideAnimation,
                    child: const CircularProgressIndicator(color: Colors.white),
                  )
                else
                  _ErrorBox(message: _error!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            fadeRoute(const SplashScreen()),
          ),
          child: const Text('Tekrar dene'),
        ),
      ],
    );
  }
}
