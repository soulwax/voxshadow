import 'dart:math' as math;

/// Lightweight platform-neutral 3D vector for cascaded shadow math.
final class ShadowVec3 {
  final double x;
  final double y;
  final double z;

  const ShadowVec3(this.x, this.y, this.z);

  static const ShadowVec3 zero = ShadowVec3(0.0, 0.0, 0.0);
  static const ShadowVec3 unitY = ShadowVec3(0.0, 1.0, 0.0);

  ShadowVec3 operator +(ShadowVec3 other) =>
      ShadowVec3(x + other.x, y + other.y, z + other.z);

  ShadowVec3 operator -(ShadowVec3 other) =>
      ShadowVec3(x - other.x, y - other.y, z - other.z);

  ShadowVec3 operator *(double s) => ShadowVec3(x * s, y * s, z * s);

  ShadowVec3 operator -() => ShadowVec3(-x, -y, -z);

  double dot(ShadowVec3 other) => x * other.x + y * other.y + z * other.z;

  ShadowVec3 cross(ShadowVec3 other) => ShadowVec3(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
      );

  double get lengthSquared => x * x + y * y + z * z;
  double get length => math.sqrt(lengthSquared);

  ShadowVec3 normalized() {
    final len = length;
    if (len <= 1e-9) return zero;
    final inv = 1.0 / len;
    return ShadowVec3(x * inv, y * inv, z * inv);
  }
}
