import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({
    Key? key,
    this.size = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          'C',
          style: TextStyle(
            fontSize: size / 2,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
