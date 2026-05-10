import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthPrompt extends StatelessWidget {
  const AuthPrompt({super.key, required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: () =>
              GoRouter.of(context).push(isLogin ? '/register' : '/login'),
          child: Text(
            isLogin ? 'Sign Up' : 'Sign In',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
