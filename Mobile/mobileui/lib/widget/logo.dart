import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
