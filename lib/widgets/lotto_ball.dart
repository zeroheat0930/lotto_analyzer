import 'package:flutter/material.dart';

class LottoBall extends StatelessWidget {
  final int number;
  final double size;

  const LottoBall({
    super.key,
    required this.number,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFDAA520), // Goldenrod
            Color(0xFFB8860B), // Dark Goldenrod
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(100),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: Colors.black,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}
