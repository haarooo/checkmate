import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../ui/checkmate_ui.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final nickname = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    nickname.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        name.text.trim().isEmpty ||
        nickname.text.trim().isEmpty) {
      setState(() => error = '모든 항목을 입력해 주세요.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ref.read(authServiceProvider).signup(
            email: email.text.trim(),
            password: password.text.trim(),
            name: name.text.trim(),
            nickname: nickname.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입이 완료됐어요. 로그인해 주세요.')));
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e is DioException ? ApiClient.messageFromError(e) : '회원가입에 실패했어요.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CMTopBar(title: '회원가입', subtitle: '체크메이트에서 친구들과 함께 완주해요.', onBack: () => context.go('/login')),
          const SizedBox(height: 24),
          CMGradientCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '새로운 미션을\n시작해 볼까요?',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.25),
                  ),
                ),
                Icon(Icons.check_circle_outline_rounded, color: Colors.white.withValues(alpha: 0.9), size: 58),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Input(controller: email, label: '이메일', hint: 'example@email.com', icon: Icons.mail_outline_rounded),
          _Input(controller: password, label: '비밀번호', hint: '비밀번호 입력', icon: Icons.lock_outline_rounded, obscure: true),
          _Input(controller: name, label: '이름', hint: '이름 입력', icon: Icons.person_outline_rounded),
          _Input(controller: nickname, label: '닉네임', hint: '닉네임 입력', icon: Icons.badge_outlined),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: CMColors.red, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          CMPrimaryButton(label: '회원가입', onPressed: submit, loading: loading),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: const Text('이미 계정이 있으신가요? 로그인', style: TextStyle(color: CMColors.blue, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: CMColors.text)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: CMColors.muted, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: CMColors.sub),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: CMColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: CMColors.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: CMColors.blue, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
