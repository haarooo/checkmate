import 'package:flutter/material.dart';

class AppContainer extends StatelessWidget {
  const AppContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 웹/데스크톱 시연용 390x844 모바일 프레임.
    // 실제 모바일 빌드에서도 화면 내부 child는 그대로 정상 동작한다.
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      body: Center(
        child: Container(
          width: 390,
          height: 844,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
