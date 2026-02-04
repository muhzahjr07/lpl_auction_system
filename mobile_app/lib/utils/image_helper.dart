import 'package:flutter/material.dart';

class ImageHelper {
  static ImageProvider getTeamLogoProvider(String? path) {
    if (path == null || path.isEmpty) {
      // Return a default placeholder or transparent image
      return const AssetImage('assets/logo_app.jpg');
    }

    if (path.startsWith('http')) {
      return NetworkImage(path);
    }

    // Assume it's a local asset path
    return AssetImage(path);
  }
}
