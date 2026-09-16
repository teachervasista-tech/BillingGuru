import 'package:flutter/material.dart';

class AppNavigationAssetIcon extends StatelessWidget {
  const AppNavigationAssetIcon({
    required this.assetPath,
    this.size = 24,
    this.color,
    super.key,
  });

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.image_not_supported_outlined,
          size: size,
          //color: color,
        );
      },
    );
  }
}
