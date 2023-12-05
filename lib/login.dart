import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginButton extends StatelessWidget{
  const LoginButton({
    super.key,
    required this.loggedIn,
    required this.signOut,
  });

  final bool loggedIn;
  final void Function() signOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextButton(
            
            onPressed: () => {
              !loggedIn ? context.push('/log-in') : signOut()
            },
            child: !loggedIn ? const Text("Login") : const Text("Logout")
          ),
        ),
      ],
    );
  }

}