import 'package:flutter/material.dart';

/// The Groupe SABA brand logo, loaded from assets.
///
/// Use [BrandLogo.mark] for compact placements (navigation rail, app bars)
/// and [BrandLogo.full] for prominent placements (login screen).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 40, this.semanticLabel});

  /// Compact size, suitable for the navigation rail header.
  const BrandLogo.mark({super.key})
    : height = 34,
      semanticLabel = 'Logo Groupe SABA';

  /// Large size, suitable for the login screen.
  const BrandLogo.full({super.key, this.height = 96})
    : semanticLabel = 'Logo Groupe SABA';

  final double height;
  final String? semanticLabel;

  static const _assetPath = 'assets/cropped-logo-saba-1-1-1.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );
  }
}
