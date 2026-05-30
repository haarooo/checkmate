import 'package:flutter/material.dart';

import '../ui/checkmate_ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: CMColors.blue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 72),
            SizedBox(height: 18),
            Text(
              'Checkmate',
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
