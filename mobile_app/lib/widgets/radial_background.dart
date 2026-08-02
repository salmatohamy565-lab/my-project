import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RadialBackground extends StatelessWidget {
  final Widget child;

  const RadialBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: AppColors.bgGradient,
          stops: [0.0, 0.38, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle top-right light grey glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33CED4DA),
              ),
              child: ClipOval(
                child: ImageFiltered(
                  imageFilter: const ColorFilter.mode(
                    Color(0x33CED4DA),
                    BlendMode.srcOver,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x33CED4DA),
                          blurRadius: 100,
                          spreadRadius: 50,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Subtle bottom-left light grey glow
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x22DEE2E6),
              ),
              child: ClipOval(
                child: ImageFiltered(
                  imageFilter: const ColorFilter.mode(
                    Color(0x22DEE2E6),
                    BlendMode.srcOver,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x22DEE2E6),
                          blurRadius: 100,
                          spreadRadius: 50,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

