import 'dart:async';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final List<String> imagePaths = [
    'assets/images/programs/kardiyo.jpg',
    'assets/images/programs/tumvucut.jpg',
    'assets/images/programs/yagyakma.jpg',
    'assets/images/programs/geceesneme.jpg',
    'assets/images/programs/gymileriust.jpg',
    'assets/images/programs/direnc.jpg',
    'assets/images/programs/gymalt2.jpg',
  ];

  int currentIndex = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
      currentIndex = (currentIndex + 1) % imagePaths.length;
      _pageController.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView ile kayarak geçiş
          PageView.builder(
            controller: _pageController,
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePaths[index],
                    fit: BoxFit.cover,
                  ),
                  // Hafif karartma efekti
                  Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ],
              );
            },
          ),
          // Altta Giriş Yap butonu
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Giriş Yap'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}