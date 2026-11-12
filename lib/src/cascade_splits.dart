import 'dart:math' as math;

/// One partitioned view-frustum depth range for Cascaded Shadow Maps (CSM).
final class ShadowCascadeSplit {
  final int cascadeIndex;
  final double nearPlane;
  final double farPlane;
  final double normalizedSplitDepth;

  const ShadowCascadeSplit({
    required this.cascadeIndex,
    required this.nearPlane,
    required this.farPlane,
    required this.normalizedSplitDepth,
  });

  double get depthSpan => farPlane - nearPlane;
}

/// Computes GPU Gems 3 Practical Split Scheme frustum slices blending logarithmic & uniform splits.
final class ShadowCascadeSplitter {
  const ShadowCascadeSplitter._();

  /// Computes [cascadeCount] contiguous splits across `[nearPlane, farPlane]` with blend factor [lambda] in `[0, 1]`.
  static List<ShadowCascadeSplit> computeSplits({
    required double nearPlane,
    required double farPlane,
    int cascadeCount = 4,
    double lambda = 0.65,
  }) {
    final n = cascadeCount.clamp(1, 8);
    final near = math.max(1e-3, nearPlane);
    final far = math.max(near + 1e-2, farPlane);
    final lam = lambda.clamp(0.0, 1.0).toDouble();
    final range = far - near;
    final ratio = far / near;

    final splits = <ShadowCascadeSplit>[];
    var prevPlane = near;
    for (var i = 1; i <= n; i++) {
      final p = i / n;
      final logSplit = near * math.pow(ratio, p);
      final uniformSplit = near + range * p;
      final splitDepth = lam * logSplit + (1.0 - lam) * uniformSplit;
      final norm = ((splitDepth - near) / range).clamp(0.0, 1.0).toDouble();
      splits.add(
        ShadowCascadeSplit(
          cascadeIndex: i - 1,
          nearPlane: prevPlane,
          farPlane: splitDepth,
          normalizedSplitDepth: norm,
        ),
      );
      prevPlane = splitDepth;
    }
    return splits;
  }
}
