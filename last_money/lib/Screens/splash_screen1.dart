import 'package:flutter/material.dart';
import 'package:last_money/Screens/splash_screen2.dart';
import 'dart:async';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen2()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF56AB2F),
      body: Center(
        child: Icon(
          Icons.attach_money,
          size: 100,
          color: Colors.white,
        ),
      ),
    );
  }
}
