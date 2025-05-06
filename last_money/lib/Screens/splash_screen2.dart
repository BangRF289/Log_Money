import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF56AB2F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash.png',
              width: 250,
              height: 250,
            ),
            SizedBox(height: 20),
            Text(
              "Money Log",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF56AB2F),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Mencatat Keuangan Anda\nDengan Mudah & Cepat",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 255, 255, 255)),
            ),
          ],
        ),
      ),
    );
  }
}
