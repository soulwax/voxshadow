import 'dart:math' as math;

import 'math.dart';

/// Fitted & texel-snapped directional light orthographic bounds for one shadow cascade.
final class FittedCascadeOrtho {
  final ShadowVec3 sphereCenterWorld;
  final double sphereRadius;
  final double texelWorldSize;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double nearZ;
  final double farZ;
  final ShadowVec3 lightRight;
  final ShadowVec3 lightUp;
  final ShadowVec3 lightForward;

  const FittedCascadeOrtho({
    required this.sphereCenterWorld,
    required this.sphereRadius,
    required this.texelWorldSize,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.nearZ,
    required this.farZ,
    required this.lightRight,
    required this.lightUp,
    required this.lightForward,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;
}

/// Fits a conservative bounding sphere around a camera frustum slice and snaps ortho bounds to shadow texels.
final class LightOrthoFitter {
  const LightOrthoFitter._();

  /// Computes the 8 world-space frustum corners for `[splitNear, splitFar]` and fits a texel-snapped ortho box.
  static FittedCascadeOrtho fitCascade({
    required ShadowVec3 cameraPosition,
    required ShadowVec3 cameraForward,
    required ShadowVec3 cameraUp,
    required double fovYRadians,
    required double aspectRatio,
    required double splitNear,
    required double splitFar,
    required ShadowVec3 lightForward,
    int shadowMapResolution = 1024,
    bool snapToTexels = true,
    double zBackPadding = 25.0,
    ShadowVec3 worldUp = ShadowVec3.unitY,
  }) {
    final camFwd = cameraForward.normalized();
    var camRight = camFwd.cross(cameraUp).normalized();
    if (camRight.lengthSquared <= 1e-6) {
      camRight = const ShadowVec3(1.0, 0.0, 0.0);
    }
    final camUp = camRight.cross(camFwd).normalized();

    final safeAspect = math.max(1e-3, aspectRatio);
    final tanHalfFov = math.tan(fovYRadians.clamp(0.05, math.pi - 0.05) * 0.5);

    final nearHalfH = tanHalfFov * splitNear;
    final nearHalfW = nearHalfH * safeAspect;
    final farHalfH = tanHalfFov * splitFar;
    final farHalfW = farHalfH * safeAspect;

    final nearCenter = cameraPosition + camFwd * splitNear;
    final farCenter = cameraPosition + camFwd * splitFar;

    final corners = <ShadowVec3>[
      nearCenter + camUp * nearHalfH - camRight * nearHalfW,
      nearCenter + camUp * nearHalfH + camRight * nearHalfW,
      nearCenter - camUp * nearHalfH - camRight * nearHalfW,
      nearCenter - camUp * nearHalfH + camRight * nearHalfW,
      farCenter + camUp * farHalfH - camRight * farHalfW,
      farCenter + camUp * farHalfH + camRight * farHalfW,
      farCenter - camUp * farHalfH - camRight * farHalfW,
      farCenter - camUp * farHalfH + camRight * farHalfW,
    ];

    var center = ShadowVec3.zero;
    for (final c in corners) {
      center = center + c;
    }
    center = center * (1.0 / 8.0);

    var maxDistSq = 0.0;
    for (final c in corners) {
      final dSq = (c - center).lengthSquared;
      if (dSq > maxDistSq) maxDistSq = dSq;
    }
    // Round radius slightly upward for rotation invariance across camera panning.
    final rawRadius = math.sqrt(maxDistSq);
    final radius = (rawRadius * 16.0).ceil() / 16.0;

    final lFwd = lightForward.lengthSquared <= 1e-8
        ? const ShadowVec3(0.0, -1.0, 0.0)
        : lightForward.normalized();
    var refUp = worldUp.normalized();
    if (lFwd.dot(refUp).abs() > 0.99) {
      refUp = const ShadowVec3(0.0, 0.0, 1.0);
    }
    final lRight = lFwd.cross(refUp).normalized();
    final lUp = lRight.cross(lFwd).normalized();

    final res = math.max(16, shadowMapResolution);
    final diameter = radius * 2.0;
    final texelSize = diameter / res;

    var centerX = center.dot(lRight);
    var centerY = center.dot(lUp);
    final centerZ = center.dot(lFwd);

    if (snapToTexels && texelSize > 1e-9) {
      centerX = (centerX / texelSize).roundToDouble() * texelSize;
      centerY = (centerY / texelSize).roundToDouble() * texelSize;
    }

    return FittedCascadeOrtho(
      sphereCenterWorld: center,
      sphereRadius: radius,
      texelWorldSize: texelSize,
      minX: centerX - radius,
      maxX: centerX + radius,
      minY: centerY - radius,
      maxY: centerY + radius,
      nearZ: centerZ - radius - math.max(0.0, zBackPadding),
      farZ: centerZ + radius,
      lightRight: lRight,
      lightUp: lUp,
      lightForward: lFwd,
    );
  }
}
